// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@account-abstraction/core/BasePaymaster.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "@account-abstraction/interfaces/PackedUserOperation.sol";
import "../interfaces/IUSDCPaymaster.sol";

/**
 * @title USDCPaymaster
 * @dev A paymaster that accepts USDC tokens for gas payment in ERC-4337 transactions
 */
contract USDCPaymaster is BasePaymaster, IUSDCPaymaster {
    using SafeERC20 for IERC20;

    // USDC token contract
    IERC20 public immutable _usdcToken;
    
    // Exchange rate: USDC per ETH (scaled by 1e18)
    uint256 public exchangeRate;
    
    // Fee markup percentage (in basis points, 100 = 1%)
    uint256 public feeMarkup = 1000; // 10% markup by default
    
    // Minimum USDC balance required for gas payment
    uint256 public minimumUSDCBalance = 10 * 1e6; // 10 USDC (6 decimals)

    // Constants
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant USDC_DECIMALS = 6;
    uint256 public constant ETH_DECIMALS = 18;

    // Events
    event FeeMarkupUpdated(uint256 oldMarkup, uint256 newMarkup);
    event MinimumBalanceUpdated(uint256 oldBalance, uint256 newBalance);

    constructor(
        IEntryPoint entryPoint,
        address usdcTokenAddress,
        uint256 initialExchangeRate,
        address initialOwner
    ) BasePaymaster(entryPoint) {
        require(usdcTokenAddress != address(0), "USDCPaymaster: USDC token cannot be zero address");
        require(initialExchangeRate > 0, "USDCPaymaster: exchange rate must be positive");
        
        _usdcToken = IERC20(usdcTokenAddress);
        exchangeRate = initialExchangeRate;
        
        // Transfer ownership to the initial owner
        _transferOwnership(initialOwner);
        
        emit ExchangeRateUpdated(0, initialExchangeRate);
    }

    /**
     * @dev Validate the paymaster user operation
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal view override returns (bytes memory context, uint256 validationData) {
        // Extract sender address
        address sender = userOp.sender;
        
        // Calculate required USDC amount
        uint256 usdcAmount = calculateUSDCAmount(maxCost);
        
        // Check if sender has enough USDC balance
        uint256 senderBalance = _usdcToken.balanceOf(sender);
        require(senderBalance >= usdcAmount, "USDCPaymaster: insufficient USDC balance");
        require(senderBalance >= minimumUSDCBalance, "USDCPaymaster: balance below minimum");
        
        // Check USDC allowance for this paymaster
        uint256 allowance = _usdcToken.allowance(sender, address(this));
        require(allowance >= usdcAmount, "USDCPaymaster: insufficient USDC allowance");
        
        // Return context with sender and USDC amount
        context = abi.encode(sender, usdcAmount, maxCost);
        validationData = 0; // Valid
    }

    /**
     * @dev Handle post-operation logic (charge USDC)
     */
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) internal override {
        if (mode == PostOpMode.postOpReverted) {
            return; // Don't charge if operation reverted
        }

        (address sender, uint256 maxUsdcAmount, uint256 maxCost) = abi.decode(context, (address, uint256, uint256));
        
        // Calculate actual USDC amount based on actual gas cost
        uint256 actualUsdcAmount = calculateUSDCAmount(actualGasCost);
        
        // Use the minimum of maxUsdcAmount and actualUsdcAmount
        uint256 chargeAmount = actualUsdcAmount > maxUsdcAmount ? maxUsdcAmount : actualUsdcAmount;
        
        // Transfer USDC from sender to paymaster
        _usdcToken.safeTransferFrom(sender, address(this), chargeAmount);
        
        emit USDCGasPayment(sender, chargeAmount, actualUserOpFeePerGas, actualGasCost / actualUserOpFeePerGas);
    }

    /**
     * @dev Calculate the USDC amount needed for a given gas cost
     */
    function calculateUSDCAmount(uint256 gasCost) public view override returns (uint256) {
        // gasCost is in wei (18 decimals)
        // exchangeRate is USDC per ETH (scaled by 1e18)
        // USDC has 6 decimals
        
        uint256 usdcAmount = (gasCost * exchangeRate) / (10 ** ETH_DECIMALS);
        
        // Apply fee markup
        usdcAmount = (usdcAmount * (BASIS_POINTS + feeMarkup)) / BASIS_POINTS;
        
        return usdcAmount;
    }

    /**
     * @dev Set the USDC/ETH exchange rate (only owner)
     */
    function setExchangeRate(uint256 newRate) external override onlyOwner {
        require(newRate > 0, "USDCPaymaster: exchange rate must be positive");
        
        uint256 oldRate = exchangeRate;
        exchangeRate = newRate;
        
        emit ExchangeRateUpdated(oldRate, newRate);
    }

    /**
     * @dev Set the fee markup percentage (only owner)
     */
    function setFeeMarkup(uint256 newMarkup) external onlyOwner {
        require(newMarkup <= 5000, "USDCPaymaster: markup cannot exceed 50%"); // Max 50%
        
        uint256 oldMarkup = feeMarkup;
        feeMarkup = newMarkup;
        
        emit FeeMarkupUpdated(oldMarkup, newMarkup);
    }

    /**
     * @dev Set the minimum USDC balance required (only owner)
     */
    function setMinimumUSDCBalance(uint256 newBalance) external onlyOwner {
        uint256 oldBalance = minimumUSDCBalance;
        minimumUSDCBalance = newBalance;
        
        emit MinimumBalanceUpdated(oldBalance, newBalance);
    }

    /**
     * @dev Withdraw USDC from the paymaster (only owner)
     */
    function withdrawUSDC(uint256 amount) external override onlyOwner {
        require(amount > 0, "USDCPaymaster: amount must be positive");
        
        uint256 balance = _usdcToken.balanceOf(address(this));
        require(balance >= amount, "USDCPaymaster: insufficient USDC balance");
        
        _usdcToken.safeTransfer(owner(), amount);
        
        emit USDCWithdrawn(owner(), amount);
    }

    /**
     * @dev Get the USDC token contract address
     */
    function usdcToken() external view override returns (address) {
        return address(_usdcToken);
    }

    /**
     * @dev Get current fee markup
     */
    function getFeeMarkup() external view returns (uint256) {
        return feeMarkup;
    }

    /**
     * @dev Get minimum USDC balance required
     */
    function getMinimumUSDCBalance() external view returns (uint256) {
        return minimumUSDCBalance;
    }

    /**
     * @dev Get USDC balance of this paymaster
     */
    function getUSDCBalance() external view returns (uint256) {
        return _usdcToken.balanceOf(address(this));
    }

    /**
     * @dev Emergency function to recover stuck ETH
     */
    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "USDCPaymaster: no ETH to withdraw");
        
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Emergency function to recover stuck tokens (except USDC)
     */
    function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(_usdcToken), "USDCPaymaster: use withdrawUSDC for USDC");
        require(token != address(0), "USDCPaymaster: token cannot be zero address");
        
        IERC20(token).safeTransfer(owner(), amount);
    }
}
