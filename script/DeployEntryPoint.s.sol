// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "@account-abstraction/core/EntryPoint.sol";

/**
 * @title DeployEntryPoint
 * @dev Script to deploy EntryPoint v0.8 if not available on the network
 */
contract DeployEntryPoint is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying EntryPoint v0.8 with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy EntryPoint v0.8
        EntryPoint entryPoint = new EntryPoint();
        
        console.log("EntryPoint v0.8 deployed at:", address(entryPoint));
        
        vm.stopBroadcast();
        
        // Save deployment info
        string memory json = string(
            abi.encodePacked(
                '{\n',
                '  "entryPoint": "', vm.toString(address(entryPoint)), '",\n',
                '  "version": "0.8",\n',
                '  "deployedAt": ', vm.toString(block.timestamp), '\n',
                '}'
            )
        );
        
        vm.writeFile("deployments/entrypoint.json", json);
        console.log("EntryPoint deployment info saved to deployments/entrypoint.json");
    }
}
