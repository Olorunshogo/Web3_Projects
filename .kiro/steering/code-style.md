# Code Style

## Comment Style

### Section separators

Use `// === Section Name` for top-level section dividers in any file.

```cairo
// === Helpers
// === Tests
// === Events
```

Do NOT use decorative ASCII box/line separators:

```cairo
// ─── Helpers ────────────────────────────────────────────────────────────────  ← NEVER use this
// --- Helpers ---  ← NEVER use this
```

### Inline and function comments

Regular `//` comments are fine anywhere inside functions or for inline explanations.

```cairo
// Deploy the contract
let contract = declare("Counter").unwrap_syscall().contract_class();
```

This applies to all languages in this repo: Cairo, TypeScript, JavaScript.

## Interaction Mode

Default to analysis mode. Do not modify any files unless the user explicitly instructs you to make changes. When in analysis mode, provide observations, explanations, and recommendations only. Switch to autopilot (modify files directly) only when the user explicitly says to make a change.
