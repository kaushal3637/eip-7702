// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@account-abstraction/interfaces/IAccount.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";

/**
 * @title IEIP7702Wallet
 * @dev Interface for EIP-7702 compatible smart wallets that support account delegation
 */
interface IEIP7702Wallet is IAccount {
    /**
     * @dev Emitted when the wallet is initialized
     * @param owner The owner of the wallet
     * @param entryPoint The entry point contract address
     */
    event WalletInitialized(address indexed owner, address indexed entryPoint);

    /**
     * @dev Emitted when ownership is transferred
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Emitted when a transaction is executed
     * @param target The target contract
     * @param value The value sent
     * @param data The transaction data
     * @param success Whether the transaction succeeded
     */
    event TransactionExecuted(address indexed target, uint256 value, bytes data, bool success);

    /**
     * @dev Initialize the wallet with an owner
     * @param owner The owner of the wallet
     */
    function initialize(address owner) external;

    /**
     * @dev Execute a transaction from the wallet
     * @param target The target contract
     * @param value The value to send
     * @param data The transaction data
     */
    function execute(address target, uint256 value, bytes calldata data) external;

    /**
     * @dev Execute multiple transactions in a batch
     * @param targets Array of target contracts
     * @param values Array of values to send
     * @param datas Array of transaction data
     * @return successes Array indicating which transactions succeeded
     * @return returnDatas Array of return data from transactions
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external returns (bool[] memory successes, bytes[] memory returnDatas);

    /**
     * @dev Get the current owner of the wallet
     * @return The owner address
     */
    function owner() external view returns (address);

    /**
     * @dev Transfer ownership of the wallet
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Check if the wallet supports EIP-7702 delegation
     * @return True if delegation is supported
     */
    function supportsDelegation() external pure returns (bool);

    /**
     * @dev Get the entry point contract address
     * @return The entry point address
     */
    function entryPoint() external view returns (IEntryPoint);
}
