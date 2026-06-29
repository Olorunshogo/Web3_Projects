# Starknet Agentic - Detailed Overview

## What Starknet Agentic Is

`starknet-agentic` is a production-focused framework for building Starknet-native AI/agent systems.

At a high level, it bundles:
- secure Cairo account and identity contracts
- MCP/A2A runtime integrations for agent tools
- skills that package repeatable Starknet workflows
- end-to-end examples that prove realistic agent behavior
- security and deployment guidance for production operation

Repository path:
- `cairo-bootcamp-6/starknet-agentic/`

---

## Core Objective

The project helps developers run agents that can:
- hold and use Starknet wallets safely
- execute on-chain actions under explicit policy constraints
- expose capabilities through standardized tool interfaces (MCP/A2A)
- compose domain skills (wallet, DeFi, identity, audits, optimization)
- move from local demo to production signer boundaries

---

## System Architecture

The architecture is intentionally layered:

1. Agent Runtime Layer
- Host runtime such as Codex/Claude/custom app executes agent logic.

2. Tool Layer
- MCP server and A2A adapters expose Starknet actions (read balances, invoke contracts, swap, identity ops, etc.).

3. Signer Boundary
- Local development can use direct signing.
- Production mode is designed around proxy signer boundaries for custody hardening.

4. On-chain Enforcement Layer
- Account/session contracts enforce policy where it matters most: on-chain execution.

5. Identity and Reputation Layer
- ERC-8004-style registries support identity, reputation, and validation workflows for agent ecosystems.

---

## Major Building Blocks

### Contracts (`contracts/`)

Key contract modules include:
- `agent-account`: session keys, policy enforcement, ownership controls
- `session-account`: session-focused account primitives and spending policy support
- `erc8004-cairo`: Starknet adaptation for identity/reputation/validation registries
- `huginn-registry`: ecosystem registry primitives used in related demos

Why this matters:
- policy enforcement is not just prompt-level; it is encoded in account behavior on-chain
- agent identity and reputation become queryable and composable primitives

### Packages (`packages/`)

Important package surfaces:
- `create-starknet-agent`: project scaffolding
- `starknet-agentic-mcp-server`: tool API surface for agent execution
- `starknet-agentic-a2a`: A2A adapter
- `starknet-agentic-agent-passport`: identity/capability metadata helpers
- `starknet-agentic-onboarding-utils`: reusable onboarding/deployment helpers
- `x402-starknet`: payment signature and x402 helper utilities

### Skills (`skills/`)

Skills package targeted workflows, for example:
- Cairo development: `cairo-contract-authoring`, `cairo-testing`, `cairo-optimization`, `cairo-auditor`, `cairo-deploy`
- App/agent workflows: `starknet-js`, `starknet-wallet`, `starknet-defi`, `starknet-identity`
- Specialized domains: `snip-36`, `starknet-mini-pay`, `starknet-tongo`, `starknet-anonymous-wallet`, `controller-cli`

This makes agent capability installation modular instead of monolithic.

---

## Examples and Agent Patterns

The `examples/` folder demonstrates different agent archetypes:

- `hello-agent`
  - Minimal end-to-end: connect RPC, read state, submit transaction.
  - Best starting point for plumbing validation.

- `full-stack-swarm`
  - Multi-agent execution narrative on Sepolia.
  - Demonstrates session keys, proxy signer boundary, gasless execution, and ERC-8004 registration.

- `secure-defi-demo`
  - Security-first single-agent flow.
  - Shows deterministic policy rejection proof, evidence artifacts, and optional identity anchoring.

- `carry-agent`
  - Deterministic strategy monitor with explicit decision gates (`ENTER`/`HOLD`/`EXIT`/`PAUSE`) and safety rails.

- `controller-calls`
  - Non-custodial unsigned call flow executed by external signer/controller model.

- `crosschain-demo`
  - Cross-chain flow linking Starknet operations with external chain context.

These examples show that "agentic" here means operationally constrained autonomous execution, not just chat-driven transactions.

---

## Autonomous Workflow Overview

A practical autonomous Starknet agent flow in this stack looks like:

1. Preflight and context load
- gather balances, account/session status, policy constraints, and market/state inputs.

2. Decision step
- strategy logic evaluates whether an action is permitted and useful.
- outputs explicit action intent plus reason codes.

3. Policy gate
- checks happen before signing/execution (and in many paths are enforced again on-chain).
- unsafe operations should fail deterministically with rejection evidence.

4. Signing and submission
- local dev: direct signer.
- production: proxy signer boundary with stricter custody posture.

5. On-chain execution
- account/session contract validates constraints and executes allowed calls.

6. Artifact and audit trail
- demos commonly emit JSON/markdown artifacts with step status, tx hashes, and rejection/acceptance evidence.

This structure is what makes autonomous mode inspectable and safer to operate.

---

## Security Model Summary

Starknet Agentic emphasizes defense-in-depth:
- policy controls before execution
- on-chain account/session enforcement
- recommended proxy signer isolation for production
- deterministic test/evidence flows in examples
- dedicated security docs/runbooks for ownership and signer rotation

Operationally, direct private-key mode is for local development; proxy/KMS/HSM-style boundaries are the intended production direction.

---

## How to Think About "Agents" in This Repo

In this ecosystem, an "agent" usually combines:
- a runtime brain (LLM + orchestration)
- a constrained Starknet tool interface (MCP/A2A)
- capability packs (skills)
- an account policy envelope (session/account contracts)
- observable outputs (artifacts, tx proofs, rejections)

That combination is the project's core contribution: agents that are programmable, composable, and policy-aware by default.

---

## Suggested Learning Path

1. Read root project docs in `starknet-agentic/README.md`.
2. Run `examples/hello-agent` to confirm environment and tx path.
3. Explore `skills/README.md` and install only the skill(s) you need.
4. Run `secure-defi-demo` to understand policy rejection/evidence flow.
5. Move to `full-stack-swarm` for autonomous multi-step production-style architecture.

---

## Quick Reference Paths

- Root overview: `starknet-agentic/README.md`
- Skills catalog: `starknet-agentic/skills/README.md`
- Security guidance: `starknet-agentic/docs/security/`
- Examples: `starknet-agentic/examples/`
- Contracts: `starknet-agentic/contracts/`
- MCP server package: `starknet-agentic/packages/starknet-mcp-server/`

---

## Final Summary

`starknet-agentic` is a full-stack framework for building autonomous Starknet agents that can act on-chain with explicit policy controls, modular skills, and production-minded signer security. Its examples move from simple transaction plumbing to evidence-driven DeFi and multi-agent orchestration, giving developers a clear path from experimentation to hardened operations.
