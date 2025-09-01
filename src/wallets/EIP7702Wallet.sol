// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/core/BaseAccount.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "@account-abstraction/interfaces/IPaymaster.sol";
import "../interfaces/IEIP7702Wallet.sol";

/**
 * @title EIP7702Wallet
 * @dev A smart wallet implementation supporting EIP-7702 account delegation and ERC-4337
 */
contract EIP7702Wallet is IEIP7702Wallet, BaseAccount, Initializable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Storage slots
    address private _owner;
    IEntryPoint private immutable _entryPoint;

    // Nonce for replay protection
    uint256 private _nonce;

    // USDC configuration
    address private _usdcToken;
    address private _gasSponsor; // Address that receives gas fees
    uint256 private _usdcExchangeRate; // USDC per ETH (scaled by 1e18)

    // Constants
    uint256 public constant SIGNATURE_LENGTH = 65;
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    modifier onlyOwner() {
        require(msg.sender == _owner, "EIP7702Wallet: caller is not the owner");
        _;
    }

    modifier onlyOwnerOrEntryPoint() {
        require(
            msg.sender == _owner || msg.sender == address(_entryPoint),
            "EIP7702Wallet: caller is not the owner or EntryPoint"
        );
        _;
    }

    constructor(IEntryPoint entryPointAddress) {
        _entryPoint = entryPointAddress;
        // Don't disable initializers for cloneable contracts
        // _disableInitializers();
    }

    /**
     * @dev Initialize the wallet with an owner
     * @param walletOwner The owner of the wallet
     */
    function initialize(address walletOwner) external initializer {
        require(walletOwner != address(0), "EIP7702Wallet: owner cannot be zero address");
        _owner = walletOwner;

        // Initialize USDC configuration
        _usdcToken = address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8); // Sepolia USDC
        _gasSponsor = walletOwner; // Initially, gas fees go to owner
        _usdcExchangeRate = 2000 * 1e18; // 2000 USDC per ETH

        emit WalletInitialized(walletOwner, address(_entryPoint));
    }

    /**
     * @dev Initialize the wallet with custom USDC configuration
     * @param walletOwner The owner of the wallet
     * @param usdcToken The USDC token address
     * @param gasSponsor The address that receives gas fees
     * @param exchangeRate The USDC/ETH exchange rate (scaled by 1e18)
     */
    function initializeWithConfig(
        address walletOwner,
        address usdcToken,
        address gasSponsor,
        uint256 exchangeRate
    ) external initializer {
        require(walletOwner != address(0), "EIP7702Wallet: owner cannot be zero address");
        require(usdcToken != address(0), "EIP7702Wallet: USDC token cannot be zero address");
        require(gasSponsor != address(0), "EIP7702Wallet: gas sponsor cannot be zero address");
        require(exchangeRate > 0, "EIP7702Wallet: exchange rate must be positive");

        _owner = walletOwner;
        _usdcToken = usdcToken;
        _gasSponsor = gasSponsor;
        _usdcExchangeRate = exchangeRate;

        emit WalletInitialized(walletOwner, address(_entryPoint));
    }

    /**
     * @dev Execute a transaction from the wallet with USDC gas payment
     */
    function execute(address target, uint256 value, bytes calldata data)
        external
        override(BaseAccount, IEIP7702Wallet)
        onlyOwnerOrEntryPoint
        nonReentrant
    {
        require(target != address(0), "EIP7702Wallet: target cannot be zero address");

        (bool success, bytes memory returnData) = target.call{value: value}(data);

        emit TransactionExecuted(target, value, data, success);

        if (!success) {
            // If the transaction failed, revert with the returned data
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    /**
     * @dev Execute USDC transfer with gas fees paid in USDC
     * @param recipient The recipient address
     * @param amount The USDC amount to transfer
     * @param gasFeeAmount The gas fee amount in USDC to deduct
     */
    function executeUSDCTransfer(
        address recipient,
        uint256 amount,
        uint256 gasFeeAmount
    ) external onlyOwner nonReentrant {
        require(recipient != address(0), "EIP7702Wallet: recipient cannot be zero address");
        require(amount > 0, "EIP7702Wallet: amount must be positive");

        // Get USDC contract (assuming it's set during initialization)
        address usdcAddress = _getUSDCAddress();
        require(usdcAddress != address(0), "EIP7702Wallet: USDC address not set");

        IERC20 usdc = IERC20(usdcAddress);

        // Check total balance required (transfer amount + gas fee)
        uint256 totalRequired = amount + gasFeeAmount;
        uint256 walletBalance = usdc.balanceOf(address(this));
        require(walletBalance >= totalRequired, "EIP7702Wallet: insufficient USDC balance");

        // Execute the USDC transfer to recipient
        bytes memory transferData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            recipient,
            amount
        );

        (bool success, ) = usdcAddress.call(transferData);
        require(success, "EIP7702Wallet: USDC transfer failed");

        // If gas fee is specified, transfer it to the gas sponsor/paymaster
        if (gasFeeAmount > 0) {
            address gasSponsor = _getGasSponsor();
            if (gasSponsor != address(0)) {
                bytes memory feeTransferData = abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    gasSponsor,
                    gasFeeAmount
                );

                (bool feeSuccess, ) = usdcAddress.call(feeTransferData);
                require(feeSuccess, "EIP7702Wallet: gas fee transfer failed");
            }
        }

        emit TransactionExecuted(usdcAddress, 0, transferData, true);
        emit USDCTransferExecuted(recipient, amount, gasFeeAmount);
    }

    /**
     * @dev Get USDC contract address
     */
    function _getUSDCAddress() internal view returns (address) {
        return _usdcToken;
    }

    /**
     * @dev Get gas sponsor address
     */
    function _getGasSponsor() internal view returns (address) {
        return _gasSponsor;
    }

    /**
     * @dev Calculate gas fee in USDC based on gas used
     * @param gasUsed The amount of gas used
     * @param gasPrice The gas price in wei
     * @return The gas fee amount in USDC (6 decimals)
     */
    function _calculateGasFeeInUSDC(uint256 gasUsed, uint256 gasPrice) internal view returns (uint256) {
        // Calculate gas cost in ETH (wei)
        uint256 gasCostInWei = gasUsed * gasPrice;

        // Convert to USDC using exchange rate
        // exchangeRate is USDC per ETH (scaled by 1e18)
        // gasCostInWei is in wei (1e18 wei = 1 ETH)
        uint256 usdcGasCost = (gasCostInWei * _usdcExchangeRate) / 1e18;

        // Convert from 18 decimals to 6 decimals (USDC)
        return usdcGasCost / 1e12;
    }

    /**
     * @dev Estimate gas fee for USDC transfer
     * @return Estimated gas fee in USDC (6 decimals)
     */
    function estimateGasFee() external view returns (uint256) {
        // Estimate gas usage for USDC transfer (simplified)
        uint256 estimatedGas = 65000; // Base gas for ERC-20 transfer
        uint256 gasPrice = 20000000000; // 20 gwei (conservative estimate)

        return _calculateGasFeeInUSDC(estimatedGas, gasPrice);
    }

    /**
     * @dev Get USDC configuration
     */
    function getUSDCConfig() external view returns (
        address usdcToken,
        address gasSponsor,
        uint256 exchangeRate
    ) {
        return (_usdcToken, _gasSponsor, _usdcExchangeRate);
    }

    /**
     * @dev Update USDC exchange rate (only owner)
     */
    function updateExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "EIP7702Wallet: exchange rate must be positive");
        _usdcExchangeRate = newRate;
        emit ExchangeRateUpdated(newRate);
    }

    /**
     * @dev Update gas sponsor address (only owner)
     */
    function updateGasSponsor(address newSponsor) external onlyOwner {
        require(newSponsor != address(0), "EIP7702Wallet: gas sponsor cannot be zero address");
        _gasSponsor = newSponsor;
        emit GasSponsorUpdated(newSponsor);
    }

    /**
     * @dev Execute multiple transactions in a batch
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyOwnerOrEntryPoint nonReentrant returns (bool[] memory successes, bytes[] memory returnDatas) {
        require(targets.length == values.length, "EIP7702Wallet: targets and values length mismatch");
        require(targets.length == datas.length, "EIP7702Wallet: targets and datas length mismatch");
        require(targets.length > 0, "EIP7702Wallet: empty batch");

        successes = new bool[](targets.length);
        returnDatas = new bytes[](targets.length);

        for (uint256 i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "EIP7702Wallet: target cannot be zero address");

            (successes[i], returnDatas[i]) = targets[i].call{value: values[i]}(datas[i]);

            emit TransactionExecuted(targets[i], values[i], datas[i], successes[i]);
        }
    }

    /**
     * @dev Validate the user operation signature
     */
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);
        
        if (signer == _owner) {
            return 0; // Valid signature
        }
        
        return SIG_VALIDATION_FAILED; // Invalid signature
    }

    /**
     * @dev Return the entry point contract address
     */
    function entryPoint() public view override(BaseAccount, IEIP7702Wallet) returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev Get the current owner of the wallet
     */
    function owner() external view override returns (address) {
        return _owner;
    }

    /**
     * @dev Transfer ownership of the wallet
     */
    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "EIP7702Wallet: new owner cannot be zero address");
        require(newOwner != _owner, "EIP7702Wallet: new owner is the same as current owner");
        
        address oldOwner = _owner;
        _owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Check if the wallet supports EIP-7702 delegation
     */
    function supportsDelegation() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Get the current nonce for the wallet
     */
    function getNonce() public view override returns (uint256) {
        return _nonce;
    }

    /**
     * @dev Increment the nonce (called by EntryPoint)
     */
    function _incrementNonce() internal {
        _nonce++;
    }

    /**
     * @dev Handle post-operation logic
     */
    function _postOp(
        IPaymaster.PostOpMode /* mode */,
        bytes calldata /* context */,
        uint256 /* actualGasCost */,
        uint256 /* actualUserOpFeePerGas */
    ) internal {
        _incrementNonce();
        // Additional post-operation logic can be added here
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {
        // Allow the wallet to receive ETH
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        // Allow the wallet to receive ETH and handle unknown function calls
    }

    /**
     * @dev Get the wallet's balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Emergency function to recover stuck tokens
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            // Withdraw ETH
            payable(_owner).transfer(amount);
        } else {
            // Withdraw ERC-20 token
            (bool success, ) = token.call(
                abi.encodeWithSignature("transfer(address,uint256)", _owner, amount)
            );
            require(success, "EIP7702Wallet: token transfer failed");
        }
    }
}
