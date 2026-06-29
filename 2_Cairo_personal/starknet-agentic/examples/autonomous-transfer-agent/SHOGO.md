# Shogo — your transfer agent

**Shogo** is this agent (`agentName: "shogo"` in `contacts.json`). You tell Shogo who to pay and how much; it checks balance, validates rules, sends STRK, logs a receipt, and alerts if balance is low.

---

## One-time setup (do this once)

### 1. `.env` (wallet — already done if you transferred before)

```bash
cd examples/autonomous-transfer-agent
cp .env.example .env
```

Set:

- `STARKNET_RPC_URL` — Sepolia RPC
- `STARKNET_ACCOUNT_ADDRESS` — your wallet
- `STARKNET_PRIVATE_KEY` — your key
- `STARKNET_SIGNER_MODE=direct`

### 2. `contacts.json` (who Shogo can pay)

```bash
cp contacts.example.json contacts.json
```

Edit `contacts.json` — add anyone you want:

```json
{
  "agentName": "shogo",
  "contacts": {
    "david": "0x05bab0ff83935ec8df4176e2aa2ffa5c1104600f8c7bd2752c41700499eb61c6",
    "alice": "0xYOUR_ALICE_ADDRESS_HERE"
  }
}
```

Use **lowercase names** (`david`, not `David`) in CLI; Cursor can use either.

### 3. `agent.config.json` (thresholds + default amount)

Edit the `strk-sepolia` profile:

| Field                      | Meaning                                | Example |
| -------------------------- | -------------------------------------- | ------- |
| `minBalanceForTransfer`    | Only send if balance **>** this (STRK) | `"100"` |
| `lowBalanceAlertThreshold` | Alert if balance **<** this            | `"500"` |
| `reserveBalance`           | Keep this much STRK after send         | `"10"`  |
| `transfer.enabled`         | Must be `true` to send                 | `true`  |
| `transfer.amount`          | Default amount if you omit `--amount`  | `"50"`  |

Example:

```json
"strk-sepolia": {
  "minBalanceForTransfer": "100",
  "lowBalanceAlertThreshold": "500",
  "reserveBalance": "10",
  "transfer": {
    "enabled": true,
    "recipient": "0x0",
    "amount": "50",
    "gasfree": false
  }
}
```

`recipient` is overwritten when you use `--contact david`.

---

## Send STRK to a contact (CLI)

**Dry-run first (recommended):**

```bash
pnpm run:shogo:dry -- --contact david --amount 50
```

**Live send:**

```bash
pnpm run:shogo -- --contact david --amount 50
```

Replace `david` with any name from `contacts.json`.

Check result: `receipts/execution-receipt.json`

---

## In Cursor (chat)

Say something like:

> **Shogo**, send **50** STRK to **david**.

The assistant should:

1. Read `contacts.json` → david’s address
2. Read `agent.config.json` → thresholds
3. Run the pipeline (balance → alert → validate → dry-run → transfer → receipt)

Or run CLI for you:

```bash
pnpm run:shogo -- --contact david --amount 50
```

---

## Threshold cheat sheet

| You want                                  | Set in `agent.config.json`        |
| ----------------------------------------- | --------------------------------- |
| “Only send if I have more than 1000 STRK” | `minBalanceForTransfer: "1000"`   |
| “Warn me if I drop below 200 STRK”        | `lowBalanceAlertThreshold: "200"` |
| “Always keep 5 STRK for gas”              | `reserveBalance: "5"`             |
| “Don’t send yet, only check”              | `transfer.enabled: false`         |

---

## Add a new contact

1. Open `contacts.json`
2. Add a line: `"name": "0x...address..."`
3. Run: `pnpm run:shogo -- --contact name --amount 10`

No code changes needed.
