# DEAL Design Decisions — Consolidated

> **Language**: DEAL — Digital Engineering Authoring Language
> **Status**: Phase 0 complete — ready for Phase 1 foundation implementation
> **Sessions**: 2026-05-16 (3 sessions)
> **Total decisions**: 68 locked

---

## Table of Contents

1. [Foundational Architecture (FA-1 through FA-5)](#foundational-architecture)
2. [Naming (NC-1)](#naming)
3. [Language Model (LM-1 through LM-3)](#language-model-alignment)
4. [File Structure (FS-1 through FS-4)](#file-structure)
5. [Project Structure (PS-1 through PS-10)](#project-structure)
6. [Syntax — Definitions (SD-1 through SD-23)](#syntax--definitions)
7. [Syntax — Compositions (CS-1 through CS-16)](#syntax--compositions)
8. [Simulation Integration (SIM-1 through SIM-5)](#simulation-integration)
9. [Syntax — Behavior (BH-1 through BH-8)](#syntax--behavior)
10. [Implementation Staging](#implementation-staging)
11. [Decisions Deferred](#decisions-deferred)

---

## Foundational Architecture

### FA-1: DEAL is a systems engineering compiler [LOCKED]

DEAL is a **systems engineering compiler infrastructure** — a text-first
authoring language with its own intermediate representation (IR) that
transpiles to multiple target formats.

```
                          ┌─────────────────────────────────┐
                          │   DEAL Source (.deal / .dealx)    │
                          │   Human + AI authored             │
                          └──────────┬──────────────────────┘
                                     │ parse
                                     ▼
                          ┌─────────────────────────────────┐
                          │   DEAL AST                       │
                          │   Concrete syntax tree           │
                          └──────────┬──────────────────────┘
                                     │ analyze + lower
                                     ▼
                    ┌────────────────────────────────────────────┐
                    │   DEAL IR (the kernel)                      │
                    │   Semantic model + agent envelope           │
                    │   Superset of all target capabilities       │
                    └──────┬─────┬──────┬──────┬──────┬─────────┘
                           │     │      │      │      │
              codegen      │     │      │      │      │
                           ▼     ▼      ▼      ▼      ▼
                    ┌──────┐ ┌──────┐ ┌─────┐ ┌────┐ ┌──────────┐
                    │SysML │ │ReqIF │ │FMI/ │ │ICD │ │Documents │
                    │v2    │ │XML   │ │FMU  │ │pkgs│ │(Word,PDF,│
                    │JSON  │ │      │ │     │ │    │ │ HTML)    │
                    └──────┘ └──────┘ └─────┘ └────┘ └──────────┘
                    Cameo    DOORS    Modelica  Wire   Reports
                    Sparx    Jama     Simulink  specs  Dashboards
```

**Key properties:**
1. DEAL IR is the kernel, not SysML v2 JSON
2. SysML v2 JSON is one export target among several
3. The IR carries everything — structure, agent metadata, simulation bindings
4. Import and export are separate paths
5. The DEAL source file is the canonical artifact — the single source of truth

### FA-2: Object-oriented library system is first-class [LOCKED]

Reusable, composable, versionable libraries as a core language feature.
Standard library includes physical interfaces, protocols, units, and
domain patterns. `deal install @deal-stdlib/mil-std-1553`.

### FA-3: Dual-purpose design [LOCKED]

DEAL serves defense/aerospace systems engineers and software engineers
building integrations equally. When tradeoffs arise, they're documented.

### FA-4: Self-explanatory syntax principle [LOCKED]

Every construct must be understandable by an AI agent or human reading
the file cold — without external documentation or language training.

### FA-5: Simulation integration is first-class [LOCKED]

Models serve as simulation inputs and consume simulation outputs.
JSON as universal I/O format. `deal_sim` Python SDK. `deal simulate` CLI.

---

## Naming

### NC-1: DEAL — Digital Engineering Authoring Language [LOCKED]

```
Language:     DEAL — Digital Engineering Authoring Language
CLI:          deal
Extension:    .deal (definitions) / .dealx (compositions)
Organization: deal-lang (GitHub)
Website:      deal-lang.org
```

---

## Language Model Alignment

### LM-1: TypeScript as primary language feel [LOCKED]

DEAL follows TypeScript conventions wherever applicable. Deviations only
for systems engineering constructs with no TypeScript analog.

### LM-2: Doc comments use JSDoc style [LOCKED]

```deal
/**
 * Base vehicle definition for the sedan product line.
 *
 * @see REQ_SYS_001 — system range requirement
 */
abstract part def EVPlatform {
```

### LM-3: String literals — TypeScript model [LOCKED]

```deal
attribute name : String = "Vehicle Alpha";              // double quotes

attribute description : String = `                       // backtick multi-line
    Multi-line string content.
`;

attribute display : String = `${name} (${variant})`;    // backtick template
```

Single quotes accepted as alias; `deal fmt` normalizes to double quotes.

---

## File Structure

### FS-1: File anatomy [LOCKED]

```deal
@header { ... }
package sedan_project.vehicle;
import deal.std.units.{kg, m, s};
import sedan_project.interfaces.*;

// Model content
part def Vehicle <<specializes>> Machine { ... }
```

### FS-2: @header block with CM fields [LOCKED]

```deal
@header {
    path:       sedan_project/vehicle.deal
    schema:     deal/0.1
    created:    2026-05-16T10:30:00Z by "David Dunnock"
    modified:   2026-05-16T14:22:00Z by "David Dunnock" via deal:fmt
    reviewed:   2026-05-16T15:00:00Z by "David Dunnock"
    hash:       sha256:a3f2b8c9...
    status:     draft
    baseline:   v2.1.0
    marking:    CUI
}
```

Fields: `path`, `schema`, `created`, `modified`, `reviewed`, `hash`,
`status` (draft|review|baseline|superseded), `baseline`, `marking`.
Interior syntax: colon-separated `key: value` inside braces.

### FS-3: Attribution model [LOCKED]

- `by` always identifies a human (from `deal config`)
- `via` optionally identifies the tool (deal:fmt, deal:import, claude:claude-code)
- `deal config --global user.name` / `user.email` sets identity (git-style)
- `deal fmt` refuses to run without configured identity
- Human is accountable; AI/tool is informational

### FS-4: System-wide index [LOCKED]

No per-file index. Project-wide index generated by `deal index`,
stored at `.deal/index.json`, gitignored. Queried by `deal query`,
LSP, and MCP server.

---

## Project Structure

### PS-1: deal.toml project manifest [LOCKED]

```toml
[project]
name = "ev-platform"
version = "0.1.0"
schema = "deal/0.1"
marking = "Unclassified"

[workspace]
packages = ["packages/*"]

[workspace.aliases]
vehicle    = "packages/vehicle"
interfaces = "packages/interfaces"
reqs       = "packages/requirements"
use_cases  = "packages/use-cases"

[dependencies]
deal-std = "0.1"

[simulations]
registry = "simulations/deal.sims.toml"
cache_dir = ".deal/simulations"

[build.targets]
sysml-v2 = { format = "json", output = "build/sysml-v2/" }
reqif = { format = "xml", output = "build/reqif/" }
docs = { format = "html", output = "build/docs/" }
```

### PS-2: Package declarations with dot paths [LOCKED]

```deal
package sedan_project.vehicle;
```

### PS-3: Barrel exports via index.deal [LOCKED]

Explicit selective exports (TypeScript index.ts pattern):

```deal
// index.deal
export electrical.{HVDCPort, CANBus};
export thermal.{CoolantPort, ThermallyManaged};
```

Barrel files are named `index.deal` to match the TypeScript convention
already used elsewhere in DEAL's language feel (LM-1).

### PS-4: Five import forms [LOCKED]

```deal
import deal.std.units.{kg, m, s};              // external dependency
import tracking.{Radar};                        // workspace alias
import .local_module.{HelperType};              // relative (same package)
import ..sibling_package.{SharedInterface};     // relative (parent)
import interfaces.*;                            // barrel glob
import interfaces as intf;                      // module reference + alias
```

### PS-5: Workspace aliases — pnpm-style [LOCKED]

```toml
[workspace.aliases]
tracking = "packages/subsystems/tracking"
```

### PS-6: Unit literals — function form from libraries [LOCKED]

```deal
import deal.std.units.{kg, m, s, V, A, kW};
attribute mass : Mass = kg(1500);
```

### PS-7: Build targets in deal.toml [LOCKED]

```toml
[build.targets]
sysml-v2 = { format = "json", output = "build/sysml-v2/" }
reqif = { format = "xml", output = "build/reqif/" }
```

### PS-8: Standard directory layout [LOCKED]

```
project/
├── deal.toml                      # project manifest
├── .deal/                         # generated (gitignored)
│   ├── index.json                 # system-wide index
│   └── simulations/               # simulation I/O cache
├── model/                         # compositions (.dealx)
│   ├── vehicle.dealx
│   ├── traceability.dealx
│   └── variants/
├── packages/                      # definitions (.deal)
│   ├── vehicle/
│   ├── interfaces/
│   ├── requirements/
│   └── use-cases/
├── simulations/                   # simulation code
│   ├── deal.sims.toml
│   ├── thermal/
│   └── dynamics/
├── test/                          # verification evidence
│   └── data/
└── docs/                          # generated output
```

### PS-9: deal config for user identity [LOCKED]

```bash
deal config --global user.name "David Dunnock"
deal config --global user.email "you@example.com"
```

### PS-10: .deal/ generated directory [LOCKED]

Gitignored. Contains index, parser cache, and simulation I/O cache.

---

## Syntax — Definitions

### SD-1: Element keywords match SysML v2 vocabulary [LOCKED]

```deal
part def    port def    action def    state def
requirement def    constraint def    attribute def    item def
interface def    connection def    flow def    allocation def
```

### SD-2: Typing uses colon [LOCKED]

```deal
part engine : Engine;
attribute mass : Mass;
```

### SD-3: Double angle bracket delimiters [LOCKED]

```deal
<<specializes>>    <<redefines>>    <<subsets>>
<<satisfies>>      <<allocated to>> <<derives from>>
```

Zero collision with any operator. ASCII approximation of UML guillemets.

### SD-4: Two-tier operator system [LOCKED]

**Tier 1 — Declaration-level (no prefix):**
```deal
part def Sedan <<specializes>> Vehicle { }
attribute mass <<redefines>> Vehicle::mass = kg(1500);
```

**Tier 2 — Annotation-level (with @category: prefix):**
```deal
@trace:<<satisfies>> REQ_SYS_001
@connection:<<connects>> fuelPort to engine.intake
@simulation:<<computes>> thermalProfile { ... }
```

### SD-5: SysML v2 symbolic operators as import aliases [LOCKED]

`:>` → `<<specializes>>`, `:>>` → `<<redefines>>`, etc.
`deal import` reads SysML v2. `deal fmt` normalizes to DEAL canonical form.

### SD-6: Relationship categories [CAPTURED]

```
@trace:        Requirements traceability
@connection:   Physical/logical connections
@behavioral:   Behavior relationships
@flow:         Item/data flows
@state:        State machine constructs
@temporal:     Time-related constructs
@requirement:  Requirement-specific constructs
@simulation:   Simulation bindings
@document:     Document generation directives
```

### SD-7: Modifiers are bare keywords [LOCKED]

```deal
abstract part def Vehicle { }
derived attribute totalMass = dryMass + cargoMass;
readonly attribute vin : String;
ordered part stages : Stage [*];
```

### SD-8: Direction keywords are bare [LOCKED]

```deal
in port fuelIn : FuelPort;
out port exhaustOut : ExhaustPort;
inout port controlBus : ControlBus;
```

### SD-9: Visibility as scope wrappers [LOCKED]

```deal
part def Vehicle {
    public (
        in port fuelIn : FuelPort;
        part engine : Engine;
    )
    protected (
        derived attribute totalMass = dryMass + cargoMass;
    )
    private (
        attribute internalState : Integer;
    )
}
```

### SD-10: Semicolons [LOCKED]

Required on single-line declarations. Optional after block-closing braces.

### SD-11: Comments [LOCKED]

```deal
// single-line
/* block comment */
/** JSDoc doc comment */
```

### SD-12: String literals [LOCKED]

Double quotes for strings. Backticks for multi-line and templates.
Single quotes accepted, `deal fmt` normalizes to double.

### SD-13: Unit literals [LOCKED]

Function form from libraries: `kg(1500)`, `V(800)`, `km(200) / hr(1)`.

### SD-14: Multiplicity [LOCKED]

```deal
part wheels : Wheel [4];           // exactly 4
part passengers [1..5];            // 1 to 5
part cargo : CargoItem [*];        // zero or more
part engines : Engine [1..*];      // one or more
attribute name : String [0..1];    // optional
```

### SD-15: Annotation value syntax [LOCKED]

Inline single-value, braces for multi-field:

```deal
@confidence: 0.85
@assumes: "Engine mass will not exceed 250 kg"

@simulation:<<computes>> thermalProfile {
    equation: "Lumped-parameter thermal model"
    tool: "python"
    entry: "simulations/thermal/battery_thermal.py"
}
```

### SD-15a: Annotation-body field separator — `;` canonical, `,` rejected [LOCKED — phase 05.1]

**Decision:** `;` is the canonical annotation-body field terminator. The parser **explicitly
consumes** `;` after each annotation field value. `,` is **NOT** a field separator alias —
using `,` between annotation body fields is a hard parser error (E0123).

**Rationale:** The showcase oracle (`battery.deal`, `behaviors.deal`, `motor.deal`) uses `;`
throughout annotation bodies. The Phase 1.5 parser-strictness contract requires that
silent-tolerance behaviors be converted into explicit accepts or explicit diagnostics.
Accepting `,` silently would mask authoring errors and conflict with import-list syntax.

**Grammar rule:** `AnnotationField ::= AnnotationKey ":" Expression ";"?` — the trailing ";"
is optional before the closing "}" of the enclosing AnnotationBody.

**Source reference:** `parser_deal.zig:1914-1923` (old silent-discard path, to be replaced in
Wave B). Recorded during Phase 05.1 Wave A as part of I1 resolution.

### SD-15b: Annotation-body field keys accept keywords [LOCKED — phase 05.1]

**Decision:** Annotation body field keys may be any IDENT **or** any reserved keyword
(`AnnotationKey ::= IDENT | _Keyword`). The lexer is **flat-reserved** — keywords such as
`from`, `to`, `via`, `method`, `status` always emit keyword tokens, never IDENT tokens.

**Rationale:** The showcase uses keyword-valued field keys (e.g. `@flow:<<flows to>> deliverPower
{ from: requestTorque; }` in `behaviors.deal:29`). A parser that accepted only IDENT as a
field key would silently reject valid showcase annotations. The parser
(`parser_deal.zig:1908`) already accepts `key_tok.tag == .ident or isKeyword(key_tok.tag)`;
this decision makes that accept explicit and spec-normative.

**No contextual lexer machinery needed** — the AnnotationKey grammar rule is the authoritative
documentation of which tokens are legal keys; the parser dispatches via `isKeyword()`.

**Source reference:** `parser_deal.zig:1908`, `isKeyword()`. Recorded during Phase 05.1 Wave A
as part of I2 resolution.

### SD-16: Doc comments + structured annotations [LOCKED]

`/** */` for narrative. `@` annotations for queryable metadata.

### SD-17: File extensions [LOCKED]

- `.deal` — definition files (components, interfaces, types)
- `.dealx` — composition files (systems, subsystems, wiring)
- `.dealx` can contain inline definitions for one-off types
- `deal fmt` warns if inline definition in `.dealx` is referenced by multiple compositions
- `.deal` files never import from `.dealx` — unidirectional dependency
- Parser uses extension to select grammar mode

### SD-18: Needs, requirements, and use cases as definition keywords [LOCKED]

```deal
need def NEED_RANGE { ... }
requirement def REQ_SYS_001 { ... }
use case def LongDistanceTrip { ... }
```

Definitions in `.deal` files. Allocations and traceability in `.dealx` files.

### SD-19: Definitions and allocations are separated [LOCKED]

```
packages/ (.deal)                model/ (.dealx)
├── requirements/                ├── vehicle.dealx        (architecture)
│   ├── needs.deal   [WHAT]      ├── traceability.dealx   (req chain)
│   └── system.deal  [WHAT]      └── variants/
├── use-cases/
│   ├── driving.deal [WHAT]
│   └── charging.deal [WHAT]
└── vehicle/
    └── battery.deal [WHAT]
```

### SD-20: Requirements declare verification contracts [LOCKED]

```deal
requirement def REQ_SYS_001 {
    public (
        attribute minRange : Length [1] = km(483);
    )

    verification {
        accepts: [simulation, test];
        rejects: [analysis, inspection];
        threshold: minRange;
        operator: ">=";
    }
}
```

- `accepts` — verification methods that satisfy this requirement
- `rejects` — methods explicitly insufficient
- `threshold` — which attribute to compare against
- `operator` — comparison direction (">=", "<=", "==")
- `conditions` — environmental conditions requiring separate evidence
- `deal check` enforces method type-checking against accepts/rejects

### SD-21: calc def — reusable, typed calculations [LOCKED]

`calc def` is a named pure function: typed parameters, a return type, and a
single `return`. It maps to a KerML Function (directed parameters + result
feature) and is the in-language compute surface (compiled to Zig). Heavier /
black-box computation belongs to `deal-sim`, not `calc`.

```deal
calc def MarginOfSafety(allowable : Pressure, actual : Pressure) : Real {
    return allowable / actual - 1;
}
```

- **Parameters**: `_DirectionPrefix? IDENT : Type [mult]?` — direction defaults to
  `in`. `out`/`inout` are accepted for full KerML fidelity (superset) but
  discouraged; `deal fmt` omits a redundant leading `in`.
- **Purity rule**: a calc with only `in` params + one `return` is
  *expression-valued* (callable inside any expression via the existing
  `FunctionCallExpression`). Any `out` param makes it *statement-valued* (callable
  only in statement position). Enforced by sema.
- **Body**: `( AnnotationStatement | LocalBinding )* ReturnStatement` — restricted
  to the model-level-evaluable subset (KerML §8.4.4.9.8): no loops, I/O, or side
  effects. `LocalBinding` reuses `derived? attribute name : T = expr;`.
- The assignment-style body that binds `out` parameters is a **deferred**
  sub-decision; until it lands, only the input-only/single-return form parses.

### SD-22: constraint def — named Boolean predicates with `require` [LOCKED]

`constraint def` becomes a named, optionally parameterized Boolean predicate.
It maps to a KerML Predicate; asserting one maps to a KerML Invariant.

```deal
constraint def PositiveForce(f : Force) { require f >= N(0); }
constraint def BatteryLimits { require packTemp <= degC(60) AND soc <= 1.0; }
```

- **`require <ConditionExpression> ;`** — the invariant statement. Multiple
  `require` lines are an implicit **conjunction** (all must hold).
- Two modes: parameterized (reusable predicate) and contextual (references
  enclosing-scope names, like `precondition`).
- A constraint is Boolean-valued and callable, so `precondition`, `postcondition`,
  satisfy `criteria`, and any `ConditionExpression` can reference it with **no
  grammar change** — this drains repeated boolean logic out of those blocks
  rather than duplicating it. The requirement `verification` block (threshold /
  operator / method typing / evidence) is unchanged — it is the managed,
  evidence-backed layer above raw predicates.

### SD-23: `=>` return contract + precision vocabulary [LOCKED]

A calc return may carry a `=>` contract: a list of obligations on the result.
Reuses the existing `ARROW` token (precedent: satisfy `=> { … }`); `->`
(`THIN_ARROW`) is left to evidence maps / connect.

```deal
calc def Drag(rho : Density, v : Speed, area : Area, cd : Real) : Force => ± percent(1), PositiveForce { … }
calc def KineticEnergy(mass : Mass, v : Speed) : Energy => sig 4 { … }
```

- **`ReturnContract ::= "=>" ContractItem ("," ContractItem)*`**; each item is a
  `PrecisionSpec` or a `ConstraintRef` (a call to an SD-22 constraint).
- **`PrecisionSpec ::= "sig" INTEGER | "±" Tolerance`**. `±` is canonical; the
  ASCII alias `+/-` is accepted and normalized to `±` by `deal fmt` (SD-5 pattern).
  Tolerance is a unit constructor (`± mV(1)`, `± percent(2)`) or a dimensionless
  literal (`± 0.001`, `± 1.0e-9`).
- **Parse now, enforce later**: the grammar + IR slot land now; storage selection
  (f16–f128), error propagation, and FP-determinism enforcement are the
  numeric-model Lane A passes (N-03/N-04) and are out of scope for this change.
  `PrecisionSpec` is the seed N-01 extends.
- On KerML export, the precision contract is preserved as a metadata feature
  (preserved, not executed) — lossless round-trip; the superset seam.

**D-06 amendment — Generalized precision attach points [LOCKED — phase 05.2]:**

The `ReturnContract` is not exclusive to calc return values. It attaches to ANY
result-valued declaration — the grammar extends the `=>` suffix to:

1. **Calc return** (SD-23 original): `calc def Foo(...) : T => sig 4 { return ...; }`
2. **Attribute/feature value** (D-06): `attribute mass : Mass = kg(5) => sig 4;`
   and `derived attribute q : Pressure = ... => ± percent(1);`
3. **Require threshold** (D-06): `require mass <= kg(1500) => sig 4;`

The `ReturnContract` attaches to the **result value** in each case — result-only,
never to bare sub-literals or type annotations. In `deal.ebnf`, the optional
`ReturnContract?` is placed BEFORE the terminating `;` in both `AttributeUsage`
and `RequireStatement` productions. This positions the contract on the
expression result consistently across all three attach points.

```deal
// attribute-value precision (D-06)
attribute mass : Mass = kg(5) => sig 4;
derived attribute q : Pressure = f / A => ± percent(1);

// require-value precision (D-06)
require mass <= kg(1500) => sig 4;
```

Contracts on sub-expressions (e.g. `kg(5) => sig 4` inside a larger expression)
are **not** supported and are a parse error — precision is a declaration-level
construct, not an expression-level operator.

---

## Syntax — Compositions

### CS-1: Dual syntax model [LOCKED]

```
Definition files (.deal)         Composition files (.dealx)
─────────────────────            ──────────────────────────
part def BatteryPack { }         [<system EVPlatform>]
port def HVDCPort { }               [<subsystem X>]
connection def HVDCCable { }             [<BatteryPack as="b" />]
flow def PowerDelivery { }              [<connect ... />]
                                         [<expose ... />]
                                     [</subsystem>]
                                 [</system>]
```

### CS-2: [< >] composition tags [LOCKED]

```deal
[<system EVPlatform>] ... [</system>]
[<subsystem EnergyStorage>] ... [</subsystem>]
[<BatteryPack as="battery" voltage={V(800)} />]
[<connect from="a" to="b" via={Cable {...}} carrying={Power {...}} />]
[<expose battery.hvOut as="hvPowerOut" />]
```

### CS-3: Component instances use `as` [LOCKED]

```deal
[<BatteryPack as="battery" ... />]
```

### CS-4: Physical/logical connection separation [LOCKED]

```deal
[<connect from="battery.hvOut" to="inverter.dcIn"
    via={HVDCCable { wireGauge: "2/0 AWG", length: m(2.5) }}
    carrying={PowerDelivery { voltage: V(800), maxCurrent: A(350) }}
/>]
```

- `via` — physical connection (cable, harness, hose)
- `carrying` — logical flow (power, data, coolant)
- Both typed against `connection def` and `flow def` definitions

### CS-5: connection def / flow def keywords [LOCKED]

```deal
connection def HVDCCable { ... }    // physical medium
flow def PowerDelivery { ... }      // logical content
```

### CS-6: expose keyword [LOCKED]

```deal
[<expose battery.hvOut as="hvPowerOut" />]
```

### CS-7: Hierarchical nesting [LOCKED]

System > subsystem > subsystem. Each level has internal wiring and exposed interfaces.

### CS-8: Prop validation via multiplicity [LOCKED]

Component definitions declare props with multiplicity. `deal check` validates
that compositions satisfy required props (`[1]`), respect optionals (`[0..1]`),
and meet collection minimums (`[1..*]`).

### CS-9: Traceability composition block [LOCKED]

```deal
[<traceability EVPlatformTraces>]
    [<allocate ... />]
    [<satisfy ...>] => { ... } ... [</satisfy>]
    [<validate ...>] ... [</validate>]
[</traceability>]
```

### CS-10: Satisfy block with executable criteria and typed returns [LOCKED]

```deal
[<satisfy requirement="REQ_SYS_001" by="EVPlatform"
    method="simulation"
>] => {
    actualRange : Length;
    margin : Length;
    marginPercent : Real;
}
    criteria {
        actualRange >= REQ_SYS_001.minRange
    }

    evidence simulation {
        source: "simulations/dynamics/range_model.py"
        binding: "range_model"
        maps { totalRange -> actualRange }
    }

    compute {
        margin = actualRange - REQ_SYS_001.minRange;
        marginPercent = margin / REQ_SYS_001.minRange * 100;
    }
[</satisfy>]
```

- `method` is type-checked against requirement's `verification.accepts`
- `=> { ... }` declares typed return values (TypeScript arrow syntax)
- `criteria` contains evaluable boolean expressions
- `evidence` blocks reference simulations, tests, analyses
- `maps` populates return values from evidence outputs
- `compute` derives additional values from returns
- `gap` documents partial satisfaction with risk and mitigation
- `deal check --verify` evaluates all criteria and reports PASS/FAIL/PARTIAL

### CS-11: Validate block [LOCKED]

```deal
[<validate requirement="REQ_SYS_001" by="LongDistanceTrip">]
    scenario: "450km highway trip with one charge stop"
    status: "passed"
    evidence: "Use case analysis completed 2026-05-01"
[</validate>]
```

### CS-12: Allocate block [LOCKED]

```deal
[<allocate from="NEED_RANGE" to="REQ_SYS_001" relationship=<<derives>> />]
```

### CS-13: Satisfy returns populated via evidence maps [LOCKED]

```deal
evidence simulation {
    source: "simulations/dynamics/range_model.py"
    binding: "range_model"
    maps {
        totalRange -> actualRange
    }
}
```

The `maps` block connects simulation/test output fields to return value names.

### CS-14: Satisfy returns derived via compute blocks [LOCKED]

```deal
compute {
    margin = actualRange - REQ_SYS_001.minRange;
    marginPercent = margin / REQ_SYS_001.minRange * 100;
}
```

### CS-15: Return values referenceable as TraceName.ReqID.fieldName [LOCKED]

```deal
// From anywhere in the model:
derived attribute massBudgetRemaining : Mass =
    REQ_SYS_003.maxMass - EVPlatformTraces.REQ_SYS_003.actualMass;

@concerns: `Range margin at ${EVPlatformTraces.REQ_SYS_001.marginPercent}%`
```

### CS-16: Verification method type-checking [LOCKED]

If a requirement declares `accepts: [test]` and a satisfy block specifies
`method="simulation"`, `deal check` reports an error. The verification
method must match the requirement's accepted list.

---

## Simulation Integration

### SIM-1: JSON as universal simulation I/O [LOCKED]

```
DEAL model → input.json → Simulation → output.json → DEAL model
```

### SIM-2: deal_sim Python SDK [LOCKED]

```python
from deal_sim import DealSimulation

class BatteryThermal(DealSimulation):
    inputs = { "packResistance": {"type": "Real", "unit": "ohm"} }
    outputs = { "heatGenerated": {"type": "Real", "unit": "W"} }

    def run(self, inputs: dict) -> dict:
        return {"heatGenerated": ...}

if __name__ == "__main__":
    BatteryThermal.cli()
```

### SIM-3: Simulation registry — deal.sims.toml [LOCKED]

```toml
[simulations.battery_thermal]
tool = "python"
entry = "thermal/battery_thermal.py"
class = "BatteryThermal"
binds_to = "packages/vehicle/battery.deal::BatteryPack"
annotation = "@simulation:<<computes>> thermalProfile"
inputs = [
    { model_path = "...", param = "...", unit = "..." }
]
outputs = [
    { param = "...", model_path = "...", unit = "..." }
]
```

### SIM-4: Simulation CLI commands [LOCKED]

```bash
deal simulate <name>            # run specific simulation
deal simulate --all             # run all
deal simulate --stale           # run only stale
deal check --simulations        # validate bindings
deal check --verify             # evaluate criteria (cached)
deal check --verify --run-sims  # re-run stale then evaluate
deal evidence capture           # snapshot results
deal evidence baseline v2.1.0   # tag with baseline
```

### SIM-5: Three-level verification [LOCKED]

**Level 1 — Structural completeness:** Every need traces to requirement.
Every requirement has satisfaction. Every satisfaction has evidence.

**Level 2 — Criteria evaluation:** Evaluates boolean criteria from
`[<satisfy>]` blocks. Compares model values against requirement thresholds.
Returns PASS/FAIL/PARTIAL with actual values and margins.

**Level 3 — Evidence freshness:** Detects stale simulation results.
Validates test data file paths exist. Recommends re-runs.

---

## Syntax — Behavior

> Closes the larger of the two functional gaps in
> `DEAL-KerML-Coverage-Gap-Analysis.html` §4.2 (behavioral control flow).
> Full rationale, EBNF, glyph-coverage proof, and the graphical↔text
> collapse contract live in `DEAL-Behavior-ActivityFlow-Design.html`.
> Eight decisions: BH-1 through BH-7 LOCKED, BH-8 OPEN.

### BH-1: Behavior is structured surface + explicit-graph escape hatch [LOCKED]

Behavior is authored in two registers over **one** IR. A *structured*
register for the readable common case, and an *explicit-graph* escape hatch
for arbitrary cyclic graphs the structured form cannot nest. Both lower to
the same node/edge IR, so readability never costs expressiveness or
graphical-notation coverage.

```deal
// structured
start -> authenticate -> deliverPower -> done;

// escape hatch (arbitrary back-edge / cross-edge)
node a : authenticate;
node b : deliverPower;
succession a -> b;
succession b -> a [retry];
```

### BH-2: Control succession is an operator chain [LOCKED]

Control flow between steps is the `->` operator, chainable.

```deal
start -> authenticate -> deliverPower -> measure -> done;
```

`->` is shared with `.dealx` connect (CS-4). The two are **disjoint by
mode**: connect appears only in `.dealx`; succession only inside an
`ActionBody` / `StateBody`. No intra-file ambiguity.

### BH-3: Control nodes are structured blocks [LOCKED]

Fork/join, decision/merge, and loops are blocks, not bare node keywords.
Each desugars to the corresponding KerML control node; the block's single
exit is the implicit merge/join.

```deal
authenticate -> decide {          // DecisionNode + implicit MergeNode
  [soc >= 100] -> done
  [else]       -> deliverPower
}

deliverPower -> par {             // ForkNode + implicit JoinNode
  -> coolPack
  -> logTelemetry
} -> resume;

loop while [soc < 100] { deliverPower -> measure; }
for cell in cells { balance(cell); }
```

### BH-4: State transition is a single line [LOCKED]

A transition collapses KerML trigger / guard / effect / target onto one
line; state behaviors use `entry|do|exit / BEHAVIOR`.

```deal
state Charging {
  entry / startCharge();
  do    / regulateCurrent();
  exit  / stopCharge();
  on TempHigh [temp > maxC] / shutdown() -> Fault;   // on TRIGGER [GUARD] / EFFECT -> TARGET
}
```

Equivalent SysML v2 textual: `transition first Charging accept TempHigh if
temp>maxC do shutdown() then Fault`.

### BH-5: Graphical canvas ↔ text is a deterministic bijection on the IR [LOCKED]

The UI draws full SysML v2 graphical notation; a structuring pass collapses
any drawn control-flow graph to **one** canonical DEAL text. Reducible
regions become structured constructs; irreducible subgraphs become
escape-hatch `node`/`succession` declarations (BH-1). Canonicalization fixes
every free choice from stable model identity, never from layout, so the same
graph always yields the same text.

Two laws hold: `collapse(expand(text)) == text` (canonical text is a
fixpoint) and `expand(collapse(graph)) ≅ graph` (IR round-trips up to
re-layout). Per GV-13, **behavior is model (`.deal`); diagram geometry is
view (`.dealview`)** — dragging a box touches only the sidecar.

### BH-6: Item/object flow uses a distinct operator `~>` [LOCKED]

Object/data flow between feature references is `~>`, kept visually separate
from control succession (`->`) and from connect. `flow def` is unchanged —
it remains the item-flow *type* (CS-5); a `~>` edge is a flow *usage*.

```deal
deliverPower.delivered ~> measure.sample;            // ItemFlow
deliverPower.delivered ~> measure.sample : Energy;   // typed by a flow def
bind measure.sample = deliverPower.delivered;        // BindingConnector
```

### BH-7: Action and state bodies are dedicated productions [LOCKED]

`ActionDefinition` and `StateDefinition` take dedicated `ActionBody` /
`StateBody` productions rather than the shared `DefinitionBody`, so
behavioral members (successions, transitions, control blocks) are admissible
only where they are legal. A `part def` cannot contain a succession.

```
ActionDefinition ::= "action" "def" IDENT StructuralRelationship? ActionBody
StateDefinition  ::= "state"  "def" IDENT StructuralRelationship? StateBody
```

The IR for both is KerML's behavioral core:
`{ Step, Succession, ItemFlow, ControlNode (= stdlib action), Binding }`.

### BH-8: Pin sides, swimlanes, streaming flows, time triggers [OPEN]

Deferred to a follow-up behavior pass:

- **Pin direction** (`in`/`out`/`inout`) is model; **pin side**
  (left/right/top/bottom) is layout → `.dealview` vocabulary.
- **Swimlanes / action allocation** to parts (graphical
  `perform-action-swimlanes`) — interaction with `[<allocate>]` (CS).
- **Streaming vs discrete** item flows.
- **Time / change-event triggers** for transitions (`after`, `when`).

---

## Implementation Staging

> **Ordering authority:** Execution order is now maintained in
> `DEAL-LANG-ROADMAP.html`. The phase list below records the current roadmap
> shape at decision-record granularity; if detailed milestone ordering differs,
> the roadmap supersedes this section.

### Stage 0: Language Design Foundation [COMPLETE]

65 locked decisions. Showcase project with 29 files.

### Phase 1: Foundation

1. Zig lexer for the full `lexical.ebnf` token set
2. Recursive-descent parser for `.deal` files
3. Composition parser for `.dealx` files with tag balancing
4. Error recovery and span-accurate diagnostics
5. C ABI boundary proven with a Rust FFI harness

Gate: all 19 showcase `.deal` / `.dealx` files tokenize and parse through
the Zig core, AST JSON snapshots are stable, and malformed-input tests do not
panic.

### Phase 2: Prove the Pipeline

1. Semantic analyzer: name resolution, type checking, import validation
2. DEAL IR v0 definition: node model, stable IDs, spans, relationship graph,
   metadata envelope, resolved-reference representation, and backend traversal
   API
3. AST → DEAL IR lowering and IR conformance tests
4. SysML v2 JSON codegen from IR
5. Offline SysML/KerML schema validator using local OMG schema references
6. Golden DEAL → SysML v2 JSON fixtures
7. `deal fmt` round-trip formatter
8. Rust CLI shell for `parse`, `check`, `fmt`, and `build`

Gate: `deal check` validates the showcase model, `deal build --target sysml-v2`
emits schema-valid JSON through the offline validator, golden fixtures match
hand-written expected JSON, `deal fmt` round-trips all 19 files, and the
showcase export has a recorded SysML v2 viewer/import smoke result or a
documented viewer blocker.

### Phase 3: Editor Intelligence

1. VS Code TextMate grammar and snippet library
2. Tree-sitter grammar and query files
3. Rust LSP server
4. VS Code LSP integration

### Phase 4: Ecosystem

1. `deal-stdlib` — standard library units and interfaces
2. ReqIF XML codegen backend
3. `deal-lang.org` documentation site with snippet-render CI
4. Package resolution and lockfile generation

Prerequisite: acquire ReqIF normative references before implementing ReqIF
codegen.

### Phase 5: Simulation Story

1. `deal_sim` SDK
2. `deal simulate` orchestrator
3. Evidence capture and verification status reporting

### Phase 6: Application

1. Desktop editor application
2. SysML v2 / ReqIF import pipelines
3. Document generation backend
4. Standard library expansion

---

## Decisions Deferred

- Expression syntax details (arithmetic, comparison, logical)
- Path expression syntax
- Full relationship category enumeration
- MQL query language design
- Codegen backend API
- Default visibility when no wrapper
- Constraint expression syntax
- `@document:` category design
- `[<document>]` composition block for report generation

---

## Design Principles (Summary)

1. **Text-first** — optimized for editors and terminals, not GUIs
2. **AI-native** — token efficient, context dense, self-explanatory
3. **Single source of truth** — DEAL is canonical; everything else derives
4. **Compiler architecture** — DEAL IR kernel, multiple codegen backends
5. **OOP libraries** — reusable, composable, versionable packages
6. **Visual hierarchy** — bare keywords | `<<operators>>` | `@category:<<operators>>` | `[<tags>]`
7. **Definition/composition split** — `.deal` for WHAT, `.dealx` for HOW
8. **Executable verification** — requirements declare contracts, satisfaction returns typed values
9. **Simulation as first-class** — JSON I/O, SDK, registry, orchestrator
10. **Defense-grade CM** — @header, attribution, baselining, markings

---

*Consolidated: 2026-05-16 from 3 design sessions*
*68 locked decisions across 8 categories (adds SD-15a/15b + SD-21/22/23)*
*Next: Phase 1 foundation implementation per `DEAL-LANG-ROADMAP.html`*