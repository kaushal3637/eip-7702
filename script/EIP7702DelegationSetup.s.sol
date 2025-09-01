// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/wallets/EIP7702DelegatedWallet.sol";

/**
 * @title EIP7702DelegationSetup
 * @dev Script to set up EIP-7702 delegation for gasless USDC transfers
 * This demonstrates how to "upgrade" an EOA to use smart wallet functionality
 */
contract EIP7702DelegationSetup is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Configuration
        address usdcToken = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));
        address gasSponsor = vm.envOr("GAS_SPONSOR", deployer);
        uint256 exchangeRate = vm.envOr("EXCHANGE_RATE", uint256(2000 * 1e18)); // 2000 USDC per ETH

        console.log("=== EIP-7702 Delegation Setup ===");
        console.log("Deployer/EOA:", deployer);
        console.log("USDC Token:", usdcToken);
        console.log("Gas Sponsor:", gasSponsor);
        console.log("Exchange Rate:", exchangeRate / 1e18, "USDC per ETH");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the delegated wallet contract
        EIP7702DelegatedWallet delegatedWallet = new EIP7702DelegatedWallet();
        console.log("Delegated wallet contract deployed at:", address(delegatedWallet));

        // Initialize the delegated wallet with USDC configuration
        console.log("Initializing delegated wallet configuration...");
        delegatedWallet.initializeForDelegation(usdcToken, gasSponsor, exchangeRate);

        // Verify configuration
        (address configuredUSDC, address configuredSponsor, uint256 configuredRate) = delegatedWallet.getUSDCConfig();
        require(configuredUSDC == usdcToken, "USDC configuration failed");
        require(configuredSponsor == gasSponsor, "Gas sponsor configuration failed");
        require(configuredRate == exchangeRate, "Exchange rate configuration failed");

        console.log("Configuration verified successfully");

        // Check current USDC balance of the EOA
        uint256 usdcBalance = delegatedWallet.getUSDCBalance();
        console.log("Current USDC balance of EOA:", usdcBalance / 1e6, "USDC");

        // Estimate gas fee for a sample transfer
        uint256 estimatedFee = delegatedWallet.estimateGasFee(100000000); // 100 USDC
        console.log("Estimated gas fee for 100 USDC transfer:", estimatedFee / 1e6, "USDC");

        vm.stopBroadcast();

        console.log("\n=== EIP-7702 Delegation Ready ===");
        console.log("Your EOA can now use the following features:");
        console.log("1. Gasless USDC transfers using executeUSDCTransfer()");
        console.log("2. Arbitrary transaction execution using execute()");
        console.log("3. Dynamic gas fee calculation");
        console.log("4. Configurable exchange rates and gas sponsors");

        // Save delegation info
        saveDelegationInfo(
            deployer,
            address(delegatedWallet),
            usdcToken,
            gasSponsor,
            exchangeRate
        );

        console.log("\n=== Next Steps ===");
        console.log("1. Use EIP-7702 transaction to delegate your EOA to this contract");
        console.log("2. Your EOA will then have smart wallet functionality");
        console.log("3. Execute gasless USDC transfers directly from your EOA");
        console.log("4. No need to transfer funds to a separate wallet contract!");
    }

    function saveDelegationInfo(
        address eoa,
        address delegatedWallet,
        address usdcToken,
        address gasSponsor,
        uint256 exchangeRate
    ) internal {
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "eoa": "',
                vm.toString(eoa),
                '",\n',
                '  "delegatedWallet": "',
                vm.toString(delegatedWallet),
                '",\n',
                '  "usdcToken": "',
                vm.toString(usdcToken),
                '",\n',
                '  "gasSponsor": "',
                vm.toString(gasSponsor),
                '",\n',
                '  "exchangeRate": "',
                vm.toString(exchangeRate),
                '",\n',
                '  "network": "',
                getNetworkName(),
                '",\n',
                '  "setupAt": ',
                vm.toString(block.timestamp),
                "\n",
                "}"
            )
        );

        string memory filename = string(
            abi.encodePacked("./delegations/delegation_", vm.toString(eoa), ".json")
        );

        try vm.writeFile(filename, json) {
            console.log("Delegation info saved to:", filename);
        } catch {
            console.log("Could not save delegation file - manual save required");
            console.log("Delegation JSON:", json);
        }
    }

    function getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;

        if (chainId == 11155111) return "Sepolia";

        return "Unknown";
    }
}
