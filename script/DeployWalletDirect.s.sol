// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "../src/wallets/EIP7702Wallet.sol";
import "../src/utils/MockUSDC.sol";

/**
 * @title DeployWalletDirect
 * @dev Script to deploy a wallet directly (not via factory) for testing
 */
contract DeployWalletDirect is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get addresses
        address entryPoint = vm.envOr("ENTRY_POINT", address(0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108));
        address usdcAddress = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));
        
        console.log("Deploying wallet directly:");
        console.log("Owner:", deployer);
        console.log("EntryPoint:", entryPoint);
        console.log("USDC Token:", usdcAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy wallet directly
        EIP7702Wallet wallet = new EIP7702Wallet(IEntryPoint(entryPoint));
        
        console.log("Wallet deployed at:", address(wallet));
        
        // Initialize the wallet
        wallet.initialize(deployer);
        
        console.log("Wallet initialized with owner:", deployer);
        
        // Verify the wallet works
        address walletOwner = wallet.owner();
        console.log("Verified owner:", walletOwner);
        require(walletOwner == deployer, "Owner verification failed");
        
        // Check if wallet supports delegation
        bool supportsDelegation = wallet.supportsDelegation();
        console.log("Supports delegation:", supportsDelegation);
        
        // Check USDC balance
        IERC20 usdc = IERC20(usdcAddress);
        uint256 usdcBalance = usdc.balanceOf(address(wallet));
        console.log("Initial USDC balance:", usdcBalance);
        
        // Try to get some USDC from faucet
        try MockUSDC(usdcAddress).faucet(address(wallet)) {
            uint256 newBalance = usdc.balanceOf(address(wallet));
            console.log("After faucet USDC balance:", newBalance);
        } catch {
            console.log("Could not use faucet (might be real USDC)");
        }
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Wallet deployed and working!");
        console.log("Wallet address:", address(wallet));
        console.log("You can now use this wallet for USDC transactions.");
        
        // Save wallet info
        string memory json = string(
            abi.encodePacked(
                '{\n',
                '  "wallet": "', vm.toString(address(wallet)), '",\n',
                '  "owner": "', vm.toString(deployer), '",\n',
                '  "entryPoint": "', vm.toString(entryPoint), '",\n',
                '  "usdcToken": "', vm.toString(usdcAddress), '",\n',
                '  "deploymentType": "direct",\n',
                '  "deployedAt": ', vm.toString(block.timestamp), '\n',
                '}'
            )
        );
        
        try vm.writeFile("./wallets/direct_wallet.json", json) {
            console.log("Wallet info saved to wallets/direct_wallet.json");
        } catch {
            console.log("Could not save wallet file");
            console.log("Wallet JSON:", json);
        }
    }
}
