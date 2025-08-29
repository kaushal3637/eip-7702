// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "../src/factories/EIP7702WalletFactory.sol";
import "../src/paymasters/USDCPaymaster.sol";

/**
 * @title Deploy
 * @dev Deployment script for the EIP-7702 wallet system
 */
contract Deploy is Script {
    // Sepolia EntryPoint address (official ERC-4337 EntryPoint v0.8)
    address constant SEPOLIA_ENTRYPOINT =
        0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108;

    // Sepolia USDC address
    address constant SEPOLIA_USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Get network-specific addresses
        (address entryPoint, address usdcToken) = getNetworkAddresses();

        console.log("Using EntryPoint:", entryPoint);
        console.log("Using USDC:", usdcToken);

        // Deploy the wallet factory
        EIP7702WalletFactory walletFactory = new EIP7702WalletFactory(
            IEntryPoint(entryPoint),
            deployer
        );

        console.log("WalletFactory deployed at:", address(walletFactory));

        // Deploy the USDC paymaster
        // Initial exchange rate: 1 ETH = 4000 USDC (2000 * 1e18)
        uint256 initialExchangeRate = 4000 * 1e18;

        USDCPaymaster usdcPaymaster = new USDCPaymaster(
            IEntryPoint(entryPoint),
            usdcToken,
            initialExchangeRate,
            deployer
        );

        console.log("USDCPaymaster deployed at:", address(usdcPaymaster));

        // Add stake to the paymaster (0.1 ETH)
        uint256 stakeAmount = 0.1 ether;
        if (deployer.balance >= stakeAmount) {
            usdcPaymaster.addStake{value: stakeAmount}(1 days);
            console.log("Added stake to paymaster:", stakeAmount);
        } else {
            console.log("Insufficient balance to add stake");
        }

        // Deposit some ETH to the paymaster for gas sponsorship
        uint256 depositAmount = 0.05 ether;
        if (deployer.balance >= depositAmount) {
            IEntryPoint(entryPoint).depositTo{value: depositAmount}(
                address(usdcPaymaster)
            );
            console.log("Deposited to paymaster:", depositAmount);
        } else {
            console.log("Insufficient balance to deposit");
        }

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Network:", getNetworkName());
        console.log("EntryPoint:", entryPoint);
        console.log("USDC Token:", usdcToken);
        console.log("WalletFactory:", address(walletFactory));
        console.log("USDCPaymaster:", address(usdcPaymaster));
        console.log(
            "Exchange Rate (USDC per ETH):",
            initialExchangeRate / 1e18
        );

        // Save deployment addresses to file
        saveDeploymentInfo(
            address(walletFactory),
            address(usdcPaymaster),
            usdcToken,
            entryPoint
        );
    }

    function getNetworkAddresses()
        internal
        returns (address entryPoint, address usdcToken)
    {
        uint256 chainId = block.chainid;

        if (chainId == 11155111) {
            // Sepolia
            entryPoint = SEPOLIA_ENTRYPOINT;
            usdcToken = SEPOLIA_USDC;
        } else {
            // In a real scenario, you'd deploy the EntryPoint too
            revert(
                "Unsupported network. Please deploy EntryPoint first or use supported network."
            );
        }
    }

    function getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;

        if (chainId == 11155111) return "Sepolia";

        return "Unknown";
    }

    function saveDeploymentInfo(
        address walletFactory,
        address usdcPaymaster,
        address usdcToken,
        address entryPoint
    ) internal {
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "network": "',
                getNetworkName(),
                '",\n',
                '  "chainId": ',
                vm.toString(block.chainid),
                ",\n",
                '  "entryPoint": "',
                vm.toString(entryPoint),
                '",\n',
                '  "usdcToken": "',
                vm.toString(usdcToken),
                '",\n',
                '  "walletFactory": "',
                vm.toString(walletFactory),
                '",\n',
                '  "usdcPaymaster": "',
                vm.toString(usdcPaymaster),
                '",\n',
                '  "deployedAt": ',
                vm.toString(block.timestamp),
                "\n",
                "}"
            )
        );

        string memory filename = string(
            abi.encodePacked("./deployments/", getNetworkName(), ".json")
        );

        try vm.writeFile(filename, json) {
            console.log("Deployment info saved to:", filename);
        } catch {
            console.log(
                "Could not save deployment file - manual save required"
            );
            console.log("Deployment JSON:", json);
        }
    }
}
