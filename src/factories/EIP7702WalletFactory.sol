// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "../wallets/EIP7702Wallet.sol";

/**
 * @title EIP7702WalletFactory
 * @dev Factory contract for deploying EIP-7702 compatible smart wallets
 */
contract EIP7702WalletFactory is Ownable {
    using Create2 for bytes32;

    // Events
    event WalletCreated(
        address indexed wallet,
        address indexed owner,
        uint256 salt
    );

    event ImplementationUpdated(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    // The wallet implementation contract
    address public walletImplementation;
    
    // Entry point contract
    IEntryPoint public immutable entryPoint;
    
    // Mapping to track deployed wallets
    mapping(address => bool) public isWalletDeployed;
    
    // Mapping from owner to their wallets
    mapping(address => address[]) public ownerToWallets;

    constructor(IEntryPoint _entryPoint, address initialOwner) Ownable(initialOwner) {
        require(address(_entryPoint) != address(0), "WalletFactory: EntryPoint cannot be zero address");
        
        entryPoint = _entryPoint;
        
        // Deploy the initial implementation
        walletImplementation = address(new EIP7702Wallet(_entryPoint));
        
        emit ImplementationUpdated(address(0), walletImplementation);
    }

    /**
     * @dev Create a new wallet for the given owner
     * @param owner The owner of the new wallet
     * @param salt A salt for deterministic address generation
     * @return wallet The address of the created wallet
     */
    function createWallet(address owner, uint256 salt) external returns (address wallet) {
        require(owner != address(0), "WalletFactory: owner cannot be zero address");
        
        bytes32 saltHash = keccak256(abi.encodePacked(owner, salt));
        
        // Use CREATE2 to deploy the wallet clone
        wallet = Clones.cloneDeterministic(walletImplementation, saltHash);
        
        // Initialize the wallet
        EIP7702Wallet(payable(wallet)).initialize(owner);
        
        // Track the deployed wallet
        isWalletDeployed[wallet] = true;
        ownerToWallets[owner].push(wallet);
        
        emit WalletCreated(wallet, owner, salt);
    }

    /**
     * @dev Get the deterministic address for a wallet
     * @param owner The owner of the wallet
     * @param salt The salt used for address generation
     * @return The predicted wallet address
     */
    function getWalletAddress(address owner, uint256 salt) external view returns (address) {
        bytes32 saltHash = keccak256(abi.encodePacked(owner, salt));
        return Clones.predictDeterministicAddress(walletImplementation, saltHash, address(this));
    }

    /**
     * @dev Create a wallet if it doesn't exist, otherwise return the existing one
     * @param owner The owner of the wallet
     * @param salt The salt for address generation
     * @return wallet The address of the wallet (created or existing)
     */
    function createWalletIfNeeded(address owner, uint256 salt) external returns (address wallet) {
        wallet = this.getWalletAddress(owner, salt);
        
        if (!isWalletDeployed[wallet]) {
            wallet = this.createWallet(owner, salt);
        }
        
        return wallet;
    }

    /**
     * @dev Get all wallets owned by an address
     * @param owner The owner address
     * @return An array of wallet addresses
     */
    function getWalletsForOwner(address owner) external view returns (address[] memory) {
        return ownerToWallets[owner];
    }

    /**
     * @dev Get the number of wallets owned by an address
     * @param owner The owner address
     * @return The number of wallets
     */
    function getWalletCountForOwner(address owner) external view returns (uint256) {
        return ownerToWallets[owner].length;
    }

    /**
     * @dev Update the wallet implementation (only owner)
     * @param newImplementation The new implementation address
     */
    function updateImplementation(address newImplementation) external onlyOwner {
        require(newImplementation != address(0), "WalletFactory: implementation cannot be zero address");
        require(newImplementation != walletImplementation, "WalletFactory: same implementation");
        
        // Verify it's a valid EIP7702Wallet implementation
        try EIP7702Wallet(payable(newImplementation)).supportsDelegation() returns (bool delegationSupport) {
            require(delegationSupport, "WalletFactory: invalid implementation");
        } catch {
            revert("WalletFactory: invalid implementation");
        }
        
        address oldImplementation = walletImplementation;
        walletImplementation = newImplementation;
        
        emit ImplementationUpdated(oldImplementation, newImplementation);
    }

    /**
     * @dev Check if an address is a wallet deployed by this factory
     * @param wallet The address to check
     * @return True if it's a deployed wallet
     */
    function isValidWallet(address wallet) external view returns (bool) {
        return isWalletDeployed[wallet];
    }

    /**
     * @dev Batch create multiple wallets
     * @param owners Array of wallet owners
     * @param salts Array of salts for each wallet
     * @return wallets Array of created wallet addresses
     */
    function createWalletsBatch(
        address[] calldata owners,
        uint256[] calldata salts
    ) external returns (address[] memory wallets) {
        require(owners.length == salts.length, "WalletFactory: arrays length mismatch");
        require(owners.length > 0, "WalletFactory: empty arrays");
        
        wallets = new address[](owners.length);
        
        for (uint256 i = 0; i < owners.length; i++) {
            wallets[i] = this.createWallet(owners[i], salts[i]);
        }
    }

    /**
     * @dev Emergency function to recover stuck ETH
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "WalletFactory: no ETH to withdraw");
        
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Get factory statistics
     * @return totalWallets The total number of wallets deployed
     * @return implementationAddress The current implementation address
     * @return entryPointAddress The entry point address
     */
    function getFactoryInfo() external view returns (
        uint256 totalWallets,
        address implementationAddress,
        address entryPointAddress
    ) {
        // Note: We don't track total wallets in this implementation
        // This would require additional storage and gas costs
        totalWallets = 0; // Could be implemented with a counter if needed
        implementationAddress = walletImplementation;
        entryPointAddress = address(entryPoint);
    }
}
