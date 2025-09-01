// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/wallets/EIP7702Wallet.sol";
import "../src/utils/MockUSDC.sol";

/**
 * @title TransferUSDC
 * @dev Script to transfer USDC from your smart wallet (gas fees paid in USDC)
 */
contract TransferUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get addresses
        address walletAddress = vm.envOr(
            "WALLET_ADDRESS",
            address(0x2a3a9a665c7fb61EFA44Ef47C3d40914a74E2AC4)
        );
        address usdcAddress = vm.envOr(
            "USDC_TOKEN",
            address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8)
        );
        address recipient = vm.envAddress("RECIPIENT_ADDRESS"); // Must be provided
        uint256 transferAmount = vm.envOr(
            "TRANSFER_AMOUNT",
            uint256(100 * 1e6)
        ); // Default: 100 USDC

        console.log("Transferring USDC from smart wallet:");
        console.log("From Wallet:", walletAddress);
        console.log("To Recipient:", recipient);
        console.log("Amount:", transferAmount);
        console.log("USDC Token:", usdcAddress);

        EIP7702Wallet wallet = EIP7702Wallet(payable(walletAddress));
        IERC20 usdc = IERC20(usdcAddress);

        // Verify wallet owner
        address walletOwner = wallet.owner();
        address deployer = vm.addr(deployerPrivateKey);
        // require(walletOwner == deployer, "You are not the owner of this wallet");

        // Check balances before
        uint256 walletBalance = usdc.balanceOf(walletAddress);
        uint256 recipientBalance = usdc.balanceOf(recipient);

        console.log("Before transfer:");
        console.log("Wallet USDC balance:", walletBalance);
        console.log("Recipient USDC balance:", recipientBalance);

        require(
            walletBalance >= transferAmount,
            "Insufficient USDC balance in wallet"
        );

        vm.startBroadcast(deployerPrivateKey);

        // Execute USDC transfer through smart wallet
        bytes memory transferData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            recipient,
            transferAmount
        );

        console.log("Executing USDC transfer...");

        wallet.execute(usdcAddress, 0, transferData);

        // Check balances after
        uint256 newWalletBalance = usdc.balanceOf(walletAddress);
        uint256 newRecipientBalance = usdc.balanceOf(recipient);

        console.log("After transfer:");
        console.log("Wallet USDC balance:", newWalletBalance);
        console.log("Recipient USDC balance:", newRecipientBalance);

        if (newRecipientBalance == recipientBalance + transferAmount) {
            console.log("USDC transfer successful!");
            console.log("Transfer Summary:");
            console.log("Amount sent:", transferAmount);
            console.log(
                "Wallet balance decreased by:",
                walletBalance - newWalletBalance
            );
            console.log(
                "Recipient balance increased by:",
                newRecipientBalance - recipientBalance
            );
        } else {
            console.log("Transfer may have failed. Check balances.");
        }

        vm.stopBroadcast();
    }
}
