# Changelog — spec (language specification)

Notable changes to the DEAL language specification: grammar, design decisions,
IR contract, and the showcase corpus. Format loosely based on
[Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
