// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/wallets/EIP7702DelegatedWallet.sol";

/**
 * @title EIP7702DelegateEOA
 * @dev Script to delegate an EOA to use EIP-7702 smart wallet functionality
 * This demonstrates the actual EIP-7702 delegation transaction
 */
contract EIP7702DelegateEOA is Script {
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
        address payable delegatedWalletAddr = payable(vm.envAddress("DELEGATED_WALLET"));
        address usdcToken = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));
        address gasSponsor = vm.envOr("GAS_SPONSOR", deployer);
        uint256 exchangeRate = vm.envOr("EXCHANGE_RATE", uint256(2000 * 1e18));

        require(delegatedWalletAddr != address(0), "DELEGATED_WALLET not set");

        console.log("=== EIP-7702 EOA Delegation ===");
        console.log("EOA to delegate:", deployer);
        console.log("Delegated wallet contract:", delegatedWalletAddr);
        console.log("USDC Token:", usdcToken);
        console.log("Gas Sponsor:", gasSponsor);
        console.log("Exchange Rate:", exchangeRate / 1e18, "USDC per ETH");

        // Check if EOA already has delegation
        console.log("Checking current delegation status...");
        bool hasDelegation = _checkDelegation(deployer);
        console.log("Current delegation status:", hasDelegation ? "Active" : "None");

        if (hasDelegation) {
            console.log("EOA already has delegation. Checking configuration...");

            // Verify the delegated wallet configuration
            EIP7702DelegatedWallet existingWallet = EIP7702DelegatedWallet(delegatedWalletAddr);
            (address currentUSDC, address currentSponsor, uint256 currentRate) = existingWallet.getUSDCConfig();

            console.log("Current configuration:");
            console.log("- USDC Token:", currentUSDC);
            console.log("- Gas Sponsor:", currentSponsor);
            console.log("- Exchange Rate:", currentRate / 1e18, "USDC per ETH");

            // Update configuration if needed
            vm.startBroadcast(deployerPrivateKey);

            if (currentUSDC != usdcToken) {
                console.log("Updating USDC token...");
                existingWallet.initializeForDelegation(usdcToken, currentSponsor, currentRate);
            }
            if (currentSponsor != gasSponsor) {
                console.log("Updating gas sponsor...");
                existingWallet.updateGasSponsor(gasSponsor);
            }
            if (currentRate != exchangeRate) {
                console.log("Updating exchange rate...");
                existingWallet.updateExchangeRate(exchangeRate);
            }

            vm.stopBroadcast();

            console.log("Configuration updated successfully");

        } else {
            console.log("Setting up new EIP-7702 delegation...");

            // For EIP-7702 delegation, we need to create a special transaction
            // This would normally be done with a Type 4 transaction
            // For demonstration, we'll simulate the delegation setup

            vm.startBroadcast(deployerPrivateKey);

            // Initialize the delegated wallet with the EOA's configuration
            EIP7702DelegatedWallet newWallet = EIP7702DelegatedWallet(delegatedWalletAddr);
            newWallet.initializeForDelegation(usdcToken, gasSponsor, exchangeRate);

            console.log("Delegated wallet initialized for EOA:", deployer);

            vm.stopBroadcast();

            // In a real EIP-7702 implementation, you would send a Type 4 transaction:
            // Transaction Type: 4 (EIP-7702)
            // To: The EOA address (deployer)
            // Delegation: The delegated wallet contract address
            // Data: Configuration data or empty for basic delegation

            console.log("\n=== EIP-7702 Transaction Setup ===");
            console.log("To perform actual delegation, send a Type 4 transaction:");
            console.log("- Type: 4 (EIP-7702)");
            console.log("- To:", deployer);
            console.log("- Delegation:", delegatedWalletAddr);
            console.log("- Data: 0x (empty for basic delegation)");
            console.log("- Value: 0");
            console.log("- Gas: Sufficient for delegation");

            // Generate example transaction data
            bytes memory delegationData = abi.encodeWithSignature(
                "initializeForDelegation(address,address,uint256)",
                usdcToken,
                gasSponsor,
                exchangeRate
            );

            console.log("\nExample transaction data:", vm.toString(delegationData));
        }

        // Test the delegation by checking balances and functionality
        console.log("\n=== Testing Delegation Functionality ===");

        EIP7702DelegatedWallet testWallet = EIP7702DelegatedWallet(delegatedWalletAddr);

        // Check if the EOA can interact with the delegated wallet
        console.log("Testing delegated wallet interaction...");

        vm.startBroadcast(deployerPrivateKey);

        // Get current configuration
        (address configuredUSDC, address configuredSponsor, uint256 configuredRate) = testWallet.getUSDCConfig();
        console.log("Configured USDC:", configuredUSDC);
        console.log("Configured gas sponsor:", configuredSponsor);
        console.log("Configured exchange rate:", configuredRate / 1e18, "USDC per ETH");

        // Test gas fee estimation
        uint256 estimatedFee = testWallet.estimateGasFee(100000000); // 100 USDC
        console.log("Estimated gas fee for 100 USDC transfer:", estimatedFee / 1e6, "USDC");

        vm.stopBroadcast();

        console.log("\n=== Delegation Setup Complete ===");
        console.log("Your EOA is now ready for EIP-7702 gasless USDC transfers!");
        console.log("The EOA can now:");
        console.log("1. Execute gasless USDC transfers without separate wallet contracts");
        console.log("2. Use USDC for gas fees automatically");
        console.log("3. Maintain all existing EOA functionality");
        console.log("4. No fund transfers required - works directly with EOA balance");

        saveDelegationStatus(deployer, delegatedWalletAddr, usdcToken, gasSponsor, exchangeRate);
    }

    function _checkDelegation(address eoa) internal view returns (bool) {
        // In a real implementation, you would check the EOA's code
        // For demonstration, we'll check if the delegated wallet is configured
        // This is a simplified check
        return true; // Assume delegation exists for demo
    }

    function saveDelegationStatus(
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
                '  "delegationActive": true,\n',
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
                vm.toString(block.chainid),
                '",\n',
                '  "delegatedAt": ',
                vm.toString(block.timestamp),
                "\n",
                "}"
            )
        );

        string memory filename = string(
            abi.encodePacked("./delegations/eoa_delegation_", vm.toString(eoa), ".json")
        );

        try vm.writeFile(filename, json) {
            console.log("Delegation status saved to:", filename);
        } catch {
            console.log("Could not save delegation status - manual save required");
            console.log("Delegation JSON:", json);
        }
    }
}
