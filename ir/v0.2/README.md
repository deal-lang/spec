# DEAL IR v0.2 Reference — Structured Behavioral Expressions

**Normative schema:** [`spec/ir/v0.2/schema.json`](./schema.json) (JSON Schema draft-2020-12)
**ADR:** [`ADR-0002-ir-v0_2-structured-expressions.md`](./ADR-0002-ir-v0_2-structured-expressions.md)
**Mapping contract:** [`expression-mapping.md`](./expression-mapping.md)
(expression sibling of [`../v0.1/behavioral-mapping.md`](../v0.1/behavioral-mapping.md))
**Status:** Active. Additive superset of [IR v0.1](../v0.1/README.md) — every
valid v0.1 *structural* document remains valid. The toolchain emits
`ir_version: "v0.2"`.

---

## Overview

IR v0.2 lifts the **expressions inside behavior** — guards, assignment values,
accept payloads, loop bounds, and perform/effect calls — from opaque source text
to **structured expression nodes**. Through v0.1 these crossed the toolchain as
`?[]const u8` source slices (`guard_expr`, `value_expr`, `iterable_expr`,
`Edge.guard`), so the SysML emitter could emit the behavioral *structure* but not
the guard/value `Expression`s. v0.2 closes that gap: a guard `[soc >= 80]` now
lowers to an `operator_expr` (`>=`) over a `feature_ref_expr` (`soc`) and a
`literal_expr` (`80`), and emits as a schema-valid SysML v2 / KerML
`OperatorExpression` tree.

It is lowered from the same AST as v0.1 (the AST already carried full expression
nodes), stays **comment-free** (D-25), and keeps the fully-qualified-path ID
strategy (D-23). It remains the single normalization hub.

## What's added over v0.1

**4 expression node kinds** (each maps to exactly one KerML/SysML v2 Expression
metaclass — see the mapping contract for clauses):

| NodeKind | payload | → metaclass |
|---|---|---|
| `operator_expr` | `operator` (KerML symbol); operand children via `contains` | OperatorExpression (8.3.4.8.17) / FeatureChainExpression (8.3.4.8.4) |
| `feature_ref_expr` | `referent_segments[]` | FeatureReferenceExpression (8.3.4.8.5) / FeatureChainExpression (8.3.4.8.4) |
| `literal_expr` | `literal_kind` + `literal_value` | Literal{Boolean,Integer,Rational,String} (8.3.4.8.9/.12/.13/.14) |
| `invocation_expr` | `callee_ref`; `trigger_kind?`; arg children | InvocationExpression (8.3.4.8.8) / TriggerInvocationExpression (SysML 8.3.17.17) |

Expression nodes are **first-class IR nodes** owned by their context via
`contains` edges; operands/arguments are child expression nodes, ordered by
their synthetic ids (`…op0`/`op1`/`argN`). No new edge kinds are introduced.

**Slot migration (text → expr-node id).** The behavioral slots that carried
source text in v0.1 now carry the id of a lowered expression node:

| Owner slot (v0.1: text) | v0.2 |
|---|---|
| `Edge.guard` (succession / decide) | expr-node id, or `"else"` sentinel (kept) |
| `IrPayload.guard_expr` (accept / loop / transition) | expr-node id |
| `IrPayload.value_expr` (assign) | expr-node id |
| `IrPayload.iterable_expr` (for-loop) | expr-node id |
| `IrPayload.effect_ref` (transition effect) | `invocation_expr` id |
| `IrPayload.callee_ref` (perform / entry-do-exit) | `invocation_expr` id |

The source text was retained losslessly in v0.1, so this is a faithful
*refinement*, not data recovery — the AST subtree is present at every site.

## Emission (SysML v2)

The emitter wires the structured expressions onto their owners:

- **decision / succession guards** — the guard `Expression` is owned by the
  source/decision node (SuccessionAsUsage has no guard slot; KerML 8.3.13.6).
- **transition guards** — a `kind=guard` TransitionFeatureMembership owning the
  Boolean-valued `Expression`, completing the trigger/guard/effect triad
  (8.3.18.8; `guardExpression` derived per 8.3.18.9).
- **assignment values / loop bounds / accept guards** — owned via the existing
  containment (`valueExpression` etc. are derived slots the tool computes).

Only non-derived slots are authored; the library-function reference (operator →
`ScalarFunctions::…`), result parameter, and result `BindingConnector`s are
derived/injected per the 8.4 semantic rules — never authored.

## Unaffected

- **`deal fmt`** walks the AST (already structured) — round-trip and idempotence
  are unchanged; only the IR gains structure.
- **Determinism / id-uniqueness** — synthetic expression ids derive
  deterministically from owner + structural path (reusing the `behav_synth`
  discipline); `determinism.lower_twice` covers it.
- **ReqIF emitter** — exports only requirement/need nodes (D-59), unaffected.

## Out of scope (v0.2)

`template_literal` / `interpolation` (string interpolation); constraint/calc-body
expression emission (a follow-on reuses the same `lowerExpr`/emit machinery);
`IndexExpression`/`SelectExpression`/`CollectExpression`/`NullExpression`/
`MetadataAccessExpression`/`ConstructorExpression` (no DEAL behavioral surface
yet). See [`expression-mapping.md`](./expression-mapping.md) §9.
