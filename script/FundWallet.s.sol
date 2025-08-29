// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITestUSDC is IERC20 {
    function faucet(address to) external;
}

/**
 * @title FundWallet
 * @dev Script to fund your smart wallet with USDC (for testnet)
 */
contract FundWallet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get addresses
        address walletAddress = vm.envOr("WALLET_ADDRESS", address(0x5cC3291Bf5113551eBa8Cc5d531b22BE0e0b4515));
        address usdcAddress = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));
        uint256 fundAmount = vm.envOr("FUND_AMOUNT", uint256(1000 * 1e6)); // Default: 1000 USDC
        
        console.log("Funding wallet with USDC:");
        console.log("Wallet:", walletAddress);
        console.log("USDC Token:", usdcAddress);
        console.log("Fund Amount:", fundAmount);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Attach USDC interface
        ITestUSDC usdc = ITestUSDC(usdcAddress);
        
        // Check current balance
        uint256 currentBalance = usdc.balanceOf(walletAddress);
        console.log("Current USDC balance:", currentBalance);
        
        try usdc.faucet(walletAddress) {
            console.log(" Faucet successful! Added USDC to wallet.");
            
            uint256 newBalance = usdc.balanceOf(walletAddress);
            console.log("New USDC balance:", newBalance);
        } catch {
            console.log(" Faucet failed. This might be a real USDC token.");
            console.log("For testnet, you may need to get USDC from a different faucet.");
            console.log("For mainnet, you need to transfer real USDC to your wallet.");
        }
        
        vm.stopBroadcast();
    }
}
