# Web3 Projects

A monorepo of Web3 learning projects and experiments spanning Solidity, Cairo/Starknet, and full-stack dApp development.

## Structure

```
Web3_Projects/
├── Solidity/               - Solidity smart contract projects
│   ├── 1-hardhat/          - Hardhat-based contracts (algebraic, todo, milestone, timelock, crowdfunding, auction, tokens, testing)
│   ├── 2-foundry/          - Foundry-based contracts (counter, timelock-vault)
│   ├── OZ-Upgradeables/    - OpenZeppelin upgradeable patterns (diamond, transparent proxy)
│   ├── Security/           - Security exercises and challenges
│   ├── Reentrancy/         - Reentrancy attack patterns and defenses
│   ├── BlockheaderCohort7Diamond/ - Diamond proxy pattern
│   └── Subgraphs/          - The Graph subgraph indexing
│
├── 2_Cairo/                - Cairo/Starknet bootcamp projects
│   ├── cairo-bootcamp-6/   - Bootcamp session 6 (cairo_program, cairo_runner, spending_token, starknet_contracts, starknet-agentic)
│   ├── Cairo_class/        - Class exercises
│   └── starknet-agentic/   - Starknet agentic framework copy
│
├── 2_Cairo_personal/       - Personal Cairo experiments mirroring bootcamp structure
│
├── Frontend_Integration/   - Full-stack dApp frontends
│   ├── full-dex/           - DEX interface
│   ├── Timelock/           - Timelock contract + Next.js frontend
│   └── timelock-ui-contract/ - Timelock UI variant
│
├── coding_entry/           - Next.js entry project
│
└── starknet-agentic/       - Starknet agentic framework (root copy)
```

## Tech Stack

| Layer | Tools |
|---|---|
| Solidity | Hardhat, Foundry, OpenZeppelin |
| Cairo | Scarb, Starknet Foundry (snforge), Cairo 1 |
| Frontend | Next.js, React, Tailwind CSS, wagmi, WalletConnect |
| Agents | starknet-agentic, MCP server, AVNU paymaster |
| Testing | Hardhat test, forge test, snforge |

## Getting Started

### Solidity - Hardhat

```bash
cd Solidity/1-hardhat/<project>
cp .env.example .env   # fill in your keys
npm install
npx hardhat compile
npx hardhat test
```

### Solidity - Foundry

```bash
cd Solidity/2-foundry/<project>
forge install
forge build
forge test
```

### Cairo / Starknet

```bash
cd 2_Cairo/cairo-bootcamp-6/<project>
scarb build
snforge test
```

### Frontend (Next.js)

```bash
cd Frontend_Integration/<project>/frontend
cp .env.example .env   # fill in your keys
pnpm install
pnpm dev
```

## Environment Variables

Each project has a `.env.example` file. Copy it to `.env` and fill in real values before running.

| Variable | Used in |
|---|---|
| `SEPOLIA_RPC_URL` | All Hardhat projects |
| `SEPOLIA_PRIVATE_KEY` | All Hardhat projects |
| `ETHERSCAN_API_KEY` | All Hardhat projects |
| `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` | Next.js frontends |
| `STARKNET_RPC_URL` | Starknet agentic examples |
| `STARKNET_ACCOUNT_ADDRESS` | Starknet agentic examples |
| `STARKNET_PRIVATE_KEY` | Starknet agentic examples |

> Never commit `.env` files with real keys.
