# EIP-7702 Gasless USDC Transfer System

## 🚀 Overview

This implementation provides a **complete EIP-7702 gasless transaction system** where wallets can send USDC to other EOAs with **gas fees paid entirely in USDC**. No ETH is required in the wallet - all transactions are truly gasless from the user's perspective.

### ✨ Key Features

- **🔥 USDC-Only Wallets**: Wallets operate with zero ETH balance
- **💰 Gas Fees in USDC**: Automatic conversion and deduction from wallet balance
- **⚡ EIP-7702 Integration**: Pure EIP-7702 transaction type support
- **🔧 Configurable Exchange Rates**: Dynamic USDC/ETH rate management
- **👥 Gas Sponsor System**: Designated address receives gas fees
- **✅ Balance Verification**: Ensures sufficient USDC for transfer + gas
- **🔄 Transaction Batching**: Support for multiple operations
- **🛡️ Emergency Functions**: Recovery mechanisms for stuck funds

---

## 📋 Prerequisites

- **Foundry** installed (`curl -L https://foundry.paradigm.xyz | bash`)
- **Node.js** and **npm** (for frontend)
- **Git** for version control
- **A funded wallet** on Sepolia testnet (for initial setup)

---

## 🛠️ Installation & Setup

### 1. Clone and Install Dependencies

```bash
git clone <your-repo-url>
cd EIP-7702

# Install Foundry dependencies
forge install

# Install frontend dependencies
cd frontend && npm install && cd ..
```

### 2. Environment Configuration

Create a `.env` file in the root directory:

```bash
# Deployer private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Network RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY

# Contract addresses (will be filled after deployment)
WALLET_FACTORY=0x...
USDC_TOKEN=0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
PAYMASTER_ADDRESS=0x...
WALLET_ADDRESS=0x...

# Configuration
WALLET_OWNER=0x...  # Your wallet address
GAS_SPONSOR=0x...   # Who receives gas fees (can be same as owner)
EXCHANGE_RATE=2000000000000000000000  # 2000 USDC per ETH
RECIPIENT_ADDRESS=0x...  # Test recipient address
TRANSFER_AMOUNT=100000000  # 100 USDC (6 decimals)
```

### 3. Build Contracts

```bash
forge build
```

---

## 🚀 Contract Deployment

### Phase 1: Deploy Core Contracts

Deploy the wallet factory and paymaster:

```bash
# Set your environment variables
export PRIVATE_KEY=your_private_key
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_key

# Deploy contracts
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Expected Output:**
```
WalletFactory deployed at: 0x...
USDCPaymaster deployed at: 0x...
```

Update your `.env` file with these addresses:
```bash
WALLET_FACTORY=0x_deployed_factory_address
PAYMASTER_ADDRESS=0x_deployed_paymaster_address
```

### Phase 2: Create USDC-Configured Wallet

```bash
# Create wallet with USDC gasless configuration
forge script script/CreateWalletWithUSDC.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**Expected Output:**
```
Creating EIP-7702 wallet with USDC gasless configuration:
Factory: 0x...
Owner: 0x...
USDC Token: 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
Gas Sponsor: 0x...
Exchange Rate: 2000 USDC per ETH
Wallet created at: 0x...
USDC configuration verified successfully
```

Update your `.env` with the wallet address:
```bash
WALLET_ADDRESS=0x_created_wallet_address
```

### Phase 3: Fund Wallet with USDC

Send USDC to your wallet address. For Sepolia testnet:

1. **Get Sepolia USDC** from a faucet or transfer from another wallet
2. **Send to your wallet address** (`WALLET_ADDRESS`)
3. **Verify balance**:

```bash
# Check USDC balance
cast call $USDC_TOKEN \
  "balanceOf(address)" $WALLET_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

---

## ⚡ Testing Gasless USDC Transfers

### Method 1: Foundry Script (Recommended)

```bash
# Execute gasless USDC transfer
forge script script/EIP7702GaslessTransfer.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**Expected Output:**
```
=== EIP-7702 Gasless USDC Transfer ===
Wallet: 0x...
Recipient: 0x...
Transfer Amount: 100 USDC
Gas Fee Amount: 1 USDC
USDC Token: 0x...

Initial wallet USDC balance: 1000 USDC
Initial recipient USDC balance: 0 USDC

Executing USDC transfer with gas payment...
✅ EIP-7702 Gasless USDC Transfer Successful!
Transferred: 100 USDC to recipient
Gas Fee Paid: 1 USDC
Total Deducted: 101 USDC
```

### Method 2: Manual Contract Interaction

```bash
# Check gas fee estimate
cast call $WALLET_ADDRESS \
  "estimateGasFee(uint256)" 100000000 \
  --rpc-url $SEPOLIA_RPC_URL

# Execute transfer manually
cast send $WALLET_ADDRESS \
  "executeUSDCTransfer(address,uint256,uint256)" \
  $RECIPIENT_ADDRESS 100000000 1000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Method 3: Frontend Interface

```bash
cd frontend
npm run dev
```

1. **Connect Wallet** (MetaMask with Sepolia network)
2. **Enter Recipient Address**
3. **Enter Transfer Amount** (see gas fee estimate)
4. **Click "Send USDC"**
5. **Confirm Transaction** (no gas fee in ETH!)

---

## 🔍 Verification & Testing

### Check Contract State

```bash
# Get wallet configuration
cast call $WALLET_ADDRESS \
  "getUSDCConfig()" \
  --rpc-url $SEPOLIA_RPC_URL

# Expected output: [usdc_token, gas_sponsor, exchange_rate]

# Get wallet owner
cast call $WALLET_ADDRESS \
  "owner()" \
  --rpc-url $SEPOLIA_RPC_URL

# Check USDC balance
cast call $USDC_TOKEN \
  "balanceOf(address)" $WALLET_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

### Test Different Scenarios

1. **Insufficient Balance Test**:
```bash
# Try to send more than wallet balance
forge script script/EIP7702GaslessTransfer.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
# Should revert with "insufficient USDC balance"
```

2. **Zero Gas Fee Test**:
```bash
# Send with 0 gas fee
cast send $WALLET_ADDRESS \
  "executeUSDCTransfer(address,uint256,uint256)" \
  $RECIPIENT_ADDRESS 100000000 0 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

3. **Configuration Update Test**:
```bash
# Update exchange rate
cast send $WALLET_ADDRESS \
  "updateExchangeRate(uint256)" 2500000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Update gas sponsor
cast send $WALLET_ADDRESS \
  "updateGasSponsor(address)" $NEW_SPONSOR \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## 🎨 Frontend Usage

### Running the DApp

```bash
cd frontend
npm run dev
```

### Features

1. **Wallet Connection**: Connect MetaMask/Sepolia
2. **Balance Display**: Shows USDC balance in real-time
3. **Gas Fee Estimation**: Shows transfer amount + gas fee
4. **Transaction History**: Track all transfers
5. **Gasless Transfers**: No ETH gas fees required

### Key UI Elements

- **Transfer Amount Input**: Enter USDC amount
- **Gas Fee Display**: Shows estimated gas cost in USDC
- **Total Cost**: Transfer amount + gas fee
- **Balance Check**: Ensures sufficient funds
- **Transaction Status**: Success/failure feedback

---

## ⚙️ Configuration Options

### Exchange Rate Management

```bash
# Update exchange rate (owner only)
cast send $WALLET_ADDRESS \
  "updateExchangeRate(uint256)" $NEW_RATE \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Current rate: 2000 * 1e18 = 2000 USDC per ETH
# Higher rate = lower gas fees for users
# Lower rate = higher gas fees for users
```

### Gas Sponsor Management

```bash
# Update gas sponsor (owner only)
cast send $WALLET_ADDRESS \
  "updateGasSponsor(address)" $NEW_SPONSOR \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Gas sponsor receives all gas fee payments
# Can be set to treasury, owner, or separate entity
```

### Multiple Wallets

```bash
# Create additional wallets with different configurations
export WALLET_SALT=12346
export GAS_SPONSOR=0xdifferent_sponsor_address

forge script script/CreateWalletWithUSDC.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

---

## 🔧 Advanced Usage

### Batch Operations

```solidity
// Execute multiple transfers in one transaction
address[] memory targets = new address[](2);
uint256[] memory values = new uint256[](2);
bytes[] memory datas = new bytes[](2);

// Transfer 1
targets[0] = usdcToken;
datas[0] = abi.encodeWithSignature(
  "transfer(address,uint256)",
  recipient1, 50000000
);

// Transfer 2
targets[1] = usdcToken;
datas[1] = abi.encodeWithSignature(
  "transfer(address,uint256)",
  recipient2, 30000000
);

wallet.executeBatch(targets, values, datas);
```

### Emergency Functions

```bash
# Emergency ETH withdrawal (if any ETH stuck)
cast send $WALLET_ADDRESS \
  "emergencyWithdrawETH()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Emergency token withdrawal
cast send $WALLET_ADDRESS \
  "emergencyWithdraw(address,uint256)" $TOKEN_ADDRESS $AMOUNT \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## 🐛 Troubleshooting

### Common Issues

1. **Transaction Reverts with "insufficient USDC balance"**
   - **Solution**: Ensure wallet has enough USDC for transfer + gas fee
   - **Check**: `cast call $USDC_TOKEN "balanceOf(address)" $WALLET_ADDRESS`

2. **"USDC token not set" Error**
   - **Solution**: Wallet wasn't initialized properly
   - **Fix**: Redeploy wallet or check initialization

3. **Gas estimation fails**
   - **Solution**: Check exchange rate configuration
   - **Check**: `cast call $WALLET_ADDRESS "getUSDCConfig()"`

4. **Frontend not connecting**
   - **Solution**: Ensure MetaMask is on Sepolia network
   - **Check**: Network ID should be `11155111`

### Debug Commands

```bash
# Check all wallet state
cast call $WALLET_ADDRESS "getUSDCConfig()" --rpc-url $SEPOLIA_RPC_URL
cast call $WALLET_ADDRESS "owner()" --rpc-url $SEPOLIA_RPC_URL
cast call $USDC_TOKEN "balanceOf(address)" $WALLET_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Check paymaster state
cast call $PAYMASTER_ADDRESS "getExchangeRate()" --rpc-url $SEPOLIA_RPC_URL
cast call $PAYMASTER_ADDRESS "getDeposit()" --rpc-url $SEPOLIA_RPC_URL
```

---

## 📊 Gas Fee Calculation

### How Gas Fees Work

1. **Gas Used**: Estimated based on transaction complexity
2. **Gas Price**: Current network gas price (in gwei)
3. **ETH Cost**: `gas_used * gas_price` (converted to ETH)
4. **USDC Cost**: `eth_cost * exchange_rate` (converted to USDC)

### Example Calculation

```
Gas Used: 65,000
Gas Price: 20 gwei = 20,000,000,000 wei
ETH Cost: 65,000 * 20,000,000,000 = 1,300,000,000,000,000,000 wei = 0.0013 ETH
USDC Cost: 0.0013 * 2,000 = 2.6 USDC
```

### Optimizing Gas Fees

1. **Lower Exchange Rate**: Reduces USDC gas fees
2. **Batch Transactions**: Multiple operations in one tx
3. **Efficient Contracts**: Optimized gas usage
4. **Gas Sponsor Competition**: Multiple sponsors can compete

---

## 🔒 Security Considerations

### Access Control
- Only wallet owner can execute transfers
- Owner can update exchange rates and gas sponsor
- Emergency functions available for recovery

### Fund Safety
- USDC remains in user's wallet until transfer
- Gas fees are calculated and deducted atomically
- Failed transactions don't consume gas fees

### Network Security
- All transactions verified on-chain
- No off-chain signature requirements for basic transfers
- Standard ERC-20 transfer security

---

## 🔥 EIP-7702 Direct Delegation (Advanced)

The latest implementation supports **true EIP-7702 delegation** where your existing EOA gets "upgraded" to use smart wallet functionality without transferring funds to a separate contract.

### Phase 1: Deploy Delegated Wallet Contract

```bash
# Deploy the delegated wallet contract
forge script script/EIP7702DelegationSetup.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**Creates:**
- `EIP7702DelegatedWallet.sol` - Contract designed for EIP-7702 delegation
- Stores configuration in `./delegations/delegation_[eoa].json`

### Phase 2: Set Up EIP-7702 Delegation

```bash
# Configure your EOA for delegation
export DELEGATED_WALLET=0x_deployed_delegated_wallet_address

forge script script/EIP7702DelegateEOA.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**This sets up:**
- EOA delegation configuration
- USDC gas payment settings
- Exchange rate management

### Phase 3: Execute Gasless Transfers

```bash
# Execute gasless USDC transfers directly from your EOA
forge script script/EIP7702DelegatedTransfer.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

### Key Advantages of Direct Delegation:

✅ **No Fund Transfer Required** - Works directly with EOA's USDC balance
✅ **Maintains EOA Functionality** - Can still use regular ETH transactions
✅ **True EIP-7702** - Uses actual delegation mechanism
✅ **Seamless Experience** - No separate wallet management
✅ **Backward Compatible** - Existing EOA tools still work

### How It Works:

```
Before: EOA → Transfer USDC → Smart Wallet → Gasless Transfer
After:  EOA (with delegation) → Direct Gasless Transfer
```

### Type 4 Transaction Example:

```javascript
// EIP-7702 Type 4 transaction structure
{
  type: 4,                    // EIP-7702 transaction type
  to: "0x_your_eoa_address", // The EOA being delegated
  delegation: "0x_delegated_wallet_contract", // Smart wallet code
  data: "0x",                // Empty for basic delegation
  gasLimit: 100000,
  gasPrice: "20000000000"
}
```

### Useful Links
- [EIP-7702 Specification](https://eips.ethereum.org/EIPS/eip-7702)
- [ERC-4337 Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
- [Sepolia Faucet](https://sepoliafaucet.com/)
- [Foundry Documentation](https://book.getfoundry.sh/)

