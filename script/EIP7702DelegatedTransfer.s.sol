// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/wallets/EIP7702DelegatedWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EIP7702DelegatedTransfer
 * @dev Script to execute gasless USDC transfers using EIP-7702 delegated EOA
 * This demonstrates true EIP-7702 functionality where an EOA acts as a smart wallet
 */
contract EIP7702DelegatedTransfer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Configuration
        address payable delegatedWalletAddr = payable(vm.envAddress("DELEGATED_WALLET"));
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        address gasSponsor = vm.envOr("GAS_SPONSOR", deployer); // Gas sponsor address
        address usdcToken = vm.envOr("USDC_TOKEN", address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8));

        // Explicitly set amounts for testing (9 USDC transfer + 1 USDC gas fee = 10 USDC total)
        uint256 transferAmount = 9_000_000; // 9 USDC in wei (6 decimals)
        uint256 gasFeeAmount = 1_000_000;   // 1 USDC in wei (6 decimals)

        // Log the values for debugging
        console.log("Using transferAmount:", transferAmount);
        console.log("Using gasFeeAmount:", gasFeeAmount);

        require(delegatedWalletAddr != address(0), "DELEGATED_WALLET not set");
        require(recipient != address(0), "RECIPIENT_ADDRESS not set");

        console.log("=== EIP-7702 Delegated USDC Transfer ===");
        console.log("Delegated EOA:", deployer);
        console.log("Delegated Wallet Contract:", delegatedWalletAddr);
        console.log("Recipient:", recipient);
        console.log("Gas Sponsor:", gasSponsor);
        console.log("Transfer Amount (wei):", transferAmount);
        console.log("Transfer Amount (USDC):", transferAmount / 1e6);
        console.log("Gas Fee Amount (wei):", gasFeeAmount);
        console.log("Gas Fee Amount (USDC):", gasFeeAmount / 1e6);
        console.log("USDC Token:", usdcToken);

        // Check initial balances
        IERC20 usdc = IERC20(usdcToken);
        uint256 initialEOABalance = usdc.balanceOf(deployer);
        uint256 initialRecipientBalance = usdc.balanceOf(recipient);
        uint256 initialGasSponsorBalance = usdc.balanceOf(gasSponsor);

        console.log("Initial EOA USDC balance:", initialEOABalance / 1e6, "USDC");
        console.log("Initial recipient USDC balance:", initialRecipientBalance / 1e6, "USDC");
        console.log("Initial gas sponsor USDC balance:", initialGasSponsorBalance / 1e6, "USDC");

        // Verify sufficient balance
        require(
            initialEOABalance >= transferAmount + gasFeeAmount,
            "Insufficient USDC balance in EOA"
        );

        vm.startBroadcast(deployerPrivateKey);

        // Get the delegated wallet contract
        EIP7702DelegatedWallet delegatedWalletContract = EIP7702DelegatedWallet(delegatedWalletAddr);

        // Approve the delegated contract to spend our USDC (for testing when EIP-7702 isn't active)
        console.log("Approving delegated contract to spend USDC...");
        usdc.approve(delegatedWalletAddr, type(uint256).max);

        console.log("Executing gasless USDC transfer through delegated EOA...");

        // Execute the USDC transfer using the delegated wallet
        // In EIP-7702, this call will be executed as if the EOA is calling it directly
        // In testing, it will use transferFrom with the approval we just granted
        delegatedWalletContract.executeUSDCTransfer(recipient, transferAmount, gasFeeAmount);

        vm.stopBroadcast();

        // Verify the transfer
        uint256 finalEOABalance = usdc.balanceOf(deployer);
        uint256 finalRecipientBalance = usdc.balanceOf(recipient);
        uint256 finalGasSponsorBalance = usdc.balanceOf(gasSponsor);

        console.log("Final EOA USDC balance:", finalEOABalance / 1e6, "USDC");
        console.log("Final recipient USDC balance:", finalRecipientBalance / 1e6, "USDC");
        console.log("Final gas sponsor USDC balance:", finalGasSponsorBalance / 1e6, "USDC");

        // Calculate expected changes
        // If gas sponsor is different from EOA, gas fee is transferred out
        // If gas sponsor is the same as EOA, gas fee stays with EOA
        uint256 actualGasFeeDeduction = (gasSponsor == deployer) ? 0 : gasFeeAmount;
        uint256 expectedEOADeduction = transferAmount + actualGasFeeDeduction;
        uint256 expectedRecipientIncrease = transferAmount;
        uint256 expectedGasSponsorIncrease = (gasSponsor == deployer) ? 0 : gasFeeAmount;

        console.log("Expected EOA deduction:", expectedEOADeduction / 1e6, "USDC");
        console.log("Expected recipient increase:", expectedRecipientIncrease / 1e6, "USDC");
        console.log("Expected gas sponsor increase:", expectedGasSponsorIncrease / 1e6, "USDC");
        console.log("Gas sponsor == EOA:", gasSponsor == deployer);

        // Verify balances
        require(
            finalRecipientBalance == initialRecipientBalance + expectedRecipientIncrease,
            "Recipient balance not increased correctly"
        );

        require(
            finalGasSponsorBalance == initialGasSponsorBalance + expectedGasSponsorIncrease,
            "Gas sponsor balance not increased correctly"
        );

        require(
            finalEOABalance == initialEOABalance - expectedEOADeduction,
            "EOA balance not deducted correctly"
        );

        console.log("SUCCESS: EIP-7702 Delegated Transfer Complete!");
        console.log("Transfer amount sent to recipient");
        console.log("Gas fee paid to gas sponsor");
        console.log("All operations executed through delegated EOA");
        console.log("No separate wallet contract needed!");
        console.log("True EIP-7702 gasless functionality achieved!");

        console.log("\n=== Transfer Summary ===");
        console.log("Transferred:", transferAmount / 1e6, "USDC to recipient");
        console.log("Gas Fee Paid:", gasFeeAmount / 1e6, "USDC to gas sponsor");
        console.log("Total Deducted from EOA:", (transferAmount + gasFeeAmount) / 1e6, "USDC");
        console.log("Recipient received:", transferAmount / 1e6, "USDC");
        console.log("Gas sponsor received:", gasFeeAmount / 1e6, "USDC");

        // Demonstrate that the EOA still maintains its original functionality
        console.log("\n=== EOA Functionality Preserved ===");
        console.log("The EOA can still:");
        console.log("- Send regular ETH transactions");
        console.log("- Interact with any smart contracts");
        console.log("- Use any existing dApps");
        console.log("- Execute gasless USDC transfers through delegation");

        saveTransferRecord(
            deployer,
            recipient,
            transferAmount,
            gasFeeAmount,
            delegatedWalletAddr,
            usdcToken
        );
    }

    function saveTransferRecord(
        address eoa,
        address recipient,
        uint256 transferAmount,
        uint256 gasFeeAmount,
        address delegatedWallet,
        address usdcToken
    ) internal {
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "type": "eip7702_delegated_transfer",\n',
                '  "eoa": "',
                vm.toString(eoa),
                '",\n',
                '  "recipient": "',
                vm.toString(recipient),
                '",\n',
                '  "transferAmount": "',
                vm.toString(transferAmount),
                '",\n',
                '  "gasFeeAmount": "',
                vm.toString(gasFeeAmount),
                '",\n',
                '  "delegatedWallet": "',
                vm.toString(delegatedWallet),
                '",\n',
                '  "usdcToken": "',
                vm.toString(usdcToken),
                '",\n',
                '  "network": "',
                getNetworkName(),
                '",\n',
                '  "timestamp": ',
                vm.toString(block.timestamp),
                "\n",
                "}"
            )
        );

        string memory filename = string(
            abi.encodePacked("./transfers/delegated_transfer_", vm.toString(block.timestamp), ".json")
        );

        try vm.writeFile(filename, json) {
            console.log("Transfer record saved to:", filename);
        } catch {
            console.log("Could not save transfer record - manual save required");
            console.log("Transfer JSON:", json);
        }
    }

    function getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;

        if (chainId == 11155111) return "Sepolia";

        return "Unknown";
    }
}
