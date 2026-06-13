# HALCYON — 6U Earth-Observation CubeSat (DEAL Showcase #2)

A full-coverage DEAL showcase: every `.deal`/`.dealx`/`.dealview` construct
exercised in one realistic spacecraft model, doubling as the canonical
translation source for the `deal view` browser app (diagrams + click-to-source).

Plan: `../../../DEAL-Showcase-CubeSat-Plan.html` · Coverage ledger: `COVERAGE.md`

## Mission sketch

6U CubeSat, sun-synchronous LEO ~550 km, pushbroom multispectral imager.
Subsystems: EPS (deployable arrays, Li-ion pack, PDU), ADCS (3 wheels,
3 magnetorquers, star tracker, IMU, sun sensors, GPS), COMMS (UHF TT&C,
X-band downlink), C&DH (OBC, mass memory), Payload (imager + data handler),
Thermal, Structure. Mission modes: Detumble → Safe → Nominal → Imaging →
Downlink (frontier state machine).

## Layout

| Path | Contents | Status |
|---|---|---|
| `packages/interfaces/` | power / data / RF / thermal ports & interfaces | core |
| `packages/spacecraft/` | part definitions for all subsystems | core |
| `packages/requirements/` | needs → mission → system requirement chain | core |
| `packages/use-cases/` | imaging pass, downlink, safe-mode | core |
| `packages/analysis/` | calc defs, constraint defs, return contracts | core |
| `packages/behaviors/` | mode FSM, imaging-pass activity (BH-1..BH-7) | **frontier** |
| `model/` | composition, variants, traceability + views | core |
| `simulations/` | 3 Python (deal-sim SDK) + 3 MATLAB sims | core |
| `test/data/` | TLE, radiometric cal, TVAC report (evidence refs) | core |

Frontier files are `status: draft`, excluded from `[workspace].packages`, and
anticipate locked-but-unlanded grammar (see plan §Phases 7).

## KerML mapping commentary

Doc comments throughout note how constructs normalize to KerML/SysML v2
(metaclass, mechanism, status), grounded in `DEAL-KerML-Mapping-Strategy.html`
and the gap analysis — first exemplar of each construct only; `COVERAGE.md`
indexes the exemplars.

## Gates

```sh
deal parse spec/examples/cubesat
deal check spec/examples/cubesat --simulations          # Phase 5+
deal check spec/examples/cubesat --verify --run-sims    # Phase 6+
deal fmt   spec/examples/cubesat --check
deal build --target sysml-v2 --validate                 # Phase 9
```
