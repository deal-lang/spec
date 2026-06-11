# deal-lang/spec

Language specification, formal grammar, and normative examples for **DEAL** — the Digital Engineering Authoring Language.

## Why DEAL Exists

Digital engineering promises a single source of truth for complex systems — but there's no proper surface for it today. Model-Based Systems Engineering (MBSE) using graphical languages like OMG's SysML and UML gets closest, but in practice it creates as many problems as it solves:

- **Sync is fragile.** Requirements live in DOORS, architecture in Cameo, interfaces in spreadsheets, verification in test tools. Keeping a graphical model synchronized with these data sources is manual, error-prone, and perpetually out of date.
- **Versioning is an afterthought.** Binary model files don't diff, don't merge, and don't fit into the version control workflows that software engineering solved decades ago. Branching a system model shouldn't require an enterprise license and a database administrator.
- **GUIs don't scale.** Navigating a graphical modeling tool to update every attribute, connection, and traceability link across a system model is tedious, time-consuming, and hostile to automation. What takes a line of text takes a dozen clicks.

DEAL addresses this by treating the system model as **code** — plain text files that compile to SysML v2 / KerML, live in Git, diff cleanly, and can be generated, transformed, and validated with standard tooling. It targets the same semantic domain as SysML v2, but replaces the textual notation with a syntax designed for human readability and machine processing.

Models are split into **definitions** (`.deal`) and **compositions** (`.dealx`), connected through explicit imports and a TOML-based project manifest. The result is a system model that works like a codebase: grep it, script it, review it in a PR, and CI/CD it into downstream artifacts like SysML v2 JSON, ReqIF, or generated documentation.

## Status

**Phase 0 complete** — 65 design decisions locked, three EBNF grammar files written, showcase model validated. Ready for Stage 1 parser implementation.

## Repository Structure

```
spec/
├── grammar/
│   ├── lexical.ebnf              # Shared token definitions (~126 token types)
│   ├── deal.ebnf                 # Definition grammar — .deal files (101 productions)
│   ├── dealx.ebnf                # Composition grammar — .dealx files (43 productions)
│   ├── DESIGN-DECISIONS.md       # 68 locked decisions (Phase 0 + SD-15a/15b + SD-21/22/23; authoritative; tracked)
│   └── tmp-references/           # untracked (gitignored) build artifacts / references
│       ├── maal-layer1-notation-reference.md
│       ├── deal-grammar-verification-report.html
│       └── deal-parser-implementation-guide.html
│
├── spec/                         # Language specification documents (TBD)
│
├── examples/
│   └── showcase/                 # Complete EV platform model
│       ├── deal.toml             # Project manifest
│       ├── packages/             # .deal definition files
│       │   ├── vehicle/
│       │   ├── interfaces/
│       │   ├── requirements/
│       │   └── use-cases/
│       ├── model/                # .dealx composition files
│       │   ├── vehicle.dealx
│       │   └── traceability.dealx
│       ├── simulations/          # Simulation registry and code
│       └── test/                 # Verification evidence
│
└── references/                   # OMG normative grammars
    ├── SysML-textual-bnf.kebnf
    ├── KerML-textual-bnf.kebnf
    ├── SysML-graphical-bnf.kgbnf
    └── *.html                    # Rendered grammar documentation
```

## Grammar Architecture

```
lexical.ebnf (Layer 1)        ← shared token definitions
       │            │
       ▼            ▼
deal.ebnf (L2/L3)    dealx.ebnf (L4)
  .deal files           .dealx files
  definitions           compositions
```

All grammar files use W3C EBNF notation (XML 1.0 Fifth Edition §6). The lexer produces the same token stream for both file types; the parser selects a start symbol based on file extension.

## Key Documents

| Document                                                                                 | Description                                                                              |
|------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [grammar/deal.ebnf](grammar/deal.ebnf)                                                   | Definition file grammar — parts, ports, actions, states, requirements, constraints, etc. |
| [grammar/dealx.ebnf](grammar/dealx.ebnf)                                                 | Composition file grammar — systems, subsystems, connections, traceability, allocation    |
| [grammar/lexical.ebnf](grammar/lexical.ebnf)                                             | Token definitions shared by both grammars                                                |
| [grammar/DESIGN-DECISIONS.md](grammar/DESIGN-DECISIONS.md)                               | All 68 locked design decisions (Phase 0 + SD-15a/15b + SD-21/22/23)                     |
| [examples/showcase/](examples/showcase/)                                                 | Multi-file EV platform model exercising the full language surface                        |

## What DEAL Looks Like

A `.deal` definition file:

```
@header {
  schema deal/0.1
  marking Unclassified
}

package vehicle.power

import deal-std::units::*

part def BatteryPack {
  attribute capacity : Energy
  attribute voltage : ElectricPotential
  attribute cell_count : Natural

  port power_out : PowerPort
}
```

A `.dealx` composition file:

```
@header {
  schema deal/0.1
  marking Unclassified
}

import vehicle.power::BatteryPack
import vehicle.drivetrain::Motor

[<system>] ElectricVehicle {
  component battery : BatteryPack
  component motor : Motor

  [<connect>] battery.power_out -> motor.power_in
}
```

## Related Repositories

This is the specification repo within the [deal-lang](https://github.com/deal-lang) organization. See the [org README](../README.md) for the full repository map including the compiler, CLI, editor tooling, and standard library.

## Contributing

This specification is in early development. If you're interested in contributing to the grammar, language design, or showcase examples, open an issue to start a discussion.

## License

[MIT](LICENSE)
