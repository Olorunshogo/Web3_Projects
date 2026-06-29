# SpendingToken (`MosesToken` / `MTK`) - Comprehensive Technical README

## 1. Purpose

`SpendingToken` is an ERC-20 token on Starknet that adds **owner-managed spending controls** on top of standard OpenZeppelin Cairo token behavior.

It is designed for cases where a token issuer needs:
- normal ERC-20 operations (`transfer`, `approve`, `transfer_from`, etc.)
- emergency controls (`freeze` / `unfreeze`)
- delegated spender controls (blocklist + per-spender cap)
- a global per-transfer cap

Primary implementation file:
- `src/token.cairo`

---

## 2. Contract Composition

The contract is built with OpenZeppelin Cairo components:

- `ERC20Component`
- `OwnableComponent`

These are wired through `component!(...)`, then exposed with embedded ABIs:

- `ERC20MixinImpl`
- `OwnableMixinImpl`
- `SpendingTokenImpl` (`ISpendingToken` custom interface)

This gives you:
- standard ERC-20 + ownership behavior from audited component patterns
- custom policy logic in one place (ERC20 hooks)
- clean storage/event separation

---

## 3. Constructor Behavior

Constructor signature:

```cairo
fn constructor(ref self: ContractState, admin: ContractAddress, initial_supply: u256)
```

Initialization steps:
1. Sets ERC-20 metadata:
- name: `MosesToken`
- symbol: `MTK`
2. Sets owner to `admin`.
3. Sets default transfer limit:
- `max_limit = 10_000_u256`
4. Mints `initial_supply` to `admin`.

Operational implication:
- the `admin` address is both initial owner and initial token recipient.

---

## 4. Storage Layout

Custom storage in addition to OZ substorage:

- `max_limit: u256`
  - global maximum allowed transfer amount
- `frozen: bool`
  - global transfer switch
- `blocked_spenders: Map<ContractAddress, bool>`
  - delegated spender blocklist
- `spender_limits: Map<ContractAddress, u256>`
  - optional delegated spender-specific caps

Substorage fields:
- `erc20: ERC20Component::Storage`
- `ownable: OwnableComponent::Storage`

---

## 5. Policy Enforcement Model (ERC20 Hook)

All runtime transfer policy checks are centralized in:
- `ERC20HooksImpl::before_update(...)`

### 5.1 Execution lifecycle

For balance/supply-changing ERC20 flows:
1. ERC20 action starts (`transfer`, `transfer_from`, mint, burn)
2. `before_update(...)` runs
3. If an assertion fails, transaction reverts
4. State mutation occurs
5. `after_update(...)` runs

`after_update(...)` is currently empty.

### 5.2 Mint/Burn bypass

If `from == 0` or `recipient == 0`, hook returns immediately.

Meaning:
- policy checks are intended for transfer paths
- mint/burn are intentionally not constrained by freeze/limits in hook logic

### 5.3 Transfer-path checks

For normal transfers:
- `frozen` must be `false` (`TRANSFERS_FROZEN` on failure)
- `amount > 0` (`ZERO_AMOUNT` on failure)
- `amount <= max_limit` (`LIMIT_EXCEEDED` on failure)

### 5.4 Delegated-spender checks (`transfer_from`)

When `caller != from`:
- spender must not be blocked (`SPENDER_BLOCKED` on failure)
- if spender has a custom cap (`spender_limit > 0`), then:
  - `amount <= spender_limit`
  - else `SPENDER_LIMIT_EXCEEDED`

Important nuance:
- spender-specific policies apply to delegated spending, not self-initiated transfers.

---

## 6. Public/External API

Custom interface from `src/interfaces.cairo`:

### 6.1 Owner-only admin functions

- `set_transfer_limit(new_limit)`
  - requires `new_limit > 0`
  - emits `TransferLimitUpdated { old_limit, new_limit }`

- `set_spender_limit(spender, limit)`
  - requires `spender != 0`
  - requires `limit > 0`
  - emits `SpenderLimitSet { spender, limit }`

- `block_spender(spender)`
  - requires `spender != 0`
  - requires spender not already blocked
  - emits `SpenderBlocked { spender }`

- `unblock_spender(spender)`
  - requires `spender != 0`
  - requires spender currently blocked
  - emits `SpenderUnblocked { spender }`

- `freeze()`
  - requires not already frozen
  - emits `TokensFrozen {}`

- `unfreeze()`
  - requires currently frozen
  - emits `TokensUnfrozen {}`

- `burn(from, amount)`
  - requires `from != 0`
  - requires `amount > 0`
  - burns from `from`
  - emits `TokensBurned { from, amount }`

### 6.2 Read functions

- `get_transfer_limit() -> u256`
- `get_spender_limit(spender) -> u256`
- `is_blocked(spender) -> bool`
- `is_frozen() -> bool`

### 6.3 Inherited ERC-20 + Ownable surface

Because ABIs are embedded, standard component methods are externally available, including typical ERC-20 and ownership operations.

---

## 7. Event Catalog

Custom events in `src/events.cairo`:

- `TransferLimitUpdated { old_limit, new_limit }`
- `SpenderBlocked { spender }`
- `SpenderUnblocked { spender }`
- `SpenderLimitSet { spender, limit }`
- `TokensFrozen {}`
- `TokensUnfrozen {}`
- `TokensBurned { from, amount }`

Component events are also flattened into the contract event enum:
- `ERC20Event`
- `OwnableEvent`

---

## 8. Error/Failure Conditions

Error constants in `src/errors.cairo`:

- `LIMIT_EXCEEDED`
- `SPENDER_LIMIT_EXCEEDED`
- `SPENDER_BLOCKED`
- `TRANSFERS_FROZEN`
- `ZERO_AMOUNT`
- `ZERO_ADDRESS`
- `INVALID_LIMIT`
- `ALREADY_FROZEN`
- `NOT_FROZEN`
- `ALREADY_BLOCKED`
- `NOT_BLOCKED`

These are asserted at policy/admin boundaries and will revert the transaction on violation.

---

## 9. Behavioral Matrix

### 9.1 `transfer` by token holder

- Blocked when frozen
- Blocked when amount is zero
- Blocked when amount exceeds global cap
- Not affected by spender blocklist/spender-limit checks (self-call path)

### 9.2 `transfer_from` by approved spender

- Requires allowance (ERC-20 standard behavior)
- Plus all transfer checks above
- Plus blocked spender enforcement
- Plus optional per-spender cap enforcement

### 9.3 `mint` and `burn`

- Hook policy path is bypassed for zero-address mint/burn semantics
- Owner-gated `burn` still enforces explicit input validation

---

## 10. Security and Governance Considerations

1. Owner trust model
- owner can freeze transfers, set limits, block spenders, and burn balances.
- owner key management is critical.

2. Centralization tradeoff
- strong admin controls improve safety/operations but increase governance power concentration.

3. Delegated-spender targeting
- spender controls are intentionally focused on `transfer_from` abuse surfaces.

4. Emergency response
- `freeze` provides global stop capability for incident handling.

---

## 11. Testing Checklist

Use `tests/token_test.cairo` plus additional cases as needed.

Recommended minimum test matrix:

1. Constructor
- owner set correctly
- metadata and initial supply initialized
- default `max_limit` is `10_000`

2. Global limit
- transfer succeeds at `amount == max_limit`
- transfer fails at `amount > max_limit`

3. Freeze lifecycle
- freeze toggles state and emits event
- transfer fails when frozen
- unfreeze restores transfer path

4. Spender blocking
- blocked spender cannot `transfer_from`
- unblocked spender regains path (subject to allowance/limits)

5. Spender-specific limit
- delegated transfer passes at cap boundary
- delegated transfer fails above cap

6. Admin access control
- non-owner calls revert for all admin functions

7. Burn behavior
- owner burn succeeds with valid inputs
- zero address/zero amount burn reverts

---

## 12. Practical Summary

`SpendingToken` keeps standard ERC-20 behavior while introducing explicit policy controls through a centralized pre-transfer hook and owner-managed administration. It is suitable for controlled token environments that need both composability and operational risk controls.
