# Planning seed — Structured expression emission (Stage 3 candidate)

> **RETIRED — superseded by IR v0.2 (Stage 3 complete).** This seed has been
> realized. The authoritative contract is [`../v0.2/expression-mapping.md`](../v0.2/expression-mapping.md)
> with the migration decision in [`../v0.2/ADR-0002-ir-v0_2-structured-expressions.md`](../v0.2/ADR-0002-ir-v0_2-structured-expressions.md).
> This file is kept only for historical context and may be removed.

**Status:** Retired (realized in IR v0.2). Seeded at the close of Stage 2.
**Context:** BH-1..BH-7 behavioral surface; `behavioral-mapping.md`; ADR-0001.

## Problem

DEAL behavioral guards, assignment values, and accept/send payloads are
**expressions** (`soc >= 80`, `temp > 60`, `soc + 10`). Today these cross the
toolchain as **opaque source text**:

- **AST** has full expression nodes (binary / unary / call / literal / member
  access / identifier) — structured.
- **IR v0.1** flattens them to text slices: `IrPayload.guard_expr`,
  `value_expr`, `iterable_expr` are `?[]const u8` (the source span), not
  structured IR (`ir.zig`, S2.5b `spanTextOpt`).
- **SysML emitter** therefore cannot emit real SysML v2 `Expression` trees. Per
  the Stage-2 decision (Option 3), guards are **not emitted**; the structural
  edges (succession source→target, transition trigger/effect memberships) and
  pin typing are emitted, but the guard/value semantics are dropped from the
  SysML output (still retained losslessly inside the IR text fields).

## Goal

Emit DEAL behavioral expressions as schema-valid SysML v2 `Expression` trees so
that:
- `decide`/`succession` guards become `guardExpression` (Boolean-valued).
- `transition` guards become the `kind=guard` `TransitionFeatureMembership`
  (Boolean-valued `Expression`), completing the trigger/guard/effect triad.
- `assign` values and `accept`/`send` payloads carry their computed expression.

## Scope (three coordinated layers)

1. **IR**: add expression node/payload kinds to `ir.zig` + `spec/ir/v0.x`
   schema — e.g. `operator_expr` (operator + operand refs),
   `feature_ref_expr`, `literal_expr` (typed: Boolean/Integer/Real/String).
   This is the additive bump (v0.1 → v0.2 or fold into v0.1 pre-freeze).
2. **Lowering** (`lowering.zig`): lower AST expression subtrees (the nodes
   currently captured as text via `spanTextOpt`) into the new IR expression
   nodes; attach them to guards/values/payloads.
3. **Emitter** (`cli/src/sysml_v2.rs`): emit IR expression nodes as SysML v2
   `OperatorExpression` / `FeatureReferenceExpression` / `LiteralBoolean` /
   `LiteralInteger` / `LiteralRational` etc. **One `sysml-v2-wiki-navigator`
   closure per expression metaclass**; cite the clause; fill non-derived slots;
   inject the 8.4 implied relationships (operator → function reference, operand
   ParameterMembership). Validate every behavioral golden against OMG SysML
   20250201.

## Wiki closures required (one per turn, per the retrieval contract)

`OperatorExpression`, `FeatureReferenceExpression`, `LiteralBoolean`,
`LiteralInteger`, `LiteralRational`, `LiteralString`, `Expression`,
`InvocationExpression` (for calls), plus the KerML `Expression`/`Function`
chain. Record each row via `deal_mappings` and rebuild `index/coverage.json`.

## Verification

- Re-generate `tests/golden/sysml-v2/11-action-behavior.expected.json` and
  `12-state-machine.expected.json` with `deal build --target sysml-v2
  --validate` (guards now present, schema-valid).
- Round-trip + determinism unaffected (idempotent fmt already covers the source
  text; IR gains structure, deterministic).

## Pointers

- Text fields to replace: `ir.zig` `guard_expr` / `value_expr` /
  `iterable_expr`; lowering `spanTextOpt` call sites (S2.5b).
- Emitter sites: `emit_transition` (guard membership), succession/decide guard
  on connectors, `emit_*` for assign/accept/send payloads.
- Mapping contract guard/value rows: `behavioral-mapping.md` §1.
