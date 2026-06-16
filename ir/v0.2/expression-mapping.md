# DEAL Behavioral Expressions → IR v0.2 → KerML / SysML v2 — Mapping Contract

**Status:** LOCKED (Stage-3 S3.0). This is the single source of truth for the
**expression half** of the DEAL → SysML v2 normalization — the guards,
assignment values, accept/send payloads, loop bounds, and perform/effect calls
that Stage-2 retained as opaque source text. Every downstream layer (IR v0.2
node kinds, `lowering.zig` `lowerExpr`, `sysml_v2.rs` emitter arms, golden
tests) targets the rows below.

It is the expression sibling of [`../v0.1/behavioral-mapping.md`](../v0.1/behavioral-mapping.md):
that contract maps the behavioral *structure* (steps, control nodes,
successions, transitions, pins); this one maps the *expressions inside* it.

Metaclass names, clause numbers, PDF pages, and authored-vs-derived slots were
verified one-closure-per-turn against the **KerML LLM wiki** (`kerml-wiki`) and,
for `TriggerInvocationExpression`, the **SysML v2 LLM wiki** (`sysml-v2-wiki`,
`--kerml`). Expressions are a **KerML** layer; SysML v2 inherits them — so all
but the trigger metaclass are KerML clauses (`8.3.4.7.x` / `8.3.4.8.x`).

Supersedes the deferral seeded at [`../v0.1/FUTURE-structured-expressions.md`](../v0.1/FUTURE-structured-expressions.md).

---

## 1. The mapping table (authoritative)

Each DEAL/AST expression node lowers to exactly one IR expression node, which
emits as exactly one KerML/SysML v2 `Expression` metaclass. The **Authored
slots** column lists *only* the non-derived slots we fill; the **Derived /
injected** column lists what the receiving tool computes or what the 8.4
semantic rules imply (we never author these — §5).

| DEAL / AST node | IR v0.2 expr kind | Metaclass · clause (PDF p.) | Authored (non-derived) slots | Derived / injected (never authored) |
|---|---|---|---|---|
| `binary` (all `BinaryOp`) | `operator_expr` | **OperatorExpression** · KerML 8.3.4.8.17 (p.244) | `operator` symbol (String); two operand argument Features (each an owned `in` Feature carrying a FeatureValue whose value is the operand expr) | `instantiatedType` (Function resolved from `operator`); `result`; `BindingConnector` to result; `specializesFromLibrary('Performances::evaluations')`; `argument` (derived) |
| `unary` (`neg`/`not`/`bang`) | `operator_expr` | **OperatorExpression** · KerML 8.3.4.8.17 (p.244) | `operator` symbol; one operand argument Feature | same as above |
| `identifier` (single name) | `feature_ref_expr` | **FeatureReferenceExpression** · KerML 8.3.4.8.5 (p.232) | the referent: an owned Membership whose memberElement is the referenced Feature | `referent` (derived = first non-parameter member); `BindingConnector` referent↔result; `result` |
| `member_access` (`a.b`, `a.b.c`) | `feature_ref_expr` (chain) | **FeatureChainExpression** · KerML 8.3.4.8.4 (p.230) | `operator = "."`; the single argument Expression (receiver) + the chained target Feature membership | `targetFeature` (derived); resolves to `ControlFunctions::'.'`; `result` |
| `int_literal` | `literal_expr` (`integer`) | **LiteralInteger** · KerML 8.3.4.8.12 (p.240) | `value` (Integer) | `result` typed `Integer` (`checkLiteralIntegerSpecialization`) |
| `real_literal` | `literal_expr` (`rational`) | **LiteralRational** · KerML 8.3.4.8.13 (p.241) | `value` (Real) | `result` typed `Rational` |
| `boolean_literal` | `literal_expr` (`boolean`) | **LiteralBoolean** · KerML 8.3.4.8.9 (p.238) | `value` (Boolean) | `result` typed `Boolean` |
| `string_literal` | `literal_expr` (`string`) | **LiteralString** · KerML 8.3.4.8.14 (p.241) | `value` (String) | `result` typed `String` |
| `call` (incl. unit ctors `kg(5)`, `percent(1)`) | `invocation_expr` | **InvocationExpression** · KerML 8.3.4.8.8 (p.236) | `instantiatedType` (invoked Behavior/Function ref = callee); argument Features (owned `in` Features redefining the callee's input parameters, each carrying a FeatureValue) | `argument` (derived); `BindingConnector` to result when `instantiatedType` is not a Function; specialization |
| guard *context* (any of the above used as a guard) | (result typing) | **BooleanExpression** · KerML 8.3.4.7.2 (p.221) | — (typing context only) | `predicate` (derived); `specializesFromLibrary('Performances::booleanEvaluations')` |
| `accept` trigger payload (`when`/`at`/`after`) | `invocation_expr` (trigger) | **TriggerInvocationExpression** · SysML 8.3.17.17 (p.359) | `kind` (TriggerKind ∈ {when, at, after}); the trigger argument Expression | invoked trigger Function (derived from `kind`) |

**Root supertype.** Every expression metaclass above ultimately specializes
**Expression** (KerML 8.3.4.7.3, p.221), whose `function`, `result`, and
`isModelLevelEvaluable` are *all* derived; the binding to
`Performances::evaluations` is injected, not authored. `template_literal` /
`interpolation` remain **out of scope** for v0.2 (rare in behavioral guards;
see §6).

---

## 2. Operator → KerML library-function mapping

An `OperatorExpression` carries the operator **symbol** as a String and
*references the corresponding Function* in the Kernel Function Library standard
packages. Per the OperatorExpression card (8.3.4.8.17): *"An operator symbol
that names a corresponding Function from one of the standard packages from the
Kernel Function Library."* The function link is therefore **derived** — the
receiving tool resolves the symbol; we author **only the symbol** (and the
operands). This is the same pattern `FeatureChainExpression` uses for `"."` →
`ControlFunctions::'.'`.

DEAL operator (`ast.zig` `BinaryOp` / `UnaryOp`) → KerML operator symbol:

| DEAL op | KerML symbol | DEAL op | KerML symbol |
|---|---|---|---|
| `add` | `"+"` | `eq` | `"=="` |
| `sub` | `"-"` | `neq` | `"!="` |
| `mul` | `"*"` | `lt` | `"<"` |
| `div` | `"/"` | `le` | `"<="` |
| `log_and` | `"and"` | `gt` | `">"` |
| `log_or` | `"or"` | `ge` | `">="` |
| unary `neg` | `"-"` | unary `not` / `bang` | `"not"` |

Comparison (`< <= > >=` `== !=`) and logical (`and` `or` `not`) operators
resolve to Predicate-typed Functions and so yield a **Boolean** result — which
is exactly what a guard requires (§6). Arithmetic operators resolve to the
numeric `ScalarFunctions` / type-specific (`IntegerFunctions`,
`RationalFunctions`, …) Functions. The emitter keeps only the small DEAL-op →
symbol table above; it does **not** author the `ScalarFunctions::…` /
`specializesFromLibrary` link — that is the 8.4 injected, derived relationship.

---

## 3. IR v0.2 expression node kinds (additive to v0.1)

Four new `NodeKind`s, in the established one-kind-per-metaclass style (no
generic discriminator). Each is a first-class IR node (§4).

| NodeKind | payload fields | → metaclass |
|---|---|---|
| `operator_expr` | `operator` (KerML symbol string); ordered operand children (via `contains` + operand order) | OperatorExpression / FeatureChainExpression |
| `feature_ref_expr` | `referent_segments` (`[]const u8` path segments — 1 segment ⇒ FeatureReferenceExpression, ≥2 ⇒ FeatureChainExpression, §6) | FeatureReferenceExpression / FeatureChainExpression |
| `literal_expr` | `literal_kind` ∈ {boolean, integer, rational, string}; `literal_value` (serialized) | Literal{Boolean,Integer,Rational,String} |
| `invocation_expr` | `callee_ref` (invoked behavior/function id); `trigger_kind?` ∈ {when, at, after}; ordered argument children | InvocationExpression / TriggerInvocationExpression |

### 3.1 Slot migration (text → structured ref)

The Stage-2 text slots become **expr-node id references** (the structured
subtree is owned by the behavior via `contains`):

| Owner slot (IR v0.1, text today) | IR v0.2 |
|---|---|
| `Edge.guard` (succession / decide) | expr-node id, **or** the `"else"` sentinel (unchanged for decision defaults) |
| `IrPayload.guard_expr` (accept / loop / transition) | expr-node id |
| `IrPayload.value_expr` (assign) | expr-node id |
| `IrPayload.iterable_expr` (for-loop) | expr-node id |
| `IrPayload.effect_ref` (transition effect) | `invocation_expr` id |
| `IrPayload.callee_ref` (perform / entry-do-exit) | `invocation_expr` id |

The source text is retained losslessly today (the AST subtree is available at
every site), so this is a faithful *refinement*, not data recovery.

---

## 4. Attachment model and identity

**First-class nodes.** Expression nodes are full IR nodes (like the behavioral
nodes), owned by their context via `contains` edges and referenced by id from
the owning slot. Operands and arguments are child expression nodes, in source
order. This keeps the IR a single uniform graph and reuses the existing
emit/walk/`find`/`children` machinery. *Alternative considered — inline nested
payloads — rejected:* it breaks the flat node/edge model and the per-node emit
dispatch (mirrors ADR-0001's rejection of `PayloadGeneric` overloading).

**Identity (D-23).** Synthetic expression ids derive deterministically from the
owner + a structural path, e.g. `<owner>.guard.expr`, `…expr.op0`, `…expr.op1`,
`…expr.arg0`. Deterministic in source order (reuse the `behav_synth` discipline
from lowering) so goldens are stable and the IR remains the BH-5 round-trip
anchor.

---

## 5. Injected (implied) relationships — 8.4 semantic rules

Lowering produces the authored backbone; the emitter materializes these implied
relationships per the closures. These are the steps a naïve generator skips:

1. **Operator → Function.** `OperatorExpression.instantiatedType` is resolved
   from the `operator` symbol against the Kernel Function Library standard
   packages — derived, never authored beyond the symbol (8.3.4.8.17).
2. **Operand parameter binding.** Each operand/argument is an owned Feature with
   `direction = in` that redefines an input parameter of the resolved Function
   and carries a FeatureValue whose value Expression is the operand
   (`validateInvocationExpressionOwnedFeatures`, `deriveInvocationExpressionArgument`,
   8.3.4.8.8).
3. **Result BindingConnector.** A `BindingConnector` between the expression's
   `result` and its referent/argument is required for
   FeatureReferenceExpression (`checkFeatureReferenceExpressionBindingConnector`,
   8.3.4.8.5) and for non-Function InvocationExpressions (8.3.4.8.8).
4. **Expression library specialization.** Every Expression must
   `specializesFromLibrary('Performances::evaluations')`; a BooleanExpression
   must `specializesFromLibrary('Performances::booleanEvaluations')` (8.3.4.7.3 /
   8.3.4.7.2). Derived.
5. **Literal result typing.** Each Literal's `result` is typed by its scalar
   type (`Integer`/`Rational`/`Boolean`/`String`) via the
   `checkLiteral*Specialization` constraints. Derived.
6. **Feature-chain function.** `FeatureChainExpression.operator = "."` resolves
   to `ControlFunctions::'.'`; `targetFeature` is derived (8.3.4.8.4).
7. **Trigger function.** `TriggerInvocationExpression` invokes the Triggers-package
   Function selected by `kind` (when/at/after) — derived from `kind` (SysML
   8.3.17.17).

---

## 6. Decision rules

- **FeatureReferenceExpression vs FeatureChainExpression.** A single identifier
  (`soc`) ⇒ `FeatureReferenceExpression` (8.3.4.8.5). A dotted path
  (`battery.soc`, `a.b.c`) ⇒ `FeatureChainExpression` (8.3.4.8.4), nested
  left-to-right, each `"."` chaining the previous result with the next target
  Feature. Lowering already holds the segments (`referent_segments`).
- **Guards must be Boolean-valued.** Comparison/logical OperatorExpressions
  already yield Boolean (their Functions are Predicates), satisfying the
  BooleanExpression requirement (8.3.4.7.2). A *bare* feature-ref guard
  (`[charging]`) is annotated/typed as a BooleanExpression per its closure;
  schema validation enforces the `guardExpression` Boolean typing.
- **Unit-typed values are calls, not literals.** `kg(5)`, `percent(1)` parse as
  `call` and lower to `invocation_expr` → InvocationExpression invoking the unit
  Function — no special case (8.3.4.8.8).
- **`"else"` stays a sentinel.** Decision-default branches keep `Edge.guard ==
  "else"`; only non-default guards carry an expr-node id.

---

## 7. Lowering sites (the nine replacement targets)

`lowerExpr(l, ast_node) → expr_node_id` is a recursive AST-expr → IR-expr
lowering. It replaces the following `spanTextOpt`/`guardOf` sites in
`lowering.zig` (S2.5b), emitting `contains` edges so each expr subtree is owned
by its behavior:

| Lowering site | v0.1 field | v0.2 |
|---|---|---|
| succession / decide guard (`guardOf`) | `Edge.guard` | expr-id or `"else"` |
| `accept_action` guard | `guard_expr` | expr-id |
| `assign_action` value | `value_expr` | expr-id |
| `loop_statement` guard | `guard_expr` | expr-id |
| `loop_statement` iterable | `iterable_expr` | expr-id |
| `transition` guard | `guard_expr` | expr-id |
| `transition` effect | `effect_ref` | `invocation_expr` id |
| `entry`/`do`/`exit` behavior | `callee_ref` | `invocation_expr` id |
| `perform_statement` call | `callee_ref` | `invocation_expr` id |

---

## 8. Verification protocol (binding on S3.1–S3.4)

- **One full closure per metaclass** (`kerml-wiki-navigator`; `sysml-v2-wiki-navigator
  --kerml` for the trigger) when writing each emitter arm; fill only the
  Authored slots from §1; inject the §5 implied relationships; **cite the
  clause** in the emit code.
- **OMG-schema validation** on every behavioral golden (`deal build … --validate`,
  OMG SysML 20250201) — guards/values/payloads now present and schema-valid.
- **Stable identity** — synthetic expression ids deterministic from owner +
  structural path (§4, D-23).
- **Coverage write-back** — record each expression row via `deal_mappings`
  frontmatter on the target wiki atom, then rebuild the graph so
  `index/coverage.json` stays live.

## 9. Out of scope (Stage-3)

`template_literal` / `interpolation` (string interpolation — rare in guards);
constraint/calc-body expression emission (those carry their own representations
today — a follow-on reuses this same `lowerExpr`/emit machinery, §7 of the
plan); `IndexExpression`, `SelectExpression`, `CollectExpression`,
`NullExpression`, `MetadataAccessExpression`, `ConstructorExpression` (no DEAL
behavioral surface yet).
