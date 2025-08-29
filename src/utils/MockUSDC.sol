// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @dev Mock USDC token for testing purposes
 */
contract MockUSDC is ERC20, Ownable {
    uint8 private constant USDC_DECIMALS = 6;
    
    constructor(address initialOwner) ERC20("USD Coin", "USDC") Ownable(initialOwner) {
        // Mint initial supply to owner (1 million USDC)
        _mint(initialOwner, 1000000 * 10**USDC_DECIMALS);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation
     */
    function decimals() public pure override returns (uint8) {
        return USDC_DECIMALS;
    }

    /**
     * @dev Mint new tokens (only owner)
     * @param to The address to mint to
     * @param amount The amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from caller's balance
     * @param amount The amount to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burn tokens from a specific address (requires allowance)
     * @param from The address to burn from
     * @param amount The amount to burn
     */
    function burnFrom(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    /**
     * @dev Faucet function for testing - gives 1000 USDC to any address
     * @param to The address to give USDC to
     */
    function faucet(address to) external {
        require(to != address(0), "MockUSDC: cannot mint to zero address");
        _mint(to, 1000 * 10**USDC_DECIMALS); // 1000 USDC
    }

    /**
     * @dev Batch faucet for multiple addresses
     * @param recipients Array of addresses to give USDC to
     */
    function batchFaucet(address[] calldata recipients) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0)) {
                _mint(recipients[i], 1000 * 10**USDC_DECIMALS);
            }
        }
    }
}
