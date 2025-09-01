// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/factories/EIP7702WalletFactory.sol";
import "../src/wallets/EIP7702Wallet.sol";

/**
 * @title CreateWalletWithUSDC
 * @dev Script to create a new EIP-7702 wallet with USDC gasless configuration
 */
contract CreateWalletWithUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get factory address from environment or deployment file
        address factoryAddress = vm.envOr("WALLET_FACTORY", address(0));
        require(
            factoryAddress != address(0),
            "WALLET_FACTORY environment variable not set"
        );

        // Configuration
        address owner = vm.envOr("WALLET_OWNER", deployer);
        address usdcToken = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));
        address gasSponsor = vm.envOr("GAS_SPONSOR", deployer); // Who receives gas fees
        uint256 exchangeRate = vm.envOr("EXCHANGE_RATE", uint256(2000 * 1e18)); // 4000 USDC per ETH
        uint256 salt = vm.envOr("WALLET_SALT", uint256(block.timestamp));

        console.log("Creating EIP-7702 wallet with USDC gasless configuration:");
        console.log("Factory:", factoryAddress);
        console.log("Owner:", owner);
        console.log("USDC Token:", usdcToken);
        console.log("Gas Sponsor:", gasSponsor);
        console.log("Exchange Rate:", exchangeRate / 1e18, "USDC per ETH");
        console.log("Salt:", salt);

        vm.startBroadcast(deployerPrivateKey);

        EIP7702WalletFactory factory = EIP7702WalletFactory(factoryAddress);

        // Check if wallet already exists
        address predictedWallet = factory.getWalletAddress(owner, salt);
        bool walletExists = factory.isValidWallet(predictedWallet);

        if (walletExists) {
            console.log("Wallet already exists at:", predictedWallet);

            // Get existing wallet and update configuration if needed
            EIP7702Wallet wallet = EIP7702Wallet(payable(predictedWallet));

            // Check current configuration
            (address currentUSDC, address currentSponsor, uint256 currentRate) = wallet.getUSDCConfig();

            console.log("Current USDC config:");
            console.log("USDC Token:", currentUSDC);
            console.log("Gas Sponsor:", currentSponsor);
            console.log("Exchange Rate:", currentRate / 1e18, "USDC per ETH");

            // Update configuration if different
            if (currentUSDC != usdcToken) {
                console.log("USDC token mismatch - wallet already configured");
            }
            if (currentSponsor != gasSponsor) {
                console.log("Updating gas sponsor...");
                wallet.updateGasSponsor(gasSponsor);
            }
            if (currentRate != exchangeRate) {
                console.log("Updating exchange rate...");
                wallet.updateExchangeRate(exchangeRate);
            }

        } else {
            // Create the wallet
            address wallet = factory.createWallet(owner, salt);
            console.log("Wallet created at:", wallet);

            // Verify the wallet
            require(factory.isValidWallet(wallet), "Wallet creation failed");

            EIP7702Wallet walletContract = EIP7702Wallet(payable(wallet));
            require(
                walletContract.owner() == owner,
                "Owner verification failed"
            );
            require(
                walletContract.supportsDelegation(),
                "Delegation support verification failed"
            );

            // Configure USDC settings
            console.log("Configuring USDC gasless settings...");
            walletContract.updateGasSponsor(gasSponsor);
            walletContract.updateExchangeRate(exchangeRate);

            // Verify configuration
            (address configuredUSDC, address configuredSponsor, uint256 configuredRate) = walletContract.getUSDCConfig();
            require(configuredUSDC == usdcToken, "USDC configuration failed");
            require(configuredSponsor == gasSponsor, "Gas sponsor configuration failed");
            require(configuredRate == exchangeRate, "Exchange rate configuration failed");

            console.log("USDC configuration verified successfully");

            // Test gas fee estimation
            uint256 estimatedFee = walletContract.estimateGasFee();
            console.log("Estimated gas fee for USDC transfer:", estimatedFee / 1e6, "USDC");
        }

        vm.stopBroadcast();

        // Save wallet info
        saveWalletInfo(predictedWallet, owner, salt, factoryAddress, usdcToken, gasSponsor, exchangeRate);
    }

    function saveWalletInfo(
        address wallet,
        address owner,
        uint256 salt,
        address factory,
        address usdcToken,
        address gasSponsor,
        uint256 exchangeRate
    ) internal {
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "wallet": "',
                vm.toString(wallet),
                '",\n',
                '  "owner": "',
                vm.toString(owner),
                '",\n',
                '  "salt": ',
                vm.toString(salt),
                ",\n",
                '  "factory": "',
                vm.toString(factory),
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
                '  "createdAt": ',
                vm.toString(block.timestamp),
                "\n",
                "}"
            )
        );

        string memory filename = string(
            abi.encodePacked("./wallets/wallet_", vm.toString(wallet), ".json")
        );

        try vm.writeFile(filename, json) {
            console.log("Wallet info saved to:", filename);
        } catch {
            console.log("Could not save wallet file - manual save required");
            console.log("Wallet JSON:", json);
        }
    }

    function getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;

        if (chainId == 11155111) return "Sepolia";

        return "Unknown";
    }
}
