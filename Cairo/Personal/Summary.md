# Maverick Workspace Summary (Agent-Focused)

This document is a high-context operational summary of the `Maverick` workspace for autonomous agents, bots, or AI copilots that need to act on or extend the system.

## 1) What Maverick Is

Maverick is a Solana-devnet multi-agent financial simulation platform with two product surfaces sharing one core backend domain:

- A **terminal app (TUI)** built with React + Ink for interactive control and autonomous execution.
- A **web app** built with Next.js (App Router) that exposes HTTP APIs and dashboard pages for interacting with the same core concepts.

At the center is a group of autonomous agents (wallet-backed), plus internal protocols:

- `MaverickBank` (vault, savings, loans, payouts)
- `MaverickAMM` (constant-product SOL/USDC pool)
- `KalshiService` (prediction market data)
- Governance/peer-funding queue (`governance.json`)
- Signals file for manual/override actions (`signals.json`)

The system executes **real Solana devnet transactions** for SOL and SPL USDC operations where implemented.

---

## 2) Repository Layout

Workspace root (`/home/olorunshogo/Projects/React/Maverick`) contains documentation and a project subfolder:

- Root docs: `architecture.md`, `Overall.md`, `Prompt.md`, etc.
- Main project folder: `maverick/`

Inside `maverick/`:

- `src/` → core runtime, protocols, agents, TUI, voice, utilities.
- `web/` → Next.js dashboard + API routes.
- `history.json`, `signals.json`, `governance.json`, `amm.json` → runtime state artifacts.

---

## 3) Runtime Modes

## 3.1 Terminal (Primary)

Entry script:

- `maverick/src/ui/main.tsx`

NPM scripts (`maverick/package.json`):

- `npm run maverick` / `npm run start` → launch TUI
- `npm run start:headless` → run autonomous cycle loop from `src/index.ts`
- `npm run invite` → invite/onboard agent
- `npm run command` → command utility
- `npm run history` → history utility

## 3.2 Web Dashboard

Web project:

- `maverick/web/`

NPM scripts (`maverick/web/package.json`):

- `npm run dev` → Next dev server
- `npm run build` / `npm run start`

The web layer calls into shared core modules in `../src/...` through `web/lib/services.ts`.

---

## 4) Core Domain Model

## 4.1 Agents

Base class:

- `src/agents/baseAgent.ts`
  - Abstract interface: `tick()` and `executeCycle()`
  - Holds `wallet`, `signer`, `connection`

Primary implementation:

- `src/agents/maverickAgent.ts`
  - Autonomous cycle decisions: trade, bet, borrow/payback, swap/LP, etc.
  - Reads and consumes manual commands from `signals.json`
  - Tracks local in-memory counters: `trades`, `bets`, `activePositions`
  - Uses:
    - `ReasoningEngine`
    - `MaverickBank`
    - `LiquidityRouter`
    - `KalshiService`
    - `TokenService`
    - `HistoryProvider`

Notable behavior:

1. Per cycle, it computes random sentiment (`BULLISH | BEARISH | NEUTRAL`).
2. If signal exists for its name, executes commanded action.
3. Otherwise randomly leans toward TRADE or BET.
4. If low SOL, asks bank for loan; if very low and loan unavailable, requests airdrop.
5. If debt exists and balance is healthy, repays bank loan.
6. Refreshes position prices using Kalshi market price endpoint.

## 4.2 Wallets and Keys

- `src/core/walletManager.ts`
  - Creates or reconstructs keypair from Base58 private key.
  - If new, persists to `.env` under passed env var name.
  - Reads SOL balance, can request airdrop.

Dynamic agent discovery pattern:

- Env vars ending with `_PRIVATE_KEY` are treated as agents.
- `VAULT_PRIVATE_KEY` is excluded from agent list.
- If no agent keys found, defaults are bootstrapped (e.g., Alpha/Beta/Gamma pattern).

## 4.3 Transaction Execution

- `src/core/transactionSigner.ts`
  - Sends transactions with fresh blockhash.
  - Handles confirmation retries and some expired-blockhash recovery logic.
  - Used for native SOL transfers and custom instruction txs.

## 4.4 Token Operations (USDC)

- `src/core/tokenService.ts`
  - Devnet/mainnet USDC mint selection (by genesis hash).
  - Associated token account helpers.
  - SPL token transfer and mint helpers.
  - Balance fetch for token accounts.

## 4.5 Bank Protocol

- `src/protocols/maverickBank.ts`

Main state:

- `participants: WalletManager[]`
- `vaultBalance` (book-kept, plus on-chain lookup function)
- `loans: Map<address, Loan>`
- `contributions: Map<address, number>`
- Rotating payout index

Key operations:

- `deposit(wallet, amount)`
- `requestLoan(wallet, amount)`
- `payback(wallet)`
- `withdraw(wallet, amount?)`
- `collectContributions()` periodic participant contribution
- `payout()` rotating reward

Constraints:

- One outstanding loan per address.
- Withdrawal denied if active debt.
- Loan/withdraw blocked if vault liquidity insufficient.

## 4.6 AMM Protocol

- `src/protocols/maverickAMM.ts`

Model:

- Constant product `x*y=k`
- Fee rate: `0.3%`
- LP share tracking
- On-disk state persistence in `amm.json`

Core methods:

- `depositLiquidity(wallet, solAmount, usdcAmount)`
- `getSwapQuote(input, amount)`
- `swap(wallet, input, amount)`
- `getPoolStats()`

## 4.7 Liquidity Router

- `src/core/liquidityRouter.ts`

Current behavior:

- Compares internal AMM quote vs simulated Jupiter price.
- If internal AMM is better, executes real AMM swap.
- Otherwise returns success as simulated external route.

Note: external aggregator integration is currently mocked/simulated in this file.

## 4.8 Kalshi Integration

- `src/core/kalshiService.ts`

Features:

- Fetches open markets/events from Kalshi API.
- In-memory + disk cache (`.kalshi-cache.json`), TTL-based.
- Category/subcategory indexing.
- Market price fetch by ticker.

Used by:

- Agent betting/position refresh.
- Web markets and portfolio APIs.

## 4.9 Governance / Peer Funding

- `src/core/communicationModule.ts`

Flow:

1. Low-balance agent creates funding request.
2. Request is appended to `governance.json` with `PENDING` status.
3. User/manual system resolves request (approve/reject).
4. Approval can trigger real SOL transfer and history record.

## 4.10 History/Audit

- `src/utils/historyProvider.ts`

Writes append-only entries to `history.json` with shape:

- `timestamp`
- `agentAddress`
- `action`
- `description`
- optional `signature`
- optional `reasoning`

Many downstream screens/APIs parse these descriptions for analytics/portfolio reconstruction.

---

## 5) Headless Global Autonomous Loop

Entry:

- `src/index.ts`

High-level cycle:

1. Connect Solana devnet.
2. Initialize history/signer/registry/comms/vault/amm/bank.
3. Clear `signals.json`.
4. Discover agents from env keys and instantiate `MaverickAgent`s.
5. Infinite loop:
   - welcome messages for new agents
   - each agent `tick()`
   - social liquidity checks (request funding when low)
   - periodic bank contributions and payout
   - print ecosystem stats dashboard
   - sleep ~15s

This loop is the closest thing to “autonomous economy mode”.

---

## 6) TUI Architecture and Navigation

Main files:

- `src/ui/main.tsx` bootstraps services and renders `App`
- `src/ui/App.tsx` router + key handling + voice hook
- `src/ui/context/ServicesContext.tsx`
- `src/ui/context/NavigationContext.tsx`

Screens include:

- home, wallet, send, swap, bank, bankAction
- markets, marketList, bet, portfolio
- agents, agentDetail, invite
- governance, governanceDetail
- history, settings, requestFunds

Input controls:

- `q` on home to quit
- `Ctrl+b` to go back
- `v` to activate voice

---

## 7) Voice Subsystem

Core files:

- `src/voice/voiceService.ts`
- `src/voice/voiceRecorder.ts`
- `src/ui/hooks/useVoice.ts`

Features:

- Uses Google Gemini (`@google/genai`) for transcription + intent parsing.
- Intent schema includes navigation, balance, send/swap guidance, trade_count, etc.
- Uses OS `say` command for TTS responses.

Operational caveats:

- Requires `GEMINI_API_KEY`.
- `say` command is macOS-specific behavior.
- Recording stack depends on local audio tooling.

---

## 8) Web Layer: Services Bootstrap and Lifecycle

File:

- `web/lib/services.ts`

What it does:

- Resolves project root robustly (`cwd` or parent)
- Loads `.env` from project root
- Instantiates singleton services:
  - connection, history, signer, registry
  - vault manager, AMM, bank
  - discovered agents
- Prefetches Kalshi cache
- Stores singleton promise on `globalThis.__maverickServicesPromise`

Implication:

- API routes share a common in-memory service graph during process lifetime.

---

## 9) Web API Surface

All under `web/app/api/*/route.ts`.

## 9.1 `/api/agents`

- `GET`: Returns discovered agents (`index`, `name`, `address`).

## 9.2 `/api/wallet`

- `GET`: Wallet/balance-oriented data for selected agent.
- `POST`: includes airdrop-oriented operation (per implementation).

## 9.3 `/api/send`

- `POST`: Transfer SOL or USDC from selected agent to recipient.
- Validates token/amount/recipient.
- Logs to history.

## 9.4 `/api/swap`

- `GET`: Returns AMM pool stats + quote.
- `POST`: Executes AMM swap for selected agent.

## 9.5 `/api/bank`

- `GET`: Vault balance, contribution, outstanding loan for selected agent.
- `POST`: `deposit | withdraw | loan | payback`.

## 9.6 `/api/markets`

- `GET`: Kalshi markets + category map (+ optional category filter).

## 9.7 `/api/bet`

- `POST`: Places betting action and records it (implementation-specific details).

## 9.8 `/api/portfolio`

- `GET`: Reconstructs positions from `history.json` `BET` entries.
- Enriches positions with live prices from Kalshi.

## 9.9 `/api/governance`

- `GET`: In-memory proposals list.
- `POST`:
  - `create` proposal
  - `approve` (executes transfer)
  - `reject`

Note: web governance proposals are memory-backed in route module state (not persisted to file), unlike core `communicationModule` file-backed queue.

## 9.10 `/api/signals`

- Supports writing/reading manual action signals for agents.

## 9.11 `/api/voice`

- Text-intent route for web voice-assistant style interactions (rule/regex-based parser).

## 9.12 `/api/history`

- Exposes stored history for UI consumption.

---

## 10) Data Artifacts and Their Roles

Main state files in project root (`maverick/`):

- `.env`
  - Agent private keys and vault private key.
- `history.json`
  - Append-only operational log.
- `governance.json`
  - Pending funding requests from communication module.
- `signals.json`
  - Manual override action queue consumed by agents.
- `amm.json`
  - AMM reserves/LP shares persistent state.
- `.kalshi-cache.json`
  - Cached market index from Kalshi.

Web folder may also contain its own copies/artifacts during dev (`web/history.json`, `web/.kalshi-cache.json`).

Agent implementers should always confirm which runtime `cwd` they are in before reading/writing state files.

---

## 11) Environment Variables

Common keys:

- `AGENT_PRIVATE_KEY`
- `BETA_PRIVATE_KEY`
- `GAMMA_PRIVATE_KEY`
- `VAULT_PRIVATE_KEY`
- `GEMINI_API_KEY`

Pattern rule:

- Any `*_PRIVATE_KEY` except `VAULT_PRIVATE_KEY` becomes a discovered agent.

---

## 12) Typical End-to-End Flows

## 12.1 Autonomous Cycle

- Agent sentiment => action => tx/signature => history record.
- Balance low => bank loan request or airdrop fallback.

## 12.2 Manual Override

- Operator/API writes signal in `signals.json` with `agentName`, `action`, optional `target`.
- Agent consumes and deletes that signal on next cycle.

## 12.3 Inter-Agent Lending

- Request created -> governance queue -> manual approval -> transfer.

## 12.4 Swap

- Quote from AMM -> optional routing decision -> SOL/USDC transfers -> AMM state + history updated.

## 12.5 Bet + Portfolio

- Bet action logged in history.
- Portfolio API parses history descriptions to reconstruct positions, then updates live prices.

---

## 13) Important Implementation Realities (For Autonomous Bots)

1. **Mixed persistence models**
- Some flows use file persistence (`governance.json`, `signals.json`, `history.json`).
- Some web endpoints use in-memory arrays (e.g., governance proposals route state).

2. **History description strings are semantic contracts**
- Portfolio parser relies on regex against `description` text format.
- Changing message wording can break downstream analytics.

3. **Vault accounting is partially book-kept + on-chain**
- `vaultBalance` in memory can diverge from actual chain state if external txs happen.
- There is an explicit on-chain vault balance getter; prefer it for truth checks.

4. **External routing is simulated**
- `LiquidityRouter` has mocked Jupiter outputs; not production-grade external execution.

5. **Voice stack portability**
- Some voice/TTS details assume local OS capabilities.

6. **Agent identity naming is env-key-derived**
- Name transformations can produce unexpected labels if env key conventions differ.

7. **No tests currently wired**
- `npm test` is placeholder in main project.
- Autonomous edits should include careful manual verification strategy.

---

## 14) How to Add a New Autonomous Bot/Agent Safely

Recommended procedure:

1. Add `<NAME>_PRIVATE_KEY` to `.env` (or let wallet bootstrap generate one).
2. Ensure new agent is discovered in `src/index.ts` / `web/lib/services.ts` flow.
3. Register with bank participant list.
4. Define strategy class extending `BaseAgent`.
5. Keep history action formats stable.
6. Validate low-balance behavior (loan, airdrop, fallback).
7. Validate interaction surfaces:
   - TUI screen visibility
   - Web APIs reflect new agent in `/api/agents`

---

## 15) Integration Points for Higher-Level Orchestrator Agents

A supervising autonomous orchestrator can:

- Use filesystem-level signaling (`signals.json`) for deterministic control of specific agents.
- Poll `history.json` and `/api/portfolio` for performance and risk decisions.
- Trigger governance actions via `/api/governance` and `/api/send`.
- Query bank health from `/api/bank`.
- Query AMM liquidity and slippage estimate from `/api/swap` GET.

A robust orchestrator should implement:

- Retry logic for Solana confirmations/timeouts.
- Guardrails around low liquidity and debt state.
- Consistency checks between in-memory and on-disk/on-chain state.

---

## 16) Quick File Index (Most Important)

Core runtime:

- `maverick/src/index.ts`
- `maverick/src/agents/maverickAgent.ts`
- `maverick/src/protocols/maverickBank.ts`
- `maverick/src/protocols/maverickAMM.ts`
- `maverick/src/core/transactionSigner.ts`
- `maverick/src/core/walletManager.ts`
- `maverick/src/core/tokenService.ts`
- `maverick/src/core/communicationModule.ts`
- `maverick/src/core/kalshiService.ts`
- `maverick/src/utils/historyProvider.ts`

TUI:

- `maverick/src/ui/main.tsx`
- `maverick/src/ui/App.tsx`
- `maverick/src/ui/context/ServicesContext.tsx`
- `maverick/src/ui/context/NavigationContext.tsx`

Web:

- `maverick/web/lib/services.ts`
- `maverick/web/app/api/agents/route.ts`
- `maverick/web/app/api/send/route.ts`
- `maverick/web/app/api/swap/route.ts`
- `maverick/web/app/api/bank/route.ts`
- `maverick/web/app/api/markets/route.ts`
- `maverick/web/app/api/portfolio/route.ts`
- `maverick/web/app/api/governance/route.ts`
- `maverick/web/app/api/voice/route.ts`

State files:

- `maverick/.env`
- `maverick/history.json`
- `maverick/governance.json`
- `maverick/signals.json`
- `maverick/amm.json`

---

## 17) Final Mental Model

Maverick is best understood as a multi-agent Solana sandbox where:

- Agent wallets are first-class identities.
- Protocols (bank/amm/markets) are local coordination primitives over real chain transfers.
- TUI and web are control/observability interfaces over the same service graph.
- History and signal files are lightweight but critical operational contracts.

If you are building an autonomous bot on top of this workspace, prioritize state discipline, explicit control loops, and strict compatibility with existing action/history schemas.
