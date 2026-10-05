# SAR ADC PA-AMS Capstone Project

**Mixed-Signal Verification of an 8-bit SAR ADC using RNM, Verilog-AMS, UPF, and UVM-AMS**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

This is a **complete capstone project** demonstrating mixed-signal verification of an 8-bit Successive Approximation Register (SAR) ADC across four methodologies taught in the Alpinum PA-AMS/UPF/RNM course:

| Methodology | Scope | Files | Tool |
|-------------|-------|-------|------|
| **RNM** (Real Number Modeling) | Fast mixed-signal with real-valued nets | `ams/*_rnm.v` | Icarus / VCS / Xcelium |
| **SPICE-AMS** | Continuous-time analog (electrical discipline) | `ams/*.va` | VCS-AD / Xcelium AMS |
| **AMS-SV** | SystemVerilog testbench architecture | `tb/tb_paams.sv` | VCS-AD / Xcelium |
| **PA-AMS** | Power-aware with UPF 1801 | `upf/sar_adc.upf` + `tb/tb_paams.sv` | VCS-NLP / VCS-AD |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SAR ADC TOP LEVEL                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ Sample/Hold │───→│  Comparator │───→│ SAR Ctrl    │     │
│  │  (RNM/AMS)  │    │  (RNM/AMS)  │    │ (Digital)   │     │
│  └─────────────┘    └──────┬──────┘    └──────┬──────┘     │
│         ↑                  │                   │            │
│         └──────────────────┘                   │            │
│         v_in (real/electrical)          dac_ctrl           │
│                                              ↓             │
│                                         ┌─────────┐        │
│                                         │   DAC   │        │
│                                         │(RNM/AMS)│        │
│                                         └────┬────┘        │
│                                              │             │
│  Power Domains (UPF):                        │             │
│  ├─ PD_TOP  (always-on) ← v_ref ────────────┘             │
│  ├─ PD_ANA  (S/H, Comp, DAC) — switchable                 │
│  └─ PD_DIG  (SAR Ctrl) — switchable + retention           │
└─────────────────────────────────────────────────────────────┘
```

### Signal Flow
1. **Sample phase**: `sample_en` high → S/H captures `v_in`
2. **Convert phase**: 8 cycles of binary search
   - SAR sets trial bit → DAC generates `v_dac`
   - Comparator: `comp_out = (v_sample > v_dac)`
   - SAR updates bit (keep if `comp_out=1`, clear if `0`)
3. **Done**: 8-bit result available on `adc_out`

---

## File Structure

```
sar_adc_paams/
├── rtl/                          # Digital RTL
│   ├── sar_controller.v          # SAR FSM controller
│   ├── dac_switch_array.v        # Binary-weighted DAC (RNM)
│   ├── sar_adc_top_rnm.v         # Top-level RNM integration
│   └── sar_adc_top_ams.v         # Top-level AMS integration
├── ams/                          # Analog models (dual view)
│   ├── sampl_hold_rnm.v          # S/H — SV-RNM (real nets)
│   ├── comparator_rnm.v          # Comparator — SV-RNM
│   ├── vref_rnm.v                # Reference voltage — RNM
│   ├── sampl_hold_ams.va         # S/H — Verilog-AMS
│   ├── comparator_ams.va         # Comparator — Verilog-AMS
│   └── dac_ams.va                # DAC — Verilog-AMS
├── upf/                          # Power intent
│   └── sar_adc.upf               # UPF 1801 (PDs, switches, isolation, retention)
├── tb/                           # Testbenches
│   ├── tb_rnm.sv                 # Functional RNM testbench
│   └── tb_paams.sv               # Power-aware AMS testbench
├── scripts/                      # Tool scripts
│   ├── vcs_ad.sh                 # VCS-AD compilation
│   └── xrun_ams.sh               # Xcelium AMS compilation
├── Makefile
└── README.md                     # This file
```

---

## Quick Start

### Local (Mac / Linux with Icarus)

```bash
# RNM simulation only (no UPF, no Verilog-AMS)
make icarus-rnm        # Compiles with Icarus, runs testbench
make wave              # Open GTKWave (if installed)
```

**Requirements**: `iverilog`, `vvp`, `gtkwave` (optional)

---

## Server Execution (Alpinum)

### Can we run VCS-AD on the Alpinum server?

**Yes — VCS-AD is available**, but with important caveats:

| Tool | Status | Notes |
|------|--------|-------|
| **VCS-AD** | ✅ Available | Mixed-signal VCS (digital + analog solver). Supports RNM and Verilog-AMS. |
| **VCS-NLP** | ❌ No license | Native Low Power (UPF-aware simulation) requires a separate license that Alpinum **does not have**. Confirmed by Abdelrahman Ali (Alpinum support). |
| **Xcelium** | ✅ Available | Cadence simulator with AMS and UPF support. Use as fallback for PA-AMS. |

### What this means for the capstone:

- **RNM simulation**: ✅ Runs on VCS-AD, Xcelium, or Icarus
- **Verilog-AMS**: ✅ Runs on VCS-AD or Xcelium AMS
- **PA-AMS with UPF**: ⚠️ **UPF-aware simulation** (power switch modeling, isolation verification) requires either:
  - VCS-NLP (not available)
  - Xcelium with UPF option (check availability)
  - **Workaround**: The `tb_paams.sv` testbench manually drives power control signals (`pwr_en_ana`, `pwr_en_dig`, `retain_en`) to **demonstrate the power sequencing and retention concepts** even without UPF-aware simulation.

### Running on the Alpinum Server

```bash
ssh user@alpinum_server_ip
cd ~/sar_adc_paams

# Source tool environment (adjust paths as needed)
source /tools/synopsys/vcs/S-2021.09-SP1/etc/setup/vcs_setup.sh

# Option 1: RNM simulation (fast, no analog solver)
make vcsad-rnm
./build/vcs_ad/simv

# Option 2: Verilog-AMS simulation (SPICE-accurate analog)
make vcsad-ams
./build/vcs_ad/simv

# Option 3: PA-AMS with UPF (if Xcelium has UPF license)
source /tools/cadence/xcelium/21.09.001/setup.sh
make xrun-paams
```

---

## Verification Coverage

### RNM Testbench (`tb_rnm.sv`)
- ✅ Functional conversion at 0V, 0.45V, 0.9V, 1.35V, 1.8V
- ✅ Near-LSB input (7mV) for resolution check
- ✅ ±1 LSB error tolerance

### PA-AMS Testbench (`tb_paams.sv`)
- ✅ Power-up sequencing (VDD_TOP → VDD_ANA → VDD_DIG)
- ✅ Normal conversion with all domains ON
- ✅ Analog domain power gating (shutdown between conversions)
- ✅ Isolation check (analog outputs clamped when PD_ANA off)
- ✅ Digital retention (SAR state save/restore during PD_DIG shutdown)
- ✅ Full standby → wake → convert recovery
- ✅ SV Assertions:
  - No `start` when PD_DIG is OFF
  - No `done` when PD_DIG is OFF
  - Power-up sequence: PD_ANA before PD_DIG

---

## Key Concepts Demonstrated

### 1. RNM (Real Number Modeling)
```systemverilog
// Analog voltage as a real net — no SPICE solver needed
real v_sample;
assign v_dac = (real'(dac_ctrl) / 256.0) * 1.8;
```
- **Speed**: 10-100× faster than SPICE-AMS
- **Use case**: Architectural validation, control loop verification, PA-AMS

### 2. Verilog-AMS (SPICE-AMS)
```verilog
// Continuous-time analog with electrical discipline
analog begin
    V(v_out) <+ v_sampled;  // Drive voltage source
end
```
- **Accuracy**: SPICE-level transistor behavior (with device models)
- **Use case**: IP characterization, noise analysis, power verification

### 3. UPF 1801 (Power Intent)
```tcl
# Power domains with switches, isolation, retention
create_power_domain PD_ANA -elements {u_sah u_comp u_dac};
create_power_switch SW_ANA -domain PD_TOP ...;
set_isolation ISO_ANA_OUT -domain PD_DIG -clamp_value 0;
set_retention RET_SAR_CTRL -domain PD_DIG ...;
```

### 4. AMS-SV Testbench Architecture
```systemverilog
// Mixed-signal UVM-style testbench
// - Analog stimulus: real-valued voltage sweeps
// - Digital control: power sequencing, retention
// - Assertions: power-state aware checks
```

---

## Course Coverage Matrix

| Alpinum Course Module | Files | Status |
|-----------------------|-------|--------|
| **Session 1: Mixed-Signal Verification Overview** | All | ✅ Architecture + use cases documented |
| **Session 2: RNM + UPF + VCS-AD Flow** | `ams/*_rnm.v`, `upf/sar_adc.upf`, `scripts/vcs_ad.sh` | ✅ RNM models + UPF + compile script |
| **Session 3: UVM-AMS + Verdi Debugging** | `tb/tb_paams.sv` | ✅ AMS-SV TB structure (UVM-AMS skeleton) |
| **Session 4: SPICE-AMS Co-Simulation** | `ams/*.va` | ✅ Verilog-AMS models + VCS-AD AMS mode |
| **Session 5: Advanced PA-AMS** | `tb/tb_paams.sv` (retention, sequencing) | ✅ Retention + isolation + recovery tests |

---

## Known Limitations

1. **SAR controller is simplified**: In a real design, the comparator result would be registered after a setup/hold window. Here it's updated on the clock edge for simulation simplicity.
2. **DAC is ideal**: No mismatch, INL, or DNL modeling. Can be extended with statistical variation.
3. **No noise or jitter**: The RNM/AMS models are noiseless. Add `$random` jitter or flicker noise for advanced verification.
4. **UPF is not simulated on VCS-AD without NLP**: The UPF file is syntactically correct UPF 1801, but power-switch behavior requires VCS-NLP or Xcelium with low-power license. The testbench drives power controls manually as a fallback.

---

## Extension Ideas

To deepen this capstone:
- [ ] Add **INL/DNL measurement** to the testbench
- [ ] Model **comparator offset and metastability** in RNM
- [ ] Add ** Monte Carlo mismatch** to the DAC
- [ ] Implement **UVM agent** for the ADC (sequence: `random_voltage_seq`, `power_gating_seq`)
- [ ] Add **FSDB dumping** for Verdi AMS debug
- [ ] Create **power report**: average current per domain

---

## License

MIT License — open-source for portfolio use.

---

## Author

**Glenn Frey Olamit** — Senior Design Engineer candidate  
Mixed-signal verification project for Alpinum PA-AMS / UPF / RNM course


## Certificates

- [CoC Mixed Signal Verilog-AMS, RNM](CoC%20Glenn%20Frey%20Olamit%20RNM.pdf)
- [CoC Power Aware-AMS](CoC%20Glenn%20Frey%20Olamit%20Power-aware.pdf)
