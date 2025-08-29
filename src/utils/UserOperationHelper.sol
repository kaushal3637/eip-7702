// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@account-abstraction/interfaces/PackedUserOperation.sol";
import "@account-abstraction/interfaces/IEntryPoint.sol";

/**
 * @title UserOperationHelper
 * @dev Utility contract for creating and managing UserOperations
 */
library UserOperationHelper {
    /**
     * @dev Create a UserOperation for a simple transaction
     * @param sender The wallet address
     * @param target The target contract address
     * @param value The value to send
     * @param data The transaction data
     * @param paymaster The paymaster address (optional)
     * @param paymasterData The paymaster data (optional)
     * @return userOp The created UserOperation
     */
    function createUserOperation(
        address sender,
        address target,
        uint256 value,
        bytes memory data,
        address paymaster,
        bytes memory paymasterData
    ) internal pure returns (PackedUserOperation memory userOp) {
        // Encode the call data for wallet execution
        bytes memory callData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            target,
            value,
            data
        );

        userOp = PackedUserOperation({
            sender: sender,
            nonce: 0, // Will be filled by the caller
            initCode: "", // Empty for existing wallets
            callData: callData,
            accountGasLimits: bytes32(abi.encodePacked(uint128(2000000), uint128(2000000))), // verificationGasLimit, callGasLimit
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(uint128(1000000000), uint128(1000000000))), // maxPriorityFeePerGas, maxFeePerGas
            paymasterAndData: paymaster != address(0) ? 
                abi.encodePacked(paymaster, paymasterData) : 
                bytes(""),
            signature: bytes("") // Will be filled by the caller
        });
    }

    /**
     * @dev Create a UserOperation for batch transactions
     * @param sender The wallet address
     * @param targets Array of target addresses
     * @param values Array of values to send
     * @param datas Array of transaction data
     * @param paymaster The paymaster address (optional)
     * @param paymasterData The paymaster data (optional)
     * @return userOp The created UserOperation
     */
    function createBatchUserOperation(
        address sender,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory datas,
        address paymaster,
        bytes memory paymasterData
    ) internal pure returns (PackedUserOperation memory userOp) {
        // Encode the call data for wallet batch execution
        bytes memory callData = abi.encodeWithSignature(
            "executeBatch(address[],uint256[],bytes[])",
            targets,
            values,
            datas
        );

        userOp = PackedUserOperation({
            sender: sender,
            nonce: 0, // Will be filled by the caller
            initCode: "", // Empty for existing wallets
            callData: callData,
            accountGasLimits: bytes32(abi.encodePacked(uint128(3000000), uint128(3000000))), // Higher limits for batch
            preVerificationGas: 150000,
            gasFees: bytes32(abi.encodePacked(uint128(1000000000), uint128(1000000000))),
            paymasterAndData: paymaster != address(0) ? 
                abi.encodePacked(paymaster, paymasterData) : 
                bytes(""),
            signature: bytes("")
        });
    }

    /**
     * @dev Create a UserOperation for wallet deployment
     * @param sender The wallet address (predicted)
     * @param factory The factory address
     * @param owner The owner of the new wallet
     * @param salt The salt for deterministic deployment
     * @param target The target for the first transaction (optional)
     * @param value The value for the first transaction
     * @param data The data for the first transaction
     * @param paymaster The paymaster address (optional)
     * @param paymasterData The paymaster data (optional)
     * @return userOp The created UserOperation
     */
    function createWalletDeploymentUserOperation(
        address sender,
        address factory,
        address owner,
        uint256 salt,
        address target,
        uint256 value,
        bytes memory data,
        address paymaster,
        bytes memory paymasterData
    ) internal pure returns (PackedUserOperation memory userOp) {
        // Create initCode for wallet deployment
        bytes memory initCode = abi.encodePacked(
            factory,
            abi.encodeWithSignature("createWallet(address,uint256)", owner, salt)
        );

        // Create callData for the transaction (if any)
        bytes memory callData = target != address(0) ?
            abi.encodeWithSignature("execute(address,uint256,bytes)", target, value, data) :
            bytes("");

        userOp = PackedUserOperation({
            sender: sender,
            nonce: 0, // Always 0 for wallet deployment
            initCode: initCode,
            callData: callData,
            accountGasLimits: bytes32(abi.encodePacked(uint128(5000000), uint128(2000000))), // Higher verification limit for deployment
            preVerificationGas: 200000,
            gasFees: bytes32(abi.encodePacked(uint128(1000000000), uint128(1000000000))),
            paymasterAndData: paymaster != address(0) ? 
                abi.encodePacked(paymaster, paymasterData) : 
                bytes(""),
            signature: bytes("")
        });
    }

    /**
     * @dev Calculate the gas cost for a UserOperation
     * @param userOp The UserOperation
     * @return gasCost The estimated gas cost in wei
     */
    function calculateGasCost(PackedUserOperation memory userOp) internal pure returns (uint256 gasCost) {
        // Extract gas limits and fees from packed data
        uint128 verificationGasLimit = uint128(bytes16(userOp.accountGasLimits));
        uint128 callGasLimit = uint128(bytes16(userOp.accountGasLimits << 128));
        uint128 maxFeePerGas = uint128(bytes16(userOp.gasFees << 128));
        
        // Calculate total gas needed
        uint256 totalGas = uint256(verificationGasLimit) + uint256(callGasLimit) + userOp.preVerificationGas;
        
        // Calculate cost
        gasCost = totalGas * uint256(maxFeePerGas);
    }

    /**
     * @dev Extract gas parameters from UserOperation
     * @param userOp The UserOperation
     * @return verificationGasLimit The verification gas limit
     * @return callGasLimit The call gas limit
     * @return maxPriorityFeePerGas The max priority fee per gas
     * @return maxFeePerGas The max fee per gas
     */
    function extractGasParameters(PackedUserOperation memory userOp) 
        internal 
        pure 
        returns (
            uint128 verificationGasLimit,
            uint128 callGasLimit,
            uint128 maxPriorityFeePerGas,
            uint128 maxFeePerGas
        ) 
    {
        verificationGasLimit = uint128(bytes16(userOp.accountGasLimits));
        callGasLimit = uint128(bytes16(userOp.accountGasLimits << 128));
        maxPriorityFeePerGas = uint128(bytes16(userOp.gasFees));
        maxFeePerGas = uint128(bytes16(userOp.gasFees << 128));
    }

    /**
     * @dev Validate UserOperation parameters
     * @param userOp The UserOperation to validate
     * @return isValid True if the UserOperation is valid
     * @return reason The reason for invalidity (if any)
     */
    function validateUserOperation(PackedUserOperation memory userOp) 
        internal 
        pure 
        returns (bool isValid, string memory reason) 
    {
        if (userOp.sender == address(0)) {
            return (false, "Invalid sender");
        }

        (uint128 verificationGasLimit, uint128 callGasLimit, , uint128 maxFeePerGas) = 
            extractGasParameters(userOp);

        if (verificationGasLimit < 100000) {
            return (false, "Verification gas limit too low");
        }

        if (callGasLimit < 21000) {
            return (false, "Call gas limit too low");
        }

        if (maxFeePerGas == 0) {
            return (false, "Max fee per gas cannot be zero");
        }

        if (userOp.preVerificationGas < 21000) {
            return (false, "Pre-verification gas too low");
        }

        return (true, "");
    }
}
