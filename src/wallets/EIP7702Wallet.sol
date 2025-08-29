// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@account-abstraction/core/BaseAccount.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";
import "@account-abstraction/interfaces/IPaymaster.sol";
import "../interfaces/IEIP7702Wallet.sol";

/**
 * @title EIP7702Wallet
 * @dev A smart wallet implementation supporting EIP-7702 account delegation and ERC-4337
 */
contract EIP7702Wallet is IEIP7702Wallet, BaseAccount, Initializable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Storage slots
    address private _owner;
    IEntryPoint private immutable _entryPoint;
    
    // Nonce for replay protection
    uint256 private _nonce;

    // Constants
    uint256 public constant SIGNATURE_LENGTH = 65;
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    modifier onlyOwner() {
        require(msg.sender == _owner, "EIP7702Wallet: caller is not the owner");
        _;
    }

    modifier onlyOwnerOrEntryPoint() {
        require(
            msg.sender == _owner || msg.sender == address(_entryPoint),
            "EIP7702Wallet: caller is not the owner or EntryPoint"
        );
        _;
    }

    constructor(IEntryPoint entryPointAddress) {
        _entryPoint = entryPointAddress;
        // Don't disable initializers for cloneable contracts
        // _disableInitializers();
    }

    /**
     * @dev Initialize the wallet with an owner
     * @param walletOwner The owner of the wallet
     */
    function initialize(address walletOwner) external initializer {
        require(walletOwner != address(0), "EIP7702Wallet: owner cannot be zero address");
        _owner = walletOwner;
        emit WalletInitialized(walletOwner, address(_entryPoint));
    }

    /**
     * @dev Execute a transaction from the wallet
     */
    function execute(address target, uint256 value, bytes calldata data) 
        external 
        override(BaseAccount, IEIP7702Wallet)
        onlyOwnerOrEntryPoint 
        nonReentrant
    {
        require(target != address(0), "EIP7702Wallet: target cannot be zero address");
        
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        
        emit TransactionExecuted(target, value, data, success);
        
        if (!success) {
            // If the transaction failed, revert with the returned data
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    /**
     * @dev Execute multiple transactions in a batch
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyOwnerOrEntryPoint nonReentrant returns (bool[] memory successes, bytes[] memory returnDatas) {
        require(targets.length == values.length, "EIP7702Wallet: targets and values length mismatch");
        require(targets.length == datas.length, "EIP7702Wallet: targets and datas length mismatch");
        require(targets.length > 0, "EIP7702Wallet: empty batch");

        successes = new bool[](targets.length);
        returnDatas = new bytes[](targets.length);

        for (uint256 i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "EIP7702Wallet: target cannot be zero address");
            
            (successes[i], returnDatas[i]) = targets[i].call{value: values[i]}(datas[i]);
            
            emit TransactionExecuted(targets[i], values[i], datas[i], successes[i]);
        }
    }

    /**
     * @dev Validate the user operation signature
     */
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);
        
        if (signer == _owner) {
            return 0; // Valid signature
        }
        
        return SIG_VALIDATION_FAILED; // Invalid signature
    }

    /**
     * @dev Return the entry point contract address
     */
    function entryPoint() public view override(BaseAccount, IEIP7702Wallet) returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev Get the current owner of the wallet
     */
    function owner() external view override returns (address) {
        return _owner;
    }

    /**
     * @dev Transfer ownership of the wallet
     */
    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "EIP7702Wallet: new owner cannot be zero address");
        require(newOwner != _owner, "EIP7702Wallet: new owner is the same as current owner");
        
        address oldOwner = _owner;
        _owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Check if the wallet supports EIP-7702 delegation
     */
    function supportsDelegation() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Get the current nonce for the wallet
     */
    function getNonce() public view override returns (uint256) {
        return _nonce;
    }

    /**
     * @dev Increment the nonce (called by EntryPoint)
     */
    function _incrementNonce() internal {
        _nonce++;
    }

    /**
     * @dev Handle post-operation logic
     */
    function _postOp(IPaymaster.PostOpMode mode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas)
        internal
    {
        _incrementNonce();
        // Additional post-operation logic can be added here
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {
        // Allow the wallet to receive ETH
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        // Allow the wallet to receive ETH and handle unknown function calls
    }

    /**
     * @dev Get the wallet's balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Emergency function to recover stuck tokens
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            // Withdraw ETH
            payable(_owner).transfer(amount);
        } else {
            // Withdraw ERC-20 token
            (bool success, ) = token.call(
                abi.encodeWithSignature("transfer(address,uint256)", _owner, amount)
            );
            require(success, "EIP7702Wallet: token transfer failed");
        }
    }
}
