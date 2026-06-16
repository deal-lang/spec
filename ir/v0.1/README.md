# DEAL IR v0.1 Reference — Behavioral Surface

**Normative schema:** [`spec/ir/v0.1/schema.json`](./schema.json) (JSON Schema draft-2020-12)
**ADR:** [`ADR-0001-ir-v0_1-behavioral.md`](./ADR-0001-ir-v0_1-behavioral.md)
**Mapping contract:** [`behavioral-mapping.md`](./behavioral-mapping.md)
**Status:** Superseded by **[IR v0.2](../v0.2/README.md)** — an additive superset
that lifts behavioral guards/values/payloads from text to structured expression
nodes. Every valid v0.1 *structural* document remains valid; the toolchain now
emits `ir_version: "v0.2"`. This page remains the reference for the behavioral
surface that v0.2 extends. (v0.1 is itself an additive superset of
[IR v0](../v0/README.md).)

---

## Overview

IR v0.1 extends the v0 kernel data model with the **behavioral surface**
(BH-1..BH-7): actions, control flow, state machines, item flows, and bindings.
It is lowered from the parsed AST + the semantic analyzer's symbol table, exactly
like v0, and stays **comment-free** (D-25) with the same fully-qualified-path ID
strategy (D-23). It remains the single normalization hub: `deal build` emits
SysML v2 JSON and ReqIF as pure functions of the IR.

## What's added over v0

**16 node kinds** (each maps to exactly one SysML v2 metaclass — see the mapping
contract for clauses):

`action_usage`, `terminate_action`, `send_action`, `accept_action`,
`assign_action`, `perform_action`, `while_loop_action`, `for_loop_action`,
`decision_node`, `merge_node` (injected), `fork_node`, `join_node` (injected),
`control_node`, `state_usage`, `transition`, `pin`.

**4 edge kinds** (with optional payload):

| EdgeKind | payload | SysML relationship |
|---|---|---|
| `succession` | `guard?` | SuccessionAsUsage (8.3.13.6) |
| `item_flow` | `flow_type?` | FlowUsage (8.3.16.3) |
| `binding` | — | BindingConnectorAsUsage (KerML 8.3.4.5.2) |
| `subaction` | `kind` (entry/do/exit) | StateSubactionMembership (8.3.18.4) |

`action_def` / `state_def` already existed in v0 as shells; v0.1 gives them
behavioral bodies. The §4 control-flow desugaring (decide → DecisionNode +
implicit MergeNode; par → ForkNode + implicit JoinNode) is performed in lowering;
the injected merge/join carry `implicit: true`.

## Resolved limitation (now in v0.2)

In v0.1, guards, assignment values, and accept/send payloads were carried as
**source text** (`guard_expr`, `value_expr`, `iterable_expr`), so the SysML
emitter emitted the structural surface but not guard `Expression`s. **[IR v0.2](../v0.2/README.md)
lifts these to structured expression nodes** that emit as schema-valid SysML v2 /
KerML `Expression` trees — see [`../v0.2/expression-mapping.md`](../v0.2/expression-mapping.md).
The Stage-3 seed `FUTURE-structured-expressions.md` is retired.
