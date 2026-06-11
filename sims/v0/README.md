# DEAL Simulation Protocol v0 Reference

**Normative schemas:** [`input.schema.json`](./input.schema.json), [`output.schema.json`](./output.schema.json), [`metadata.schema.json`](./metadata.schema.json)
**Status:** NORMATIVE (Phase 5 / D-70)

---

## Overview

The DEAL Simulation Protocol v0 defines the language-neutral JSON data contract that connects DEAL models to simulation tools. Every simulation target — Python (`deal-sim`), MATLAB, Zig-internal, or generic subprocess — must conform to this contract. It mirrors `spec/ir/v0/` in role and structure: the IR is the kernel for static model artifacts; the sims protocol is the kernel for runtime simulation artifacts.

**Pipeline:**

```
DEAL model → input.json → Simulation tool → output.json + metadata.json → DEAL model
```

---

## Artifact Layout

Each simulation run produces three files under `.deal/sims/<name>/` (gitignored per PS-10):

| File | Schema | Description |
|------|--------|-------------|
| `input.json` | `input.schema.json` | Resolved model parameter values sent to the sim |
| `output.json` | `output.schema.json` | Computed results returned from the sim |
| `metadata.json` | `metadata.schema.json` | Provenance: tool version, duration, reproducibility tier, staleness key |

Durable evidence baselines are written to `evidence/baselines/<tag>/` (tracked in git) by `deal evidence baseline <tag>`.

---

## Exit-Code Table

| Code | Meaning |
|------|---------|
| `0` | Simulation completed successfully; `output.json` is valid |
| `1` | Simulation failed (computation error); `output.json` may be absent or partial |
| `2` | Input validation failed; `output.json` will not be written |
| `3` | Tool not found or unlicensed; `skip.json` written instead (D-72 graceful-skip) |

---

## Key Invariants

### D-18: Alphabetical Key Order

All JSON output files MUST have alphabetically sorted keys at every level. This ensures byte-stable evidence artifacts for content-hash staleness detection (D-83). Use `sort_keys=True` in Python `json.dump`; use `BTreeMap` (not `HashMap`) in Rust serialization.

### D-70: Language-Neutral Contract

The contract is defined entirely in JSON Schema draft-2020-12. Any simulation tool can conform by reading `input.json` and writing `output.json` + `metadata.json` with the required fields. The DEAL compiler never executes simulation code directly.

### D-75: Reproducibility Tiers

The `metadata.json` `reproducibility_tier` field records the declared `@reproducibility` tier:

| Tier | Meaning |
|------|---------|
| `strict` | Bit-identical results across runs (Zig `@setFloatMode(.strict)`) |
| `tolerant` | Results within declared tolerance bounds |
| `advisory` | No reproducibility guarantee (external tool, MATLAB, etc.) |

### D-83: Staleness Key

The `metadata.json` `staleness_key` is a SHA-256 hex digest of:
1. The resolved input values (D-18 sorted JSON bytes)
2. The simulation source file bytes
3. The `[simulations.<name>]` TOML section bytes

This key is deterministic, reproducible, and defense-auditable. `deal check --verify` compares the stored key against a freshly computed one to detect stale evidence (D-84).

---

## Schema Conventions

Following `spec/ir/v0/schema.json` conventions:

- **JSON Schema version:** draft-2020-12
- **`$id`:** `https://deal-lang.org/spec/sims/v0/<name>.schema.json`
- **Key order:** Alphabetical at every level (D-18)
- **`deal_sim_protocol`:** `const: "v0"` — protocol version tag
- **`v`:** `const: 1` — document format version
- **`additionalProperties: false`** on all object schemas

---

## Three-Level Verification (SIM-5)

`deal check --verify` evaluates three levels:

1. **Level 1 — Structural completeness:** All `satisfy` blocks have evidence bound to a registered sim; all required `return {}` fields are mapped.
2. **Level 2 — Criteria evaluation:** Boolean expressions in `criteria {}` blocks evaluate against evidence map values. Verdicts: `PASS`, `FAIL`, `PARTIAL`.
3. **Level 3 — Evidence freshness:** Staleness key comparison. `STALE` is an orthogonal flag layered on top of the Level 2 verdict (D-84, D-86).

---

## See Also

- `spec/ir/v0/README.md` — normative IR v0 reference (structural model)
- `.planning/phases/05-simulation-integration/05-CONTEXT.md` — D-70 through D-88
- `cli/src/simulate.rs` — Rust orchestrator (Phase 5 Plan 02)
- `deal-sim/README.md` — Python SDK reference
