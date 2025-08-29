// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "../src/wallets/EIP7702Wallet.sol";

/**
 * @title DeployWalletSimple
 * @dev Simple script to deploy a wallet without trying to fund it
 */
contract DeployWalletSimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get addresses
        address entryPoint = vm.envOr("ENTRY_POINT", address(0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108));
        
        console.log("Deploying simple wallet:");
        console.log("Owner:", deployer);
        console.log("EntryPoint:", entryPoint);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy wallet directly
        EIP7702Wallet wallet = new EIP7702Wallet(IEntryPoint(entryPoint));
        console.log("Wallet deployed at:", address(wallet));
        
        // Initialize the wallet
        wallet.initialize(deployer);
        console.log("Wallet initialized");
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Simple wallet deployed!");
        console.log("Address:", address(wallet));
    }
}
