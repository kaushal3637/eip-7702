// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/factories/EIP7702WalletFactory.sol";
import "../src/wallets/EIP7702Wallet.sol";

/**
 * @title CreateWallet
 * @dev Script to create a new EIP-7702 wallet
 */
contract CreateWallet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get factory address from environment or deployment file
        address factoryAddress = vm.envOr("WALLET_FACTORY", address(0));
        require(
            factoryAddress != address(0),
            "WALLET_FACTORY environment variable not set"
        );

        // Get owner address (default to deployer)
        address owner = vm.envOr("WALLET_OWNER", deployer);

        // Get salt (default to timestamp)
        uint256 salt = vm.envOr("WALLET_SALT", uint256(block.timestamp));

        console.log("Creating wallet with:");
        console.log("Factory:", factoryAddress);
        console.log("Owner:", owner);
        console.log("Salt:", salt);

        vm.startBroadcast(deployerPrivateKey);

        EIP7702WalletFactory factory = EIP7702WalletFactory(factoryAddress);

        // Check if wallet already exists
        address predictedWallet = factory.getWalletAddress(owner, salt);
        bool walletExists = factory.isValidWallet(predictedWallet);

        if (walletExists) {
            console.log("Wallet already exists at:", predictedWallet);
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

            console.log("Wallet verification passed");
        }

        vm.stopBroadcast();

        // Save wallet info
        saveWalletInfo(predictedWallet, owner, salt, factoryAddress);
    }

    function saveWalletInfo(
        address wallet,
        address owner,
        uint256 salt,
        address factory
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
