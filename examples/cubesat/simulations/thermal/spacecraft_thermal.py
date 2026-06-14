"""
Spacecraft Thermal — reduced battery-node temperature, hot and cold cases.

Bound to: packages/spacecraft/thermal.deal::HeaterCircuit
Annotation: @simulation:<<computes>> thermalBalance

Invoked by `deal simulate spacecraft_thermal`. Evaluates REQ_SYS_006 (battery
0..45 degC). Reduced from the 6-node lumped network to the battery node: the
detailed orbital model supplies hot/cold radiator sink temperatures; the
battery sits a thermal resistance away and self-heats with its own
dissipation; the survival heater clamps the cold-case floor.

Declared inputs are model-derived; idle fraction, strap conductance and heater
setpoint are fixed design characteristics.
"""

from deal_sim import DealSimulation

IDLE_FRACTION = 0.4       # eclipse idle dissipation vs imaging-duty dissipation
COUPLING_K_W = 1.5        # battery-to-radiator thermal resistance, K/W
HEATER_SETPOINT_C = 2.0   # survival heater operational floor


class SpacecraftThermal(DealSimulation):
    """Battery hot/cold temperatures from radiator sink + self-heating."""

    inputs = {
        "batteryDissipation_W": {"type": "Real", "unit": "W"},
        "hotSinkTemp_C": {"type": "Real", "unit": "degC"},
        "coldSinkTemp_C": {"type": "Real", "unit": "degC"},
    }

    outputs = {
        "batteryMaxTemp": {"type": "Real", "unit": "degC"},
        "batteryMinTemp": {"type": "Real", "unit": "degC"},
    }

    def run(self, inputs: dict) -> dict:
        diss = inputs["batteryDissipation_W"]

        battery_max = inputs["hotSinkTemp_C"] + diss * COUPLING_K_W
        battery_min_raw = inputs["coldSinkTemp_C"] + diss * IDLE_FRACTION * COUPLING_K_W
        battery_min = max(HEATER_SETPOINT_C, battery_min_raw)

        return {
            "batteryMaxTemp": round(battery_max, 2),
            "batteryMinTemp": round(battery_min, 2),
        }


if __name__ == "__main__":
    SpacecraftThermal.cli()
