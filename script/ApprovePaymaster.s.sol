// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/wallets/EIP7702Wallet.sol";
import "../src/utils/MockUSDC.sol";

/**
 * @title ApprovePaymaster
 * @dev Script to approve the USDC paymaster to spend USDC from your smart wallet
 */
contract ApprovePaymaster is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get addresses from environment or use defaults from deployment
        address walletAddress = vm.envOr("WALLET_ADDRESS", address(0x4ba5d35B85855E7747746D70d09972D8b2aB6241));
        address paymasterAddress = vm.envOr("PAYMASTER_ADDRESS", address(0xbfDF0766BFD1BDD1Dd9C82eE21274c15F75c1f0E));
        address usdcAddress = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));
        uint256 approvalAmount = vm.envOr("APPROVAL_AMOUNT", type(uint256).max); // Default: unlimited approval
        
        console.log("Approving paymaster to spend USDC from wallet:");
        console.log("Wallet:", walletAddress);
        console.log("Paymaster:", paymasterAddress);
        console.log("USDC Token:", usdcAddress);
        console.log("Approval Amount:", approvalAmount);
        
        // Check if wallet exists and is valid
        if (walletAddress.code.length == 0) {
            console.log("ERROR: Wallet not deployed or has no code!");
            console.log("Please run CreateWallet script first or check the wallet address.");
            return;
        }
        
        EIP7702Wallet wallet = EIP7702Wallet(payable(walletAddress));
        
        // Verify the wallet owner
        try wallet.owner() returns (address walletOwner) {
            require(walletOwner == deployer, "You are not the owner of this wallet");
            console.log("Wallet Owner verified:", walletOwner);
        } catch {
            console.log("ERROR: Cannot verify wallet owner. Wallet may not be properly initialized.");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check current USDC balance
        IERC20 usdc = IERC20(usdcAddress);
        uint256 currentBalance = usdc.balanceOf(walletAddress);
        console.log("Current USDC balance in wallet:", currentBalance);
        
        // Check current allowance
        uint256 currentAllowance = usdc.allowance(walletAddress, paymasterAddress);
        console.log("Current allowance to paymaster:", currentAllowance);
        
        if (currentAllowance >= approvalAmount) {
            console.log("Paymaster already has sufficient allowance!");
        } else {
            // Execute approval through the smart wallet
            bytes memory approvalData = abi.encodeWithSignature(
                "approve(address,uint256)", 
                paymasterAddress, 
                approvalAmount
            );
            
            console.log("Executing approval transaction...");
            
            wallet.execute(usdcAddress, 0, approvalData);
            
            // Verify the approval worked
            uint256 newAllowance = usdc.allowance(walletAddress, paymasterAddress);
            console.log("New allowance to paymaster:", newAllowance);
            
            if (newAllowance >= approvalAmount) {
                console.log(" Approval successful! Paymaster can now spend USDC for gas fees.");
            } else {
                console.log(" Approval failed. Please check the transaction.");
            }
        }
        
        vm.stopBroadcast();
        
        // Save approval info
        string memory json = string(
            abi.encodePacked(
                '{\n',
                '  "wallet": "', vm.toString(walletAddress), '",\n',
                '  "paymaster": "', vm.toString(paymasterAddress), '",\n',
                '  "usdcToken": "', vm.toString(usdcAddress), '",\n',
                '  "approvalAmount": ', vm.toString(approvalAmount), ',\n',
                '  "approvedAt": ', vm.toString(block.timestamp), '\n',
                '}'
            )
        );
        
        try vm.writeFile("./approvals/approval.json", json) {
            console.log("Approval info saved to approvals/approval.json");
        } catch {
            console.log("Could not save approval file");
            console.log("Approval JSON:", json);
        }
    }
}
