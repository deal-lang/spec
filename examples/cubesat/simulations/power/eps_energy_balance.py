"""
EPS Orbit Energy Balance — orbit-averaged power budget and battery DoD.

Bound to: packages/spacecraft/eps.deal::BatteryPack
Annotation: @simulation:<<computes>> energyBalance

Invoked by `deal simulate eps_energy_balance`. Evaluates REQ_SYS_003
(power-positive) and REQ_SYS_004 (depth-of-discharge). The eclipse fraction
and orbit period are produced by orbit/eclipse_power.m and chained in through
the model (Halcyon.eclipseFraction / Halcyon.orbitPeriod).

Declared inputs are all model-derived; the charge-path round-trip efficiency
is a fixed EPS characteristic.
"""

from deal_sim import DealSimulation

CHARGE_EFFICIENCY = 0.85  # battery charge/discharge round-trip (EPS spec)


class EpsEnergyBalance(DealSimulation):
    """Sunlit/eclipse energy balance over one orbit (stdlib-only)."""

    inputs = {
        "arrayPowerEOL_W": {"type": "Real", "unit": "W"},
        "orbitAvgLoad_W": {"type": "Real", "unit": "W"},
        "eclipseFraction": {"type": "Real", "unit": ""},
        "orbitPeriod_s": {"type": "Real", "unit": "s"},
        "usableCapacity_Wh": {"type": "Real", "unit": "Wh"},
    }

    outputs = {
        "orbitEnergyMargin": {"type": "Real", "unit": "Wh"},
        "depthOfDischarge": {"type": "Real", "unit": ""},
    }

    def run(self, inputs: dict) -> dict:
        period_h = inputs["orbitPeriod_s"] / 3600.0
        sunlit_frac = 1.0 - inputs["eclipseFraction"]

        generated_wh = (
            inputs["arrayPowerEOL_W"] * sunlit_frac * period_h * CHARGE_EFFICIENCY
        )
        consumed_wh = inputs["orbitAvgLoad_W"] * period_h
        margin_wh = generated_wh - consumed_wh

        eclipse_energy_wh = (
            inputs["orbitAvgLoad_W"] * inputs["eclipseFraction"] * period_h
        )
        dod = eclipse_energy_wh / inputs["usableCapacity_Wh"]

        return {
            "orbitEnergyMargin": round(margin_wh, 2),
            "depthOfDischarge": round(dod, 4),
        }


if __name__ == "__main__":
    EpsEnergyBalance.cli()
