# EIP-7702 + ERC-4337 USDC Gas Payment System

This project implements a complete account abstraction system using EIP-7702 and ERC-4337 that allows users to pay transaction fees in USDC instead of ETH. Users can send USDC transactions even when they have no ETH in their wallet.

## 🚀 Features

- **EIP-7702 Smart Wallets**: Account delegation support for enhanced functionality
- **ERC-4337 Account Abstraction**: Gasless transactions via UserOperations
- **USDC Gas Payment**: Pay transaction fees in USDC instead of ETH
- **Paymaster System**: Automated gas sponsorship with USDC conversion
- **Batch Operations**: Execute multiple transactions in a single operation
- **Deterministic Addresses**: Predictable wallet addresses using CREATE2
- **Emergency Recovery**: Built-in recovery mechanisms for stuck funds

## 📋 Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Node.js and npm (for additional tooling)
- An Ethereum wallet with some ETH for deployment
- Alchemy API key (or other RPC provider)

## 🛠️ Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd EIP-7702
```

2. Install dependencies:
```bash
forge install
```

3. Copy environment configuration:
```bash
cp env.example .env
```

4. Fill in your `.env` file with:
   - `PRIVATE_KEY`: Your deployment private key (without 0x prefix)
   - `ALCHEMY_API_KEY`: Your Alchemy API key
   - Other configuration as needed

## 🏗️ Architecture

### Core Contracts

1. **EIP7702Wallet** (`src/wallets/EIP7702Wallet.sol`)
   - Smart wallet with EIP-7702 delegation support
   - ERC-4337 compatible account abstraction
   - Owner-based access control
   - Batch transaction execution

2. **USDCPaymaster** (`src/paymasters/USDCPaymaster.sol`)
   - Sponsors gas fees in exchange for USDC
   - Dynamic exchange rate management
   - Fee markup configuration
   - Stake management for EntryPoint

3. **EIP7702WalletFactory** (`src/factories/EIP7702WalletFactory.sol`)
   - Deterministic wallet deployment using CREATE2
   - Batch wallet creation
   - Wallet registry and validation

4. **UserOperationHelper** (`src/utils/UserOperationHelper.sol`)
   - Utility functions for creating UserOperations
   - Gas calculation and validation
   - Support for deployment and execution operations

### System Flow

```
User → UserOperation → EntryPoint → Paymaster (USDC) → Smart Wallet → Target Contract
                                  ↓
                               Gas Payment in USDC
```

## 🚀 Quick Start

### 1. Deploy the System

Deploy to Sepolia testnet:
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

This will deploy:
- Wallet Factory
- USDC Paymaster
- Mock USDC (on testnets)

### 2. Create a Smart Wallet

```bash
# Set environment variables
export WALLET_FACTORY=<deployed_factory_address>
export WALLET_OWNER=<your_address>
export WALLET_SALT=12345

# Create wallet
forge script script/CreateWallet.s.sol --rpc-url sepolia --broadcast
```

### 3. Fund Your Wallet with USDC

For testnets using Mock USDC:
```bash
# The wallet creation script automatically gives 1000 USDC via faucet
```

For mainnet or real USDC:
```bash
# Transfer USDC to your wallet address manually
```

### 4. Approve Paymaster to Spend USDC

Your wallet needs to approve the paymaster to spend USDC for gas:
```solidity
// Approve paymaster to spend USDC
usdc.approve(paymasterAddress, amount);
```

### 5. Execute Transactions

Now you can send USDC transactions without ETH:
```solidity
// Example: Transfer USDC to another address
wallet.execute(
    usdcAddress,
    0,
    abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
);
```

## 🧪 Testing

Run the complete test suite:
```bash
# Run all tests
forge test

# Run specific test files
forge test --match-path test/unit/EIP7702WalletTest.t.sol
forge test --match-path test/unit/USDCPaymasterTest.t.sol
forge test --match-path test/integration/EndToEndTest.t.sol

# Run tests with gas reporting
forge test --gas-report

# Run tests with detailed traces
forge test -vvv
```

### Test Coverage

- **Unit Tests**: Individual contract functionality
- **Integration Tests**: End-to-end system workflows
- **Gas Optimization**: Gas usage analysis and optimization

## 📖 Usage Examples

### Creating and Using a Smart Wallet

```solidity
// 1. Deploy wallet via factory
address wallet = factory.createWallet(owner, salt);

// 2. Fund wallet with USDC (no ETH needed)
usdc.transfer(wallet, 1000 * 1e6); // 1000 USDC

// 3. Approve paymaster for gas payments
EIP7702Wallet(wallet).execute(
    address(usdc),
    0,
    abi.encodeWithSignature("approve(address,uint256)", paymaster, type(uint256).max)
);

// 4. Execute USDC transfer (gas paid in USDC)
EIP7702Wallet(wallet).execute(
    address(usdc),
    0,
    abi.encodeWithSignature("transfer(address,uint256)", recipient, 500 * 1e6)
);
```

### Batch Operations

```solidity
address[] memory targets = new address[](2);
uint256[] memory values = new uint256[](2);
bytes[] memory datas = new bytes[](2);

// Transfer to recipient 1
targets[0] = address(usdc);
values[0] = 0;
datas[0] = abi.encodeWithSignature("transfer(address,uint256)", recipient1, 200 * 1e6);

// Transfer to recipient 2
targets[1] = address(usdc);
values[1] = 0;
datas[1] = abi.encodeWithSignature("transfer(address,uint256)", recipient2, 300 * 1e6);

wallet.executeBatch(targets, values, datas);
```

### Paymaster Configuration

```solidity
// Update exchange rate (owner only)
paymaster.setExchangeRate(2500 * 1e18); // 1 ETH = 2500 USDC

// Update fee markup (owner only)
paymaster.setFeeMarkup(1500); // 15% markup

// Calculate USDC needed for gas
uint256 gasCost = 0.01 ether; // Gas cost in ETH
uint256 usdcNeeded = paymaster.calculateUSDCAmount(gasCost);
```

## ⚙️ Configuration

### Environment Variables

Key environment variables in `.env`:

```bash
# Deployment
PRIVATE_KEY=your_private_key_here
ALCHEMY_API_KEY=your_alchemy_api_key_here

# Network addresses (set after deployment)
WALLET_FACTORY=0x...
USDC_TOKEN=0x...

# Paymaster settings
EXCHANGE_RATE=2000000000000000000000  # 2000 USDC per ETH
FEE_MARKUP=1000                       # 10% markup
```

### Gas Settings

The system is optimized for gas efficiency:
- Wallet operations: ~100,000-200,000 gas
- Paymaster validation: ~50,000 gas
- USDC transfers: ~65,000 gas

## 🔒 Security Considerations

1. **Private Key Management**: Never commit private keys to version control
2. **Paymaster Funding**: Ensure paymaster has sufficient ETH for gas sponsorship
3. **Exchange Rate Updates**: Monitor and update USDC/ETH rates regularly
4. **Access Control**: Only authorized addresses can update paymaster settings
5. **Emergency Recovery**: Built-in emergency withdrawal functions

## 🌐 Network Support

### Supported Networks

- **Mainnet**: Full production deployment
- **Sepolia**: Testnet with mock USDC
- **Local**: Development with mock contracts

### Contract Addresses

After deployment, contract addresses are saved to:
- `deployments/{network}.json`: Deployment information
- `wallets/wallet_{address}.json`: Individual wallet information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 References

- [EIP-7702: Set EOA account code](https://eips.ethereum.org/EIPS/eip-7702)
- [ERC-4337: Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
- [Account Abstraction Implementation](https://github.com/eth-infinitism/account-abstraction)
- [Foundry Documentation](https://book.getfoundry.sh/)

## 🆘 Support

For questions and support:
1. Check the test files for usage examples
2. Review the contract documentation
3. Open an issue on GitHub
4. Join the community discussions

## 🎯 Roadmap

- [ ] Multi-token paymaster support (USDT, DAI, etc.)
- [ ] Social recovery mechanisms
- [ ] Mobile SDK integration
- [ ] Gasless onboarding flows
- [ ] Cross-chain compatibility
- [ ] Advanced batching optimizations

---

**Note**: This is an experimental implementation of EIP-7702 and ERC-4337. Use with caution in production environments and conduct thorough audits before mainnet deployment.

## Setup & Deployment

See the step-by-step setup guide with all environment variables:

- docs/SETUP.md