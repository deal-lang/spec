"""
Battery Thermal Model — Lumped-parameter analysis.

Bound to: packages/vehicle/battery.deal::BatteryPack
Annotation: @simulation:<<computes>> thermalProfile

This simulation is invoked by `deal simulate battery_thermal`.
The DEAL CLI generates input.json from the model, runs this script,
and reads output.json back to evaluate verification criteria.
"""

from deal_sim import DealSimulation


class BatteryThermal(DealSimulation):
    """Lumped-parameter battery thermal model with coolant loop."""

    inputs = {
        "packResistance": {"type": "Real", "unit": "ohm"},
        "totalCurrent": {"type": "Real", "unit": "A"},
        "coolantFlowRate": {"type": "Real", "unit": "L/min"},
    }

    outputs = {
        "heatGenerated": {"type": "Real", "unit": "W"},
        "coolantOutTemp": {"type": "Real", "unit": "degC"},
    }

    def run(self, inputs: dict) -> dict:
        """
        Compute battery heat generation and coolant outlet temperature.

        Physics:
            Q_gen = I² × R                           (Joule heating)
            ΔT = Q_gen / (ṁ × Cp)                   (energy balance)
            T_out = T_in + ΔT                        (outlet temp)
        """
        # I²R losses
        heat_generated = inputs["totalCurrent"] ** 2 * inputs["packResistance"]

        # Coolant energy balance
        coolant_density = 1.06  # kg/L for glycol-water 50/50
        coolant_cp = 3500.0  # J/(kg·K)
        coolant_inlet_temp = 20.0  # °C — from model in production

        mass_flow_rate = inputs["coolantFlowRate"] * coolant_density / 60.0  # kg/s
        delta_t = heat_generated / (mass_flow_rate * coolant_cp)
        coolant_out_temp = coolant_inlet_temp + delta_t

        return {
            "heatGenerated": round(heat_generated, 1),
            "coolantOutTemp": round(coolant_out_temp, 2),
        }


# deal_sim.DealSimulation provides:
#   - CLI runner (reads input.json, writes output.json)
#   - Input validation against declared schema
#   - Output validation against declared schema
#   - Metadata generation (timestamp, duration, tool version)
if __name__ == "__main__":
    BatteryThermal.cli()
