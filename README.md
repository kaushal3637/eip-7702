# EIP-7702 + ERC-4337 USDC Gas Payment System

[![Solidity](https://img.shields.io/badge/Solidity-0.8.28-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Enabled-yellow.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

A complete account abstraction system that enables gasless transactions using USDC instead of ETH, combining EIP-7702 account delegation with ERC-4337 UserOperations.

## 📋 Table of Contents

- [Overview](#-overview)
- [Shared Assumptions & Prerequisites](#-shared-assumptions--prerequisites)
- [System Architecture](#-system-architecture)
- [Contract Details](#-contract-details)
- [Wallet Creation](#-wallet-creation)
- [UserOperation Execution](#-useroperation-execution)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Setup & Deployment](#-setup--deployment)
- [Usage Examples](#-usage-examples)
- [Testing](#-testing)
- [Security](#-security)
- [API Reference](#-api-reference)
- [Contributing](#-contributing)
- [Roadmap](#-roadmap)
- [License](#-license)

## 🎯 Overview

This project implements a revolutionary account abstraction system that allows users to pay transaction fees in USDC instead of ETH. By combining **EIP-7702 account delegation** with **ERC-4337 UserOperations**, users can interact with DeFi protocols without holding ETH in their wallets.
                                                                                                                                                                                                                                                                                                      
### Key Features

- 🚀 **Gasless Transactions**: Pay gas fees in USDC, not ETH
- 🔐 **EIP-7702 Compatible**: Account delegation support for enhanced functionality
- ⚡ **ERC-4337 Account Abstraction**: Meta-transactions via UserOperations
- 🏭 **Deterministic Wallets**: CREATE2-based wallet deployment
- 💰 **Paymaster System**: Automated gas sponsorship with USDC conversion
- 🔄 **Batch Operations**: Execute multiple transactions atomically
- 🛡️ **Emergency Recovery**: Built-in security mechanisms
- 📊 **Gas Optimization**: Detailed gas usage analysis and optimization

### Use Cases

- **DeFi Users**: Interact with protocols without ETH holdings
- **dApps**: Enable gasless onboarding for new users
- **Wallets**: Provide seamless UX without gas complications
- **Exchanges**: Enable direct token transfers without gas concerns

---

## 🔧 Shared Assumptions & Prerequisites

### Blockchain Network Assumptions

| Component | Requirement | Status |
|-----------|-------------|--------|
| **EVM Compatibility** | Ethereum-compatible chains | ✅ Required |
| **EIP-7702 Support** | Account delegation functionality | ✅ Required |
| **Solidity Version** | ^0.8.28 | ✅ Implemented |
| **EntryPoint Version** | v0.8 (ERC-4337) | ✅ Integrated |

### External Dependencies

| Service | Purpose | Status |
|---------|---------|--------|
| **EntryPoint Contract** | UserOperation validation & execution | ✅ Required |
| **USDC Token** | Gas payment token | ✅ Integrated |
| **Bundler Service** | UserOperation bundling & submission | ✅ Compatible |
| **RPC Provider** | Blockchain connectivity | ✅ Required |

### Security Assumptions

- Owner maintains control of private keys
- Paymaster has sufficient ETH for gas sponsorship
- Exchange rates are monitored and updated regularly
- Emergency functions available for recovery

### Network Requirements

- **Gas Price Volatility**: System handles dynamic gas pricing
- **USDC Availability**: Sufficient liquidity for gas payments
- **Bundler Reliability**: External bundler services for UserOperation submission

---

## 🏗️ System Architecture

### Core System Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    User     │───▶│   Bundler   │───▶│ EntryPoint  │───▶│  Paymaster  │
│  (EOA/Smart)│    │ (Pimlico/   │    │  (v0.8)     │    │ (USDCPay-   │
│             │    │  Alchemy)   │    │             │    │   master)   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                           │
                                                           ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Smart Wallet│───▶│Target       │    │   USDC      │◀───│   Paymaster  │
│ (EIP7702-   │    │Contract     │    │             │    │ (Gas Fee     │
│  Compatible)│    │             │    │             │    │  Deduction)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Component Relationships

```
┌─────────────────┐
│  User Interface │
│  (dApp/Wallet)  │
└─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  UserOperation  │────▶│    Bundler      │
│   Creation      │     │   (External)    │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│   EntryPoint    │◀────│   Paymaster     │
│   Validation    │     │   (USDC)        │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│ Smart Wallet    │     │   Gas Pool      │
│ Execution       │     │   (ETH)         │
└─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│ Target Contract │
│   (DeFi/DEX)    │
└─────────────────┘
```

### Data Flow Architecture

```
UserOperation Flow:
1. User → Bundler: Signed UserOperation
2. Bundler → EntryPoint: Submit UserOperation
3. EntryPoint → Paymaster: Validate & Pre-fund
4. Paymaster → EntryPoint: Validation result
5. EntryPoint → Wallet: Execute transaction
6. Wallet → Target: Execute user logic
7. EntryPoint → Paymaster: Post-operation settlement
8. Paymaster → User: Deduct USDC gas fee
```

---

## 📄 Contract Details

### Core Contracts Implementation

| Contract | Lines | Status | Description |
|----------|-------|--------|-------------|
| **EIP7702Wallet** | 391 | ✅ Complete | Smart wallet with EIP-7702 delegation |
| **USDCPaymaster** | 224 | ✅ Complete | Gas sponsorship in USDC |
| **EIP7702WalletFactory** | 199 | ✅ Complete | Deterministic wallet deployment |
| **IEIP7702Wallet** | 149 | ✅ Complete | Wallet interface specification |
| **IUSDCPaymaster** | 72 | ✅ Complete | Paymaster interface specification |
| **UserOperationHelper** | 223 | ✅ Complete | Utility functions for UserOperations |

### EIP7702Wallet Contract

**Location**: `src/wallets/EIP7702Wallet.sol`

**Key Features:**
- EIP-7702 account delegation support
- ERC-4337 BaseAccount implementation
- Owner-based access control
- Batch transaction execution
- USDC gas payment integration
- Emergency recovery functions

**Core Functions:**
```solidity
function initialize(address owner) external
function execute(address target, uint256 value, bytes data) external
function executeBatch(address[] targets, uint256[] values, bytes[] data) external
function executeUSDCTransfer(address recipient, uint256 amount, uint256 gasFee) external
function estimateGasFee() external view returns (uint256)
```

### USDCPaymaster Contract

**Location**: `src/paymasters/USDCPaymaster.sol`

**Key Features:**
- USDC-based gas sponsorship
- Dynamic exchange rate management
- Fee markup configuration
- Stake management for EntryPoint
- Emergency withdrawal functions

**Core Functions:**
```solidity
function calculateUSDCAmount(uint256 gasCost) external view returns (uint256)
function setExchangeRate(uint256 newRate) external
function setFeeMarkup(uint256 newMarkup) external
function withdrawUSDC(uint256 amount) external
```

### EIP7702WalletFactory Contract

**Location**: `src/factories/EIP7702WalletFactory.sol`

**Key Features:**
- CREATE2-based deterministic deployment
- Factory pattern implementation
- Batch wallet creation
- Implementation upgradeability

**Core Functions:**
```solidity
function createWallet(address owner, uint256 salt) external returns (address)
function getWalletAddress(address owner, uint256 salt) external view returns (address)
function createWalletsBatch(address[] owners, uint256[] salts) external returns (address[])
```

---

## 🏠 Wallet Creation

### Deterministic Wallet Deployment

```
Wallet Creation Flow:
1. User/Factory → Factory Contract: Create wallet request
2. Factory → CREATE2: Deterministic deployment
3. Factory → Wallet: Initialize with owner
4. Factory → Registry: Track deployed wallet
5. Factory → User: Return wallet address
```

### Wallet Creation Process

```
┌─────────────────┐
│    Factory      │
│   Contract      │
└─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  CREATE2 Salt   │────▶│ Predict Address │
│   Generation    │     │                 │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│   Deploy Clone  │     │   Initialize    │
│   (EIP7702Wallet│     │   Wallet        │
│    Template)    │     │                 │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│  Register       │     │   Transfer      │
│   Wallet        │     │   Ownership     │
└─────────────────┘     └─────────────────┘
```

### Code Example

```solidity
// 1. Predict wallet address
address predictedWallet = factory.getWalletAddress(owner, salt);

// 2. Create wallet if needed
address wallet = factory.createWalletIfNeeded(owner, salt);

// 3. Initialize wallet configuration
EIP7702Wallet(wallet).initialize(owner);
```

---

## ⚡ UserOperation Execution

### 6-Step Execution Process

```
UserOperation Execution Flow:
1. Signature Creation → User signs UserOperation
2. Bundler Submission → Bundler submits to EntryPoint
3. Pre-Operation → Paymaster validates and pre-funds
4. Transaction Execution → Wallet executes user logic
5. Post-Operation → Paymaster settles gas costs
6. Event Emission → System emits completion events
```

### Detailed Execution Flow

```
┌─────────────────┐
│   User Signs    │
│ UserOperation   │
│   (EOA Key)     │
└─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│   Bundler       │────▶│   EntryPoint    │
│   Submits       │     │   Receives      │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│  Paymaster      │     │   Validation    │
│ Pre-funding     │     │   & Security    │
│  (USDC Check)   │     │   Checks        │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│   Wallet        │     │   Target        │
│  Execution     │────▶│   Contract      │
│   (User Logic)  │     │   (DeFi/DEX)    │
└─────────────────┘     └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│   Gas Fee       │     │   USDC          │
│  Settlement     │────▶│   Deduction     │
│   (ETH → USDC)  │     │                 │
└─────────────────┘     └─────────────────┘
```

### Gas Payment Flow

```
USDC Gas Payment Process:
1. Calculate gas cost in ETH
2. Convert ETH to USDC using exchange rate
3. Apply fee markup (configurable)
4. Check user USDC balance
5. Verify paymaster allowance
6. Execute USDC transfer from user to paymaster
7. Paymaster uses transferred USDC for gas
```

---

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Node.js and npm (optional)
- Funded EOA on testnet
- RPC endpoint access

### One-Command Setup

```bash
# Clone repository
git clone <repository-url>
cd EIP-7702

# Install dependencies
forge install

# Copy environment template
cp env.example .env

# Edit .env with your keys and addresses
# PRIVATE_KEY=your_private_key_without_0x_prefix
# ALCHEMY_API_KEY=your_alchemy_api_key
# SEPOLIA_ENTRYPOINT=0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108
# SEPOLIA_USDC=0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
```

### Deploy and Test

```bash
# Deploy to Sepolia
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify

# Create a wallet
forge script script/CreateWallet.s.sol --rpc-url sepolia --broadcast

# Make a gasless USDC transfer
forge script script/TransferUSDC.s.sol --rpc-url sepolia --broadcast
```

---

## 📦 Installation

### System Requirements

- **OS**: Linux, macOS, or Windows (WSL)
- **Solidity**: ^0.8.28
- **Foundry**: Latest stable version
- **Node.js**: v16+ (optional)

### Installation Steps

1. **Install Foundry**
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Clone Repository**
```bash
git clone <repository-url>
cd EIP-7702
```

3. **Install Dependencies**
```bash
forge install
```

4. **Build Contracts**
```bash
forge build
```

5. **Run Tests**
```bash
forge test
```

---

## ⚙️ Setup & Deployment

### Environment Configuration

Create a `.env` file with the following variables:

```bash
# Deployment Keys
PRIVATE_KEY=your_private_key_without_0x_prefix
ALCHEMY_API_KEY=your_alchemy_api_key

# Network Addresses
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}
SEPOLIA_ENTRYPOINT=0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108
SEPOLIA_USDC=0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8

# Optional: Pre-deployed contract addresses
WALLET_FACTORY=0x...
USDC_PAYMASTER=0x...
WALLET_ADDRESS=0x...
```

### Deployment Steps

#### 1. Deploy Core Contracts

```bash
# Deploy Wallet Factory and USDC Paymaster
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

#### 2. Create Smart Wallet

```bash
# Set environment variables
export WALLET_FACTORY=<deployed_factory_address>
export WALLET_OWNER=<your_address>
export WALLET_SALT=12345

# Create wallet
forge script script/CreateWallet.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

#### 3. Fund Wallet with USDC

```bash
# Transfer USDC to wallet (via your wallet UI)
# Or use faucet for test tokens
```

#### 4. Approve Paymaster

```bash
export PAYMASTER_ADDRESS=<paymaster_address>

forge script script/ApprovePaymaster.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

#### 5. Stake Paymaster

```bash
cast send $PAYMASTER_ADDRESS "addStake(uint32)" 86400 \
  --value 0.1ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Deposit ETH for gas sponsorship
cast send $SEPOLIA_ENTRYPOINT "depositTo(address)" $PAYMASTER_ADDRESS \
  --value 0.05ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## 💡 Usage Examples

### Basic USDC Transfer

```solidity
// Execute USDC transfer with gas paid in USDC
wallet.execute(
    usdcAddress,
    0,
    abi.encodeWithSignature(
        "transfer(address,uint256)",
        recipient,
        100 * 1e6  // 100 USDC
    )
);
```

### Batch Transactions

```solidity
address[] memory targets = new address[](2);
uint256[] memory values = new uint256[](2);
bytes[] memory datas = new bytes[](2);

// Transfer to recipient 1
targets[0] = usdcAddress;
values[0] = 0;
datas[0] = abi.encodeWithSignature(
    "transfer(address,uint256)",
    recipient1,
    50 * 1e6
);

// Transfer to recipient 2
targets[1] = usdcAddress;
values[1] = 0;
datas[1] = abi.encodeWithSignature(
    "transfer(address,uint256)",
    recipient2,
    30 * 1e6
);

// Execute batch
wallet.executeBatch(targets, values, datas);
```

### Paymaster Configuration

```solidity
// Update exchange rate (1 ETH = 2500 USDC)
paymaster.setExchangeRate(2500 * 1e18);

// Update fee markup (15% markup)
paymaster.setFeeMarkup(1500);

// Calculate gas cost for transaction
uint256 gasCost = 0.01 ether;
uint256 usdcNeeded = paymaster.calculateUSDCAmount(gasCost);
```

### Emergency Operations

```solidity
// Emergency withdrawal of stuck tokens
wallet.emergencyWithdraw(tokenAddress, amount);

// Emergency ETH withdrawal from paymaster
paymaster.emergencyWithdrawETH();
```

---

## 🧪 Testing

### Test Structure

```
test/
├── unit/                    # Unit tests for individual contracts
│   ├── EIP7702WalletTest.t.sol
│   ├── USDCPaymasterTest.t.sol
│   └── EIP7702WalletFactoryTest.t.sol
├── integration/            # Integration tests
│   └── EndToEndTest.t.sol
└── utils/                  # Test utilities
    └── TestBase.t.sol
```

### Running Tests

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/unit/EIP7702WalletTest.t.sol

# Run with gas reporting
forge test --gas-report

# Run with detailed traces
forge test -vvv

# Run integration tests only
forge test --match-path test/integration/
```

### Test Coverage

- **Unit Tests**: Individual contract functionality
- **Integration Tests**: End-to-end system workflows
- **Gas Tests**: Gas usage analysis and optimization
- **Security Tests**: Access control and edge cases

### Coverage Report

```bash
# Generate coverage report
forge coverage

# Generate HTML coverage report
forge coverage --report lcov
```

---

## 🔒 Security

### Security Considerations

1. **Private Key Management**
   - Never commit private keys to version control
   - Use hardware wallets for production deployments
   - Implement proper key rotation policies

2. **Paymaster Security**
   - Ensure sufficient ETH balance for gas sponsorship
   - Monitor exchange rate updates regularly
   - Implement rate limiting for large transactions

3. **Access Control**
   - Owner-only functions for critical operations
   - Multi-signature requirements for high-value operations
   - Time-locked operations for sensitive changes

4. **Emergency Mechanisms**
   - Emergency withdrawal functions for stuck funds
   - Circuit breaker patterns for system protection
   - Admin controls for system maintenance

### Audit Status

- ✅ **Unit Tests**: 100% coverage of critical paths
- ✅ **Integration Tests**: End-to-end workflow validation
- ✅ **Security Reviews**: Basic security checks implemented
- ⚠️ **Formal Audit**: Recommended for production deployment

### Best Practices

- **Rate Limiting**: Implement transaction rate limits
- **Monitoring**: Set up comprehensive system monitoring
- **Backup Systems**: Maintain backup paymaster instances
- **Upgrade Mechanisms**: Implement upgradeable contracts safely

---

## 📚 API Reference

### EIP7702Wallet Interface

```solidity
interface IEIP7702Wallet is IAccount {
    // Core functions
    function initialize(address owner) external;
    function execute(address target, uint256 value, bytes calldata data) external;
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external;
    function executeUSDCTransfer(address recipient, uint256 amount, uint256 gasFee) external;

    // View functions
    function owner() external view returns (address);
    function entryPoint() external view returns (IEntryPoint);
    function supportsDelegation() external pure returns (bool);
    function estimateGasFee() external view returns (uint256);
    function getUSDCConfig() external view returns (address usdcToken, address gasSponsor, uint256 exchangeRate);

    // Owner functions
    function transferOwnership(address newOwner) external;
    function updateExchangeRate(uint256 newRate) external;
    function updateGasSponsor(address newSponsor) external;
}
```

### USDCPaymaster Interface

```solidity
interface IUSDCPaymaster is IPaymaster {
    // Core functions
    function calculateUSDCAmount(uint256 gasCost) external view returns (uint256);
    function setExchangeRate(uint256 newRate) external;
    function withdrawUSDC(uint256 amount) external;

    // View functions
    function usdcToken() external view returns (address);
    function exchangeRate() external view returns (uint256);

    // Owner functions
    function setFeeMarkup(uint256 newMarkup) external;
    function setMinimumUSDCBalance(uint256 newBalance) external;
}
```

### Events

```solidity
// Wallet Events
event WalletInitialized(address indexed owner, address indexed entryPoint);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event TransactionExecuted(address indexed target, uint256 value, bytes data, bool success);
event USDCTransferExecuted(address indexed recipient, uint256 amount, uint256 gasFeeAmount);
event ExchangeRateUpdated(uint256 newRate);
event GasSponsorUpdated(address indexed newSponsor);

// Paymaster Events
event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);
event FeeMarkupUpdated(uint256 oldMarkup, uint256 newMarkup);
event MinimumBalanceUpdated(uint256 oldBalance, uint256 newBalance);
event USDCGasPayment(address indexed user, uint256 usdcAmount, uint256 gasPrice, uint256 gasUsed);
event USDCWithdrawn(address indexed owner, uint256 amount);

// Factory Events
event WalletCreated(address indexed wallet, address indexed owner, uint256 salt);
event ImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);
```

---

## 🤝 Contributing

### Development Setup

1. **Fork the repository**
2. **Create a feature branch**
```bash
git checkout -b feature/your-feature-name
```

3. **Make your changes**
4. **Add tests for new functionality**
5. **Run the test suite**
```bash
forge test
```

6. **Update documentation if needed**
7. **Commit your changes**
```bash
git commit -m "Add: your feature description"
```

8. **Push to your branch**
```bash
git push origin feature/your-feature-name
```

9. **Create a Pull Request**

### Code Standards

- Follow Solidity style guide
- Add comprehensive tests
- Update documentation
- Use descriptive commit messages
- Follow existing code patterns

### Testing Requirements

- Unit tests for new functions
- Integration tests for new features
- Gas usage optimization
- Security considerations

---

## 🗺️ Roadmap

### Phase 1: Core Implementation ✅
- [x] EIP-7702 Smart Wallet implementation
- [x] ERC-4337 UserOperation support
- [x] USDC Paymaster system
- [x] Factory contract for wallet deployment
- [x] Basic testing suite
- [x] Documentation

### Phase 2: Enhanced Features 🚧
- [ ] Multi-token paymaster support (USDT, DAI)
- [ ] Social recovery mechanisms
- [ ] Mobile SDK integration
- [ ] Gasless onboarding flows
- [ ] Advanced batching optimizations
- [ ] Cross-chain compatibility

### Phase 3: Production Readiness 📋
- [ ] Formal security audit
- [ ] Mainnet deployment
- [ ] Performance optimization
- [ ] Monitoring and alerting
- [ ] Backup systems
- [ ] Emergency procedures

### Phase 4: Ecosystem Integration 🌐
- [ ] Integration with popular wallets
- [ ] dApp partnerships
- [ ] DeFi protocol integrations
- [ ] Cross-chain bridge support
- [ ] Governance mechanisms

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This is an experimental implementation of EIP-7702 and ERC-4337. Use with caution in production environments and conduct thorough audits before mainnet deployment.

## 📞 Support

For questions and support:
1. Check the test files for usage examples
2. Review the contract documentation
3. Open an issue on GitHub
4. Join the community discussions

## 🔗 References

- [EIP-7702: Set EOA account code](https://eips.ethereum.org/EIPS/eip-7702)
- [ERC-4337: Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
- [Account Abstraction Implementation](https://github.com/eth-infinitism/account-abstraction)
- [Foundry Documentation](https://book.getfoundry.sh/)

---

**Built with ❤️ for the Ethereum ecosystem**