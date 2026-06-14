"""
X-band Downlink Link Budget — Eb/N0 margin and daily data volume.

Bound to: packages/spacecraft/comms.deal::XBandTransmitter
Annotation: @simulation:<<computes>> linkBudget

Invoked by `deal simulate link_budget`. Evaluates REQ_SYS_005 (>= 2.0 Gbit/day)
and reports the closing Eb/N0 margin. Declared inputs are model-derived (the
transmitter and antenna); ground-station figure of merit, pass geometry and
coding threshold are mission/ground constants.
"""

import math

from deal_sim import DealSimulation

BOLTZMANN_DBW = -228.6     # 10*log10(k), dBW/(K*Hz)
LINE_LOSS_DB = 1.0         # coax + connector loss, transmitter to antenna
SLANT_RANGE_KM = 1500.0    # worst-case slant range at 10 deg elevation
GROUND_GOVERT_DBK = 18.0   # ground station G/T (3 m X-band dish)
REQUIRED_EBN0_DB = 4.0     # OQPSK + LDPC threshold at target BER
PASS_DURATION_S = 420.0    # usable seconds per station pass
PASSES_PER_DAY = 4.0       # contacts per day, single ground station
LINK_AVAILABILITY = 0.7    # fraction of pass above the rate threshold


class LinkBudget(DealSimulation):
    """X-band downlink budget (stdlib-only)."""

    inputs = {
        "txPower_W": {"type": "Real", "unit": "W"},
        "antennaGain_dBi": {"type": "Real", "unit": "dBi"},
        "frequency_GHz": {"type": "Real", "unit": "GHz"},
        "symbolRate_sps": {"type": "Real", "unit": "Hz"},
    }

    outputs = {
        "ebno_dB": {"type": "Real", "unit": "dB"},
        "linkMargin_dB": {"type": "Real", "unit": "dB"},
        "dailyVolumeGbit": {"type": "Real", "unit": "Gbit"},
    }

    def run(self, inputs: dict) -> dict:
        freq_mhz = inputs["frequency_GHz"] * 1000.0

        eirp = (
            10.0 * math.log10(inputs["txPower_W"])
            + inputs["antennaGain_dBi"]
            - LINE_LOSS_DB
        )
        fspl = 32.45 + 20.0 * math.log10(SLANT_RANGE_KM) + 20.0 * math.log10(freq_mhz)
        c_over_n0 = eirp - fspl + GROUND_GOVERT_DBK - BOLTZMANN_DBW
        ebno = c_over_n0 - 10.0 * math.log10(inputs["symbolRate_sps"])
        margin = ebno - REQUIRED_EBN0_DB

        bits_per_pass = inputs["symbolRate_sps"] * PASS_DURATION_S * LINK_AVAILABILITY
        daily_gbit = bits_per_pass * PASSES_PER_DAY / 1.0e9

        return {
            "ebno_dB": round(ebno, 2),
            "linkMargin_dB": round(margin, 2),
            "dailyVolumeGbit": round(daily_gbit, 2),
        }


if __name__ == "__main__":
    LinkBudget.cli()
