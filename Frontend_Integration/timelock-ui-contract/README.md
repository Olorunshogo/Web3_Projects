# TimeLock Savings DApp

A decentralized application where users can lock their ETH for a specified time period and withdraw it only after the unlock time.

## Project Structure

```
├── backend/          # Solidity smart contracts (Foundry)
│   ├── src/         # Contract source files
│   ├── test/        # Contract tests
│   └── script/      # Deployment scripts
└── frontend/        # Next.js React frontend
```

## Backend Setup

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Test Contracts
```bash
cd backend
forge test
```

### Deploy to Local Network
```bash
# Start local node
anvil

# Deploy (in another terminal)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast --private-key <PRIVATE_KEY>
```

### Deploy to Testnet (Sepolia)
```bash
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY --verify
```

## Frontend Setup

### Prerequisites
- Node.js 18+
- MetaMask or any Web3 wallet

### Install & Run
```bash
cd frontend
npm install
npm run dev
```

### Configure

1. **Environment Variables**: Copy `.env.example` to `.env.local`
   ```bash
   cp .env.example .env.local
   ```

2. **WalletConnect Project ID**: Get a free project ID from [WalletConnect Cloud](https://cloud.walletconnect.com/)
   - Update `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` in `.env.local`

3. **Contract Address**: After deploying the contract, update `NEXT_PUBLIC_CONTRACT_ADDRESS` in `.env.local`

## How It Works

1. **Connect Wallet**: Users connect via RainbowKit (supports MetaMask, WalletConnect, Coinbase Wallet, etc.)
2. **Deposit**: Users deposit ETH and set a lock duration (in days)
3. **Wait**: The ETH is locked until the unlock time
4. **Withdraw**: After the unlock time, users can withdraw their ETH

## Smart Contract Features

- One active vault per address
- Secure withdrawal using `call` instead of deprecated `transfer`
- Events emitted for deposits and withdrawals
- View function to check vault status

## Tech Stack

### Backend
- **Smart Contracts**: Solidity 0.8.33
- **Testing**: Foundry
- **Framework**: Forge

### Frontend
- **Framework**: Next.js 16, React 19, TypeScript
- **Web3**: wagmi v2, viem v2
- **Wallet**: RainbowKit
- **State**: TanStack Query
- **Styling**: Tailwind CSS v4
