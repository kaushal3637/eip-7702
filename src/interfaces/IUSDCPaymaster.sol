// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@account-abstraction/interfaces/IPaymaster.sol";

/**
 * @title IUSDCPaymaster
 * @dev Interface for a paymaster that accepts USDC tokens for gas payment
 */
interface IUSDCPaymaster is IPaymaster {
    /**
     * @dev Emitted when USDC is used to pay for gas
     * @param user The user whose transaction was sponsored
     * @param usdcAmount The amount of USDC charged
     * @param gasPrice The gas price used
     * @param gasUsed The amount of gas used
     */
    event USDCGasPayment(
        address indexed user,
        uint256 usdcAmount,
        uint256 gasPrice,
        uint256 gasUsed
    );

    /**
     * @dev Emitted when the USDC/ETH exchange rate is updated
     * @param oldRate The previous exchange rate
     * @param newRate The new exchange rate
     */
    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);

    /**
     * @dev Emitted when the owner withdraws USDC
     * @param owner The owner address
     * @param amount The amount withdrawn
     */
    event USDCWithdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Get the USDC token contract address
     * @return The USDC token address
     */
    function usdcToken() external view returns (address);

    /**
     * @dev Get the current USDC/ETH exchange rate
     * @return The exchange rate (USDC per ETH, scaled by 1e18)
     */
    function exchangeRate() external view returns (uint256);

    /**
     * @dev Set the USDC/ETH exchange rate (only owner)
     * @param newRate The new exchange rate
     */
    function setExchangeRate(uint256 newRate) external;

    /**
     * @dev Calculate the USDC amount needed for a given gas cost
     * @param gasCost The gas cost in ETH (wei)
     * @return The USDC amount needed
     */
    function calculateUSDCAmount(uint256 gasCost) external view returns (uint256);

    /**
     * @dev Withdraw USDC from the paymaster (only owner)
     * @param amount The amount to withdraw
     */
    function withdrawUSDC(uint256 amount) external;


}
