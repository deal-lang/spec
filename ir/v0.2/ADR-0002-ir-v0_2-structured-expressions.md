# ADR-0002 — IR v0.1 → v0.2: structured behavioral expressions

- **Status:** Accepted (Stage-3 S3.0)
- **Date:** 2026-06-16
- **Context lineage:** ADR-0001 (IR v0→v0.1 behavioral), D-22…D-27 (IR v0
  contract), BH-1…BH-7 (behavioral surface), `spec/ir/v0.2/expression-mapping.md`,
  supersedes `spec/ir/v0.1/FUTURE-structured-expressions.md`

## Context and problem statement

IR v0.1 (ADR-0001) carries the behavioral *structure* — steps, control nodes,
successions, transitions, pins — as schema-valid SysML v2. But the
**expressions inside** behavior cross the toolchain as **opaque source text**:

- The **AST** already has fully structured expression nodes (`binary`, `unary`,
  `call`, `member_access`, `identifier`, the literals).
- **IR v0.1** flattens them to `?[]const u8` source slices —
  `IrPayload.guard_expr` / `value_expr` / `iterable_expr` and `Edge.guard` — via
  `spanTextOpt` in `lowering.zig` (nine call sites).
- The **emitter** therefore cannot emit real SysML v2 `Expression`s. Per the
  Stage-2 decision, guards are *not* emitted; only the structural surface is
  (see the deferral comment in `emit_transition`, `sysml_v2.rs`).

This leaves the behavioral mapping incomplete: a guard `[soc >= 80]` should emit
as an `OperatorExpression(">=")` over a `FeatureReferenceExpression(soc)` and a
`LiteralInteger(80)` — schema-valid and executable by tools.

## Decision drivers

- **Traceability:** each new IR expression element maps to exactly one
  KerML/SysML v2 metaclass (the one-node→one-metaclass rule from ADR-0001),
  grounded in a wiki closure.
- **Hub integrity:** the IR stays the single thing every emitter is a pure
  function of; expressions become part of the one uniform graph.
- **Faithful refinement, not recovery:** the AST subtree is present at every
  lowering site, so this is structurally lossless.
- **Backward compatibility:** existing v0/v0.1 *structural* output is unchanged;
  only the previously-text behavioral expression slots gain structure.
- **Bounded blast radius:** the change ripples to `ir.zig`, `json.zig`,
  `lowering.zig`, `sysml_v2.rs`, and goldens — a controlled, versioned
  migration.

## Considered options

1. **Additive v0.2 with first-class expression nodes (chosen)** — add four
   expression `NodeKind`s (`operator_expr`, `feature_ref_expr`, `literal_expr`,
   `invocation_expr`), owned via `contains` and referenced by id from the
   guard/value/iterable/effect/callee slots; bump `ir_version` to `v0.2`. The
   expression subtree is part of the single IR graph and reuses the existing
   emit/walk machinery.
2. **Inline nested expression payloads** — embed a recursive expression struct
   directly inside each owning payload. *Rejected:* breaks the flat node/edge
   model and the per-node emit dispatch; defeats `find`/`children`/`references`.
3. **Keep expressions as text** (status quo) — *rejected:* the emitter can never
   produce schema-valid `Expression` trees; the behavioral mapping stays
   permanently partial.

## Decision

Adopt **additive IR v0.2**. Concretely (full design in
`expression-mapping.md`):

- **New node kinds:** `operator_expr`, `feature_ref_expr`, `literal_expr`,
  `invocation_expr` (each → one KerML/SysML metaclass; see the mapping table).
- **Payload fields:** `operator` (KerML symbol), `literal_kind` +
  `literal_value`, `referent_segments`, `trigger_kind?`, with operands/arguments
  carried as ordered child expression nodes via `contains`.
- **Slot migration:** `guard_expr` / `value_expr` / `iterable_expr` change from
  source text to an **expr-node id**; `effect_ref` / `callee_ref` reference an
  `invocation_expr` id. `Edge.guard` keeps `"else"` as a sentinel; otherwise an
  expr-node id.
- **Versioning:** `$id` → `https://deal-lang.org/spec/ir/v0.2/schema.json`;
  `ir_version` → `"v0.2"`. v0.1 remains published; v0.2 supersedes it for the
  toolchain. The structural superset property holds: every v0.1 *structural*
  document remains valid; only behavioral expression slots are refined.
- **Identity unchanged:** D-23 still holds. Synthetic expression ids are
  deterministic from owner + structural path (`<owner>.guard.expr`, `…op0`,
  `…op1`, `…arg0`), reusing the `behav_synth` discipline.

The expression mapping itself — metaclasses, clauses, authored-vs-derived slots,
the operator→symbol table, and the 8.4 implied relationships — is locked in
`expression-mapping.md`, verified one-closure-per-turn against the KerML and
SysML v2 LLM wikis.

## Consequences

**Positive**
- Behavioral guards, assignment values, accept/send payloads, and loop bounds
  become emittable as schema-valid SysML v2 / KerML `Expression` trees —
  completing the 1:1 behavioral mapping (the trigger/guard/effect transition
  triad finishes).
- Traceability stays structural: the contract is encoded in the schema +
  emitter, proven by golden + OMG-schema tests.
- The exhaustive Zig `switch (node.kind)` / `switch (node.payload)` discipline
  *forces* every consumer (incl. `json.zig`) to handle the new kinds — the
  compiler enumerates the gaps.

**Negative / risk (mitigations)**
- The schema/`ir_version` bump churns IR-JSON output (new fields, new kinds) →
  additive only; no field removed or repurposed; **no committed IR-JSON
  byte-golden exists**, so the real gate is the SysML goldens regenerated under
  `--validate`. Determinism/idempotence preserved.
- Migration ripples to `ir.zig`, `json.zig`, `lowering.zig`, `sysml_v2.rs`, and
  goldens → land per sub-stage (S3.1–S3.4) with review at each, regenerating and
  reviewing all goldens (the Phase-1a cascade lesson).
- IR-JSON consumers (LSP, any tooling) must tolerate new kinds → additive;
  add new arms; nothing removed.
- **fmt round-trip is unaffected** — fmt walks the AST (already structured);
  only the IR gains structure. Existing idempotence tests stand.
- ReqIF emitter unaffected (D-59 exports only requirement/need nodes) — confirm
  with a regression run.

## Compliance / verification

When implementing the emitter arms (S3.3), run the full wiki closure per
metaclass (`kerml-wiki-navigator`; `sysml-v2-wiki-navigator --kerml` for
`TriggerInvocationExpression`), fill only the non-derived slots, inject the 8.4
implied relationships (operator→Function, operand ParameterMembership/FeatureValue,
result BindingConnector, library specialization, Boolean result typing), and
cite the clause. Golden fixtures (`11-action-behavior`, `12-state-machine`, plus
a guard-focused golden) validate against OMG SysML 20250201 **with guards
present**. See `expression-mapping.md` §8.
