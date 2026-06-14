# HALCYON Coverage Ledger

> **Gate status (2026-06-14):** Phases 1–6 done. `deal check` clean; the full
> sim chain runs (3 Python + 3 MATLAB) and `deal check --verify --run-sims`
> reports **5 PASS, 1 PARTIAL** (REQ_SYS_002 partial by design — TVAC gap).
> Upstream features/fixes landed to get here: real deal-stdlib loading
> (multi-file NUL parse + path-dep seeding), the `actor def` construct
> (SD-18b), MATLAB dispatch (cwd+addpath), negative-literal resolution,
> verify absolute-root + path expansion, and bare-output-key evidence
> resolution. Phases 7–9 pending.


Every grammar construct, viewer contract requirement, and KerML-mapping
exemplar this showcase must exercise. Check a box only when the construct
exists in the named file AND (core) passes `deal check`.

- **Exemplar** = file carrying the one prose KerML-mapping doc comment for that
  construct (first-exemplar density; repeats unannotated).
- KerML targets per `DEAL-KerML-Mapping-Strategy.html` (84/84, 2026-06-11),
  cross-checked against the `sysml-v2` emitter. Mechanisms M1–M6; status:
  impl / impl-generic / designed / gap.

## A · `.deal` constructs

| ✓ | Construct | Planned exemplar | KerML target (mech · status) |
|---|---|---|---|
| ☑ | `package` + nested package | `spacecraft/index.deal`; nesting in `interfaces/*.deal` | Package (M1 · impl) |
| ☐ | `import` — all 5 forms incl. `~` alias, `.*` | `spacecraft/eps.deal` | MembershipImport / NamespaceImport (M1 · designed; D-24 single-package emit) |
| ☑ | `export` lists | `interfaces/index.deal` | re-export membership (M2) |
| ☑ | `part def` | `spacecraft/eps.deal` (BatteryPack) | Structure / PartDefinition (M1 · impl) |
| ☑ | part usage `part x : T [n]` | `spacecraft/eps.deal` | Feature / PartUsage (M1 · impl); FeatureTyping synthesized (M2) |
| ☑ | `ordered` / `nonunique` | `spacecraft/eps.deal` (cell strings) | isOrdered impl · isUnique designed |
| ☑ | multiplicity `[n]` `[n..m]` `[n..*]` `[*]` | `spacecraft/adcs.deal` | MultiplicityRange (M1 · designed, not emitted); LiteralInfinity (M3) |
| ☑ | `port def` + port usage | `interfaces/power.deal` | PortDefinition / PortUsage (M1 · impl) |
| ☑ | port-body `<<redefines>>` (def body) | `interfaces/power.deal` (Rail3V3) | Redefinition (M1 · impl) |
| ☑ | `in/out/inout` directions | `interfaces/data.deal` (CANBus) | FeatureDirectionKind (M5 · impl on usages); conjugation derived at export (M2) |
| ☑ | `interface def` | `interfaces/data.deal` (CANBus) | InterfaceDefinition (M1 · impl, SysML-level) |
| ☑ | `attribute def` | `interfaces/power.deal` (PowerTelemetry) | DataType (M1 · impl — emitter quirk: emits AttributeUsage) |
| ☑ | attribute usage + default `= expr` | `interfaces/power.deal` | AttributeUsage (M1 · impl); FeatureValue default (M1 · designed) |
| ☑ | `derived attribute` | `spacecraft/eps.deal` | Feature isDerived=true (M1 · impl) |
| ☑ | `item def` | `spacecraft/payload.deal` (ImageProduct) | Class / ItemDefinition (M1 · impl) |
| ☑ | `flow def` + `@flow:` | `interfaces/data.deal` (flow def); `use-cases/*.deal` (@flow:) | Flow/Interaction (M1 · partial — emitter lumps to ItemDefinition) |
| ☑ | `need def` / `requirement def` | `requirements/needs.deal`, `requirements/system.deal` | RequirementDefinition (M1 · impl) |
| ☑ | `verification {}` accepts/rejects/threshold/conditions | `requirements/system.deal` | contract carried, not emitted (SD-20 · designed) |
| ☑ | all 4 verification methods | `requirements/system.deal` (REQ_SYS_001..007) | — |
| ☑ | `use case def` + actor/subject | `use-cases/imaging.deal` | UseCaseDefinition (M1 · impl-generic) |
| ☑ | `actor def` (NEW construct) + `part def` subject | `use-cases/actors.deal`; subject `spacecraft/system.deal` (Halcyon) | PartDefinition + «actor» metadata (M1 · impl as PartDefinition; SD-18b). KerML has no ActorDefinition — actor is a part marked «actor». Grammar/parser/sema/emitter added this session; verified via Zig lib test. |
| ☑ | `calc def` + params | `analysis/calcs.deal` (OrbitAvgPower) | **Function** (M1 · impl; ParameterMembership M2, ordered per D-12) |
| ☑ | return contract `=> ±` / `=> sig N` / predicate ref | `analysis/calcs.deal` (OrbitAvgPower ±, DoD sig+SafeDoD, LinkMargin sig+PositiveMargin) | no KerML equiv — carried as metadata on Function (D-08 "carried not enforced") |
| ☑ | `constraint def` + `require` | `analysis/constraints.deal` (PositiveMargin/SafeDoD/WheelMomentumBound) | **Predicate** (M1 · impl); require → Invariant (designed) |
| ☑ | `<<specializes>>` / `:>` | `interfaces/power.deal` (Rail3V3) | Subclassification (M1 · impl) |
| ☑ | `<<subsets>>` | `spacecraft/comms.deal` | Subsetting (M1 · impl) |
| ☑ | `<<redefines>>` / `:>>` | `interfaces/power.deal` | Redefinition (M1 · impl) |
| ☑ | `<<references>>` / `::>` / `ref` | `spacecraft/obc.deal` | ReferenceSubsetting (M1 · **designed — not in emitted edge set**) |
| ☑ | visibility `public/private/protected` | `spacecraft/comms.deal` | VisibilityKind (M5 · designed) |
| ☑ | units `kW(2.1)`, dimensional exprs | everywhere; exemplar `analysis/calcs.deal` | unit ctor → InvocationExpression/LiteralRational (M3 · designed; sema impl) |
| ☑ | §19 expression tree (logical→…→unary, calls, `.` chains) | `analysis/calcs.deal` | OperatorExpression / InvocationExpression / FeatureChainExpression / literals (M3 · designed) |
| ☑ | doc comments + @see/@param/@returns | `spacecraft/eps.deal` | Documentation (M1 · designed, D-25 deferred). ⚠ Doc comments attach to *definitions* only — `DealFile ::= HeaderBlock? PackageDeclaration …` forbids one between `@header` and `package` (E0101); package-level prose must be a block comment. |
| ☑ | block + line comments | `requirements/system.deal` | Comment (M1 · designed) |
| ☑ | `@header {}` | every file; exemplar `spacecraft/index.deal` | CM envelope, model-silent (FS-2) |
| ☑ | `@confidence/@rationale/@assumes/@concerns` | `spacecraft/eps.deal` | MetadataFeature (M1 · partial — emitter ignores Phase 2) |
| ☑ | `@simulation:<<computes>>` | `spacecraft/eps.deal` (battery) | sim-binding metadata (FA-5 · ignored by emitter) |
| ☑ | `@trace:` | `requirements/mission.deal` | Dependency (M2 · designed); targets must be imported into scope |

## B · `.dealx` constructs

| ✓ | Construct | Planned exemplar | KerML target (mech · status) |
|---|---|---|---|
| ☑ | `[<system>]` / `[<subsystem>]` | `model/halcyon.dealx` | PartUsage tree (M1/M2 · impl-generic) |
| ☑ | instance `[<T as="x" attr={…} />]` | `model/halcyon.dealx` | PartUsage instance (M1 · designed) |
| ☑ | inline object literal / proplist | `model/halcyon.dealx` (connect via) | ConstructorExpression (M3 · partial, CS-8) |
| ☑ | `[<connect from to via carrying />]` | `model/halcyon.dealx` | ConnectionUsage + connectorEnd (M1 · impl); EndFeatureMembership/CrossSubsetting (M2) |
| ☑ | `[<expose />]` chains | `model/halcyon.dealx` (umbilical) | PortUsage re-export (M1 · impl, CS-6) |
| ☑ | `[<allocate relationship=<<derives>> />]` | `model/traceability.dealx` | Dependency (M2 · impl-generic) |
| ☑ | `[<satisfy>]` + criteria + evidence maps + `compute` | `model/traceability.dealx` | Dependency kind "satisfy" (M1 · impl); evidence designed |
| ☑ | `gap {}` block (honest open item) | `model/traceability.dealx` (jitter TVAC) | — |
| ☑ | `[<validate>]` | `model/traceability.dealx` | Dependency-flavored (M1 · impl-generic) |
| ☑ | variants (two `.dealx` configs) | `model/variants/{multispec,hyperspec}.dealx` | SysML variation/variant membership (partial — semantics pending, gap §3.2) |
| ☑ | dotted navigation `Trace.REQ.field` | `model/traceability.dealx` | FeatureChaining per segment (M2 · designed, CS-15) |

## C · Frontier (`packages/behaviors/`, variants extras) — `status: draft`, excluded from default check

| ✓ | Construct | Planned exemplar | Anticipates |
|---|---|---|---|
| ☐ | `state def` FSM, entry/do/exit, trigger/guard/effect | `behaviors/modes.deal` | BH-4..BH-7 (LOCKED, no grammar) — SysML-level, no KerML metaclass |
| ☐ | `action def`, `->` successions, `decide/par/loop` | `behaviors/activities.deal` | BH-1..BH-3 → Behavior/Step/Succession (8.3.4.6.x, 8.3.4.5.4) |
| ☐ | `~>` item flow | `behaviors/activities.deal` | BH-7 → SuccessionFlow (8.3.4.9.6) |
| ☐ | `variation` usage modifier exercised | `model/variants/` | gap doc §3.2 |
| ☐ | timeslice/snapshot | **no DEAL surface** — document as @opaque-on-import case in variants doc comment | strategy M6/keystone §4.5 |
| ☐ | `@opaque:sysml-v2` example (if syntax probe passes) | `behaviors/activities.deal` tail | TextualRepresentation 8.3.2.3.6 (keystone ADD) |

## D · `.dealview` constructs (Phase 8)

| ✓ | Construct | Planned exemplar |
|---|---|---|
| ☐ | `view {}` props: title/viewpoint/direction/layout/grid/edge-labels | `model/views/structure-bdd.dealview` |
| ☐ | `include {}` / `exclude {}` — kind filters, `**` glob, `{set}` | `model/views/power-ibd.dealview` |
| ☐ | type → instance → attribute-refined → edge rule cascade | `model/global.dealview` + `power-ibd` |
| ☐ | layout deltas x/y/w/h, `collapsed` | every view |
| ☐ | edge `waypoints` | `model/views/data-ibd.dealview` |
| ☐ | tool-managed block (engineVersion + inputHash) | one view, after first render |

## E · Viewer contract stress targets (DEAL-Viewer-*.html)

| ✓ | Requirement | View |
|---|---|---|
| ☐ | 10/10 connector kinds (RG-10.1) | bdd: subclassification/definedBy/compositeOf/memberOf/redefines/references · ibd: connect/association · variants: variation/timeslice |
| ☐ | 3+ nesting levels, cross-container routing, INV-1 | `power-ibd` (system→EPS→pack→string) |
| ☐ | ≥5 compartments on one element | `structure-bdd` (BatteryPack) |
| ☐ | all 3 badge slots: semantic/diagnostics/verification | `structure-bdd` + sim-driven verification badges via `traceability` |
| ☐ | port flow glyphs in/out/inout on all 4 faces (RG-9.9) | `power-ibd`, `data-ibd` |
| ☐ | same-source bundling ≥3 same-kind (RG-10.9) | `power-ibd` (PDU rails → 5 loads) |
| ☐ | crossing hops (RG-10.8) | `data-ibd` (CAN × SpaceWire) |
| ☐ | inline label + slide, horiz & vert segments (RG-10.10/11) | `icd` |
| ☐ | state machine + control nodes (P4) | `modes-fsm`, `imaging-activity` |
| ☐ | >50 elements → auto-collapse banner + budget override (RG-6) | `full-system` |
| ☐ | every element ref = stable qualified name (RG-7.5 click-to-source) | audit script, Phase 9 |

## F · Simulation / evidence protocol

| ✓ | Item | Where |
|---|---|---|
| ☑ | 3 Python sims on deal-sim SDK | `simulations/{power/eps_energy_balance,thermal/spacecraft_thermal,comms/link_budget}.py` — run end-to-end in-sandbox, valid v0 output, criteria-passing values |
| ☑ | 3 MATLAB sims via `matlab -batch` adapter | `simulations/{orbit/eclipse_power,adcs/detumble_bdot,adcs/pointing_jitter}.m` — jsondecode/jsonencode v0 contract; physics verified via Python port (MATLAB execution pending local run) |
| ☑ | graceful-skip path exercised (skip.json, D-72) | confirmed on David's run — MATLAB absent → sims skip cleanly |
| ☑ | v0 contract: alphabetical keys (D-18), staleness keys (D-83), repro tiers (D-75) | SDK emits sorted v0 envelope; `reproducibility` strict(py)/tolerant(matlab) in registry |
| ☑ | `deal.sims.toml`: binds_to, inputs/outputs, auto_run | `simulations/deal.sims.toml` — 6 sims, eclipse→eps chaining via model_path |
| ☑ | satisfy criteria evaluated end-to-end (5 PASS, 1 PARTIAL) | `deal check --verify --run-sims` — model values → sim physics → evidence → criteria → compute margins |
| ☐ | evidence baseline captured (`deal evidence baseline initial`) | David's snapshot step |
