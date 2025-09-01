// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/wallets/EIP7702Wallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EIP7702GaslessTransfer
 * @dev Script to execute gasless USDC transfers using EIP-7702 delegation
 * This demonstrates USDC-only wallet sending USDC to another EOA with gas fees paid in USDC
 */
contract EIP7702GaslessTransfer is Script {
    // EIP-7702 Type 4 transaction structure
    struct EIP7702Transaction {
        uint256 nonce;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        address delegation; // EIP-7702 delegation contract
        bytes signature;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Configuration
        address walletAddress = vm.envOr("WALLET_ADDRESS", address(0));
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        address gasSponsor = vm.envOr("GAS_SPONSOR", deployer); // Gas sponsor (defaults to deployer if not set)
        uint256 transferAmount = vm.envOr("TRANSFER_AMOUNT", uint256(100 * 1e6)); // 100 USDC
        uint256 gasFeeAmount = vm.envOr("GAS_FEE_AMOUNT", uint256(1 * 1e6)); // 1 USDC for gas
        address usdcAddress = vm.envOr("USDC_ADDRESS", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));

        require(walletAddress != address(0), "WALLET_ADDRESS not set");
        require(recipient != address(0), "RECIPIENT_ADDRESS not set");

        console.log("=== EIP-7702 Gasless USDC Transfer ===");
        console.log("Wallet:", walletAddress);
        console.log("Recipient:", recipient);
        console.log("Gas Sponsor:", gasSponsor);
        console.log("Transfer Amount:", transferAmount / 1e6, "USDC");
        console.log("Gas Fee Amount:", gasFeeAmount / 1e6, "USDC");
        console.log("USDC Token:", usdcAddress);

        // Check initial balances
        IERC20 usdc = IERC20(usdcAddress);
        uint256 initialWalletBalance = usdc.balanceOf(walletAddress);
        uint256 initialRecipientBalance = usdc.balanceOf(recipient);
        uint256 initialGasSponsorBalance = usdc.balanceOf(gasSponsor);

        console.log("Initial wallet USDC balance:", initialWalletBalance / 1e6, "USDC");
        console.log("Initial recipient USDC balance:", initialRecipientBalance / 1e6, "USDC");
        console.log("Initial gas sponsor USDC balance:", initialGasSponsorBalance / 1e6, "USDC");

        // Verify sufficient balance
        require(
            initialWalletBalance >= transferAmount + gasFeeAmount,
            "Insufficient USDC balance for transfer + gas"
        );

        vm.startBroadcast(deployerPrivateKey);

        // For EIP-7702, we need to create a delegation transaction
        // This would typically be sent from the wallet owner using EIP-7702 Type 4 transaction
        EIP7702Wallet wallet = EIP7702Wallet(payable(walletAddress));

        console.log("Executing USDC transfer with gas payment...");

        // Execute the USDC transfer with gas fee deduction
        // In a real EIP-7702 scenario, this would be called via delegation
        wallet.executeUSDCTransfer(recipient, transferAmount, gasFeeAmount);

        vm.stopBroadcast();

        // Verify the transfer
        uint256 finalWalletBalance = usdc.balanceOf(walletAddress);
        uint256 finalRecipientBalance = usdc.balanceOf(recipient);
        uint256 finalGasSponsorBalance = usdc.balanceOf(gasSponsor);

        console.log("Final wallet USDC balance:", finalWalletBalance / 1e6, "USDC");
        console.log("Final recipient USDC balance:", finalRecipientBalance / 1e6, "USDC");
        console.log("Final gas sponsor USDC balance:", finalGasSponsorBalance / 1e6, "USDC");

        // Calculate expected balances
        uint256 expectedWalletDeduction = transferAmount + gasFeeAmount;
        uint256 expectedRecipientIncrease = transferAmount; // Only transfer amount goes to recipient
        uint256 expectedGasSponsorIncrease = gasFeeAmount; // Gas fee goes to gas sponsor

        console.log("Expected wallet deduction:", expectedWalletDeduction / 1e6, "USDC");
        console.log("Expected recipient increase:", expectedRecipientIncrease / 1e6, "USDC");
        console.log("Expected gas sponsor increase:", expectedGasSponsorIncrease / 1e6, "USDC");

        // Verify balances
        require(
            finalRecipientBalance == initialRecipientBalance + expectedRecipientIncrease,
            "Recipient balance not increased correctly"
        );

        require(
            finalGasSponsorBalance == initialGasSponsorBalance + expectedGasSponsorIncrease,
            "Gas sponsor balance not increased correctly"
        );

        require(
            finalWalletBalance == initialWalletBalance - expectedWalletDeduction,
            "Wallet balance not deducted correctly"
        );

        console.log("EIP-7702 Gasless USDC Transfer Successful!");
        console.log("Transferred:", transferAmount / 1e6, "USDC to recipient");
        console.log("Gas Fee Paid:", gasFeeAmount / 1e6, "USDC to gas sponsor");
        console.log("Total Deducted:", (transferAmount + gasFeeAmount) / 1e6, "USDC");
        console.log("Recipient received:", transferAmount / 1e6, "USDC");
        console.log("Gas sponsor received:", gasFeeAmount / 1e6, "USDC");
    }

    /**
     * @dev Helper function to create EIP-7702 transaction data
     * This would be used when sending actual EIP-7702 Type 4 transactions
     */
    function createEIP7702TransactionData(
        address /* wallet */,
        address recipient,
        uint256 amount,
        uint256 gasFeeAmount
    ) internal pure returns (bytes memory) {
        // This would encode the function call for EIP-7702 delegation
        return abi.encodeWithSignature(
            "executeUSDCTransfer(address,uint256,uint256)",
            recipient,
            amount,
            gasFeeAmount
        );
    }

    /**
     * @dev Estimate gas cost in USDC based on current gas price and exchange rate
     */
    function estimateGasCostInUSDC(
        uint256 gasLimit,
        address usdcAddress
    ) internal view returns (uint256) {
        // Get current gas price
        uint256 gasPrice = tx.gasprice;
        uint256 estimatedGasCost = gasLimit * gasPrice;

        // Convert ETH gas cost to USDC (assuming 1 ETH = 2000 USDC for estimation)
        uint256 exchangeRate = 2000 * 1e18; // 2000 USDC per ETH in wei
        uint256 usdcGasCost = (estimatedGasCost * exchangeRate) / 1e18;

        // Convert to USDC decimals (6 decimals)
        return usdcGasCost / 1e12; // ETH has 18 decimals, USDC has 6, so divide by 1e12
    }
}
