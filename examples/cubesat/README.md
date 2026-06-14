# HALCYON — 6U Earth-Observation CubeSat (DEAL Showcase #2)

A full-coverage DEAL example: every `.deal` / `.dealx` / `.dealview` construct
exercised in one realistic spacecraft model, with a working simulation →
evidence → verification loop, and authored to double as the translation source
for the `deal view` browser app (diagrams + click-to-source).

Plan: [`../../../DEAL-Showcase-CubeSat-Plan.html`](../../../DEAL-Showcase-CubeSat-Plan.html)
· Coverage ledger: [`COVERAGE.md`](COVERAGE.md)

## Mission

HALCYON is a 6U CubeSat in a sun-synchronous ~550 km LEO carrying a 4-band
pushbroom multispectral imager. Subsystems: **EPS** (deployable arrays, Li-ion
pack, PDU with switched rails), **ADCS** (3 reaction wheels, 3 magnetorquers,
star tracker, IMU, sun sensors, GPS), **COMMS** (UHF TT&C, X-band downlink),
**C&DH** (OBC, mass memory), **Payload** (imager + data handler), **Thermal**
(heaters, radiator, thermistors), **Structure** (6U frame, deployment switches).
Mission modes: `Detumble → Safe → Nominal → {Imaging | Downlink}`, fault to Safe.

## Layout

| Path | Contents |
|---|---|
| `packages/interfaces/` | power / data / RF / thermal ports, interfaces, harnesses |
| `packages/spacecraft/` | ~30 part definitions for every subsystem + `Halcyon` system def |
| `packages/requirements/` | needs → mission → system requirement chain (all 4 verification methods) |
| `packages/use-cases/` | imaging / downlink / safe-mode + `actor def`s |
| `packages/analysis/` | `calc def`s + `constraint def`s with SD-23 return contracts |
| `packages/behaviors/` | **frontier** — mode FSM + imaging activity (BH-1..BH-7, ahead of grammar) |
| `model/` | `halcyon.dealx` composition, variants, `traceability.dealx`, `.dealview` views |
| `simulations/` | 3 Python (deal-sim SDK) + 3 MATLAB sims + `deal.sims.toml` |
| `test/data/` | TLE / radiometric cal / TVAC report (evidence references) |

## Running it

```sh
# Parse + semantic/dimensional check (behaviors excluded via [workspace].exclude)
deal check .

# Run the simulation chain (Python always; MATLAB needs `matlab` on PATH),
# then evaluate the satisfy criteria against captured evidence
deal simulate --all
deal check --verify --run-sims
deal evidence baseline initial

# Build targets
deal build --target sysml-v2 --validate
deal build --target reqif

# Format check, and the frontier diagnostics (expected to fail — see below)
deal fmt packages/**/*.deal --check
deal parse packages/behaviors/*.deal
```

`deal check --verify` reports **5 PASS, 1 PARTIAL**. The PARTIAL is REQ_SYS_002
(pointing) — by design: the criterion *passes* (RMS jitter 0.024° ≤ 0.1°) but the
requirement carries `status="partial"` and an honest `gap` block (TVAC pointing
correlation pending), so it is reported as not-fully-verified. That is the
traceability story the example is meant to tell: verified requirements *and* a
tracked open item.

## What it demonstrates

- **Language coverage** — every construct in `COVERAGE.md`: parts/ports/
  interfaces, requirements with verification contracts, use cases with
  `actor def`s, `calc`/`constraint def`s with `=> ± / sig N` return contracts,
  the full `.dealx` composition surface (system/subsystem/instance/connect/
  expose/allocate/satisfy/gap/validate/variants), and the frontier behavior
  syntax written ahead of the grammar.
- **KerML/SysML v2 mapping** — first-exemplar doc comments throughout cite the
  target metaclass, mapping mechanism (M1–M6), and clause, per
  `DEAL-KerML-Mapping-Strategy.html`.
- **Simulation + evidence** — realistic physics (orbit eclipse, EPS energy
  balance, lumped thermal, X-band link budget, B-dot detumble, wheel jitter)
  bound to the model via `deal.sims.toml`, with `eclipse_power → eps_energy_balance`
  chaining; evidence drives the satisfy criteria and verification badges.
- **Viewer payload** — 11 `.dealview` files exercising every layout/connector/
  badge contract from `DEAL-Viewer-*.html` (all 10 connector kinds, ≥5
  compartments, port glyphs, same-source bundling, crossing hops, sliding
  labels, waypoints, the >50-element auto-collapse, and stable qualified-name
  references for click-to-source).

## Honest gaps / notes

- **Frontier behaviors** (`packages/behaviors/`) are written to the locked
  BH-1..BH-7 designs and **do not parse on today's grammar** (expected:
  `modes.deal` → E0100, `activities.deal` → E0120). They are `status: draft`
  and excluded from `deal check` via `[workspace].exclude`. Check them
  explicitly with `deal parse packages/behaviors/*.deal`.
- **`.dealview` files** are authored to `dealview.ebnf` + the viewer contracts.
  The current CLI has no `.dealview` parser (it is view-state for the future
  `deal view` app), so they are not validated by `deal check`.
- The `variation` usage *modifier* is not exercised — variants are shown as
  full config files (`multispec` / `hyperspec`) instead.
- Building this example surfaced and fixed several CLI issues (stdlib loading,
  the `actor def` construct, MATLAB dispatch, signed-literal and evidence-key
  resolution, verify path handling, `[workspace].exclude`) — dogfooding a
  flagship example is part of the point.
