# Changelog — spec (language specification)

Notable changes to the DEAL language specification: grammar, design decisions,
IR contract, and the showcase corpus. Format loosely based on
[Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added — Structured behavioral expressions (Stage 3, IR v0.2)

- **IR v0.2** (`ir/v0.2/`) — additive superset of v0.1 that lifts behavioral
  guards, assignment values, accept payloads, and loop bounds from opaque source
  text to structured expression nodes:
  - `schema.json` — 4 expression node kinds (`operator_expr`, `feature_ref_expr`,
    `literal_expr`, `invocation_expr`) and a `PayloadExpression` variant; the
    guard/value/iterable/effect/callee slots now carry an expr-node id;
    `Edge.guard` keeps `"else"` as a sentinel; accepts `ir_version` `"v0"`,
    `"v0.1"`, `"v0.2"`.
  - `expression-mapping.md` — the locked DEAL → IR → KerML/SysML v2 expression
    mapping contract (metaclasses + clauses verified against the KerML and
    SysML v2 LLM wikis; operator → KerML symbol table; 8.4 implied relationships).
  - `ADR-0002-ir-v0_2-structured-expressions.md` — the additive text→structure
    migration + `ir_version` bump.
- **Traceability** — `deal_mappings` recorded on the expression metaclass atoms
  (10 KerML + `TriggerInvocationExpression` in SysML v2); `index/coverage.json`
  rebuilt.
- **Retired** — `ir/v0.1/FUTURE-structured-expressions.md` (the Stage-3 seed),
  now realized by v0.2.

### Added — Behavioral surface (BH-1..BH-7)

- **Grammar** — `deal.ebnf` §9b/§9c: `ActionBody` / `StateBody` and their
  members — pins, succession chains, control endpoints, `decide`/`par`,
  `loop`/`for`, `send`/`accept`/`assign`, perform, item flow (`~>`), bind,
  escape hatch (`node`/`succession`), `entry`/`do`/`exit`, transitions
  (`on … [g] / e -> target`). `_StateMember` admits state parameters (pins).
- **IR v0.1** (`ir/v0.1/`) — additive superset of v0:
  - `schema.json` — 16 behavioral node kinds, 4 edge kinds with payload, a
    `PayloadBehavioral` variant; accepts `ir_version` `"v0"` and `"v0.1"`.
  - `behavioral-mapping.md` — the locked DEAL → IR → SysML v2 / KerML mapping
    contract (metaclasses + clauses verified against the SysML v2 LLM wiki).
  - `ADR-0001-ir-v0_1-behavioral.md` — the additive-v0.1 decision.
  - `FUTURE-structured-expressions.md` — seed for Stage-3 structured-expression
    emission (guards/values currently carried as text).
- **Showcase** — `examples/showcase/packages/vehicle/behaviors.deal` rewritten
  in real behavioral syntax; `charging-states.deal` added (state machine). The
  pre-parser annotation drafts moved to `examples/behavioral-preview/` are now
  superseded.
- **Traceability** — `deal_mappings` recorded on 21 SysML v2 metaclass atoms in
  the wiki; `index/coverage.json` reflects behavioral coverage.

## [Phase 0] — Specification baseline

68 locked design decisions; `lexical.ebnf`, `deal.ebnf`, `dealx.ebnf`,
`dealview.ebnf`; IR v0 contract (`ir/v0/`); and the EV-platform showcase corpus.
