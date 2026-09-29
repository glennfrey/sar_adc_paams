#!/bin/bash
###############################################################################
# vcs_ad.sh — VCS-AD (Analog/Digital) Compilation Script for SAR ADC
#
# VCS-AD supports TWO modes of mixed-signal simulation:
#
# 1. Verilog-AMS Behavioral (default):
#    Digital Verilog/SystemVerilog + Verilog-AMS behavioral models
#    (electrical discipline, analog begin/end blocks)
#    Fast, equation-based analog solver
#
# 2. SPICE-AMS Co-Simulation (requires FineSim/CustomSim license):
#    Digital Verilog/SystemVerilog + SPICE transistor netlists (.sp)
#    Accurate, SPICE-level device simulation
#    Requires: VCS + CustomSim/FineSim + connect modules
#
# USAGE:
#   ./scripts/vcs_ad.sh rnm              # RNM-only (fastest)
#   ./scripts/vcs_ad.sh ams              # Verilog-AMS behavioral
#   ./scripts/vcs_ad.sh spiceams         # SPICE-AMS (SPICE netlists for analog)
#   ./scripts/vcs_ad.sh paams            # Power-aware AMS (UPF + RNM/AMS)
###############################################################################

set -e

MODE=${1:-rnm}
TOP=""
UPF_OPT=""
AMS_FILES=""
SPICE_FILES=""

echo "=========================================="
echo " SAR ADC VCS-AD Compilation"
echo " Mode: $MODE"
echo "=========================================="

mkdir -p build/vcs_ad
mkdir -p waves

# Source tool environment (adjust paths for your server)
# source /tools/synopsys/vcs/S-2021.09-SP1/etc/setup/vcs_setup.sh 2>/dev/null || true
# source /tools/synopsys/customsim/S-2021.09/etc/setup/customsim_setup.sh 2>/dev/null || true

RTL_FILES="rtl/sar_controller.v rtl/dac_switch_array.v"
RNM_FILES="ams/sampl_hold_rnm.v ams/comparator_rnm.v ams/vref_rnm.v"
AMS_VA_FILES="ams/sampl_hold_ams.va ams/comparator_ams.va ams/dac_ams.va"
SPICE_NETLISTS="ams/sampl_hold.sp ams/comparator.sp ams/dac.sp"

#-------------------------------------------------------------------------
# Mode selection
#-------------------------------------------------------------------------
case $MODE in
    rnm)
        echo "[INFO] RNM mode: real-number modeling, no analog solver"
        echo "       Digital Verilog + real-valued nets (fast)"
        TOP="tb_rnm"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_rnm.v"
        ;;

    ams)
        echo "[INFO] AMS mode: Verilog-AMS behavioral analog"
        echo "       Digital Verilog + Verilog-AMS (electrical discipline)"
        TOP="tb_ams"
        AMS_FILES="-ams $AMS_VA_FILES"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_ams.v"
        ;;

    spiceams)
        echo "[INFO] SPICE-AMS mode: SPICE transistor netlists for analog"
        echo "       Digital Verilog + SPICE (.sp) via CustomSim/FineSim"
        echo "       Requires: FineSim license + connect modules"
        TOP="tb_ams"  # same top, but analog blocks from SPICE
        # For SPICE-AMS, we exclude Verilog-AMS files and include SPICE netlists
        # VCS-AD with CustomSim uses -ad=spice or -ams with SPICE config
        SPICE_FILES="-ad=spice $SPICE_NETLISTS"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_ams.v"
        ;;

    paams)
        echo "[INFO] PA-AMS mode: RNM + UPF power intent"
        echo "       Power-aware simulation (UPF file loaded)"
        echo "       NOTE: Full power-switch modeling requires VCS-NLP license"
        echo "             This run demonstrates UPF loading + manual power control"
        TOP="tb_paams"
        UPF_OPT="-upf upf/sar_adc.upf"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_rnm.v"
        ;;

    *)
        echo "[ERROR] Unknown mode: $MODE"
        echo "Usage: $0 {rnm|ams|spiceams|paams}"
        exit 1
        ;;
esac

#-------------------------------------------------------------------------
# VCS-AD compilation
#-------------------------------------------------------------------------
echo "[INFO] Compiling with VCS-AD..."
echo "       RTL:  $RTL_FILES"
echo "       RNM:  $RNM_FILES"
echo "       AMS:  $AMS_FILES"
echo "       SPICE: $SPICE_FILES"
echo "       UPF:  $UPF_OPT"

vcs -full64     -sverilog     -ad=vcsad     -timescale=1ns/1ps     $AMS_FILES     $SPICE_FILES     $UPF_OPT     -debug_access+all     -kdb     +vpi     +v2k     -Mdir=build/vcs_ad/csrc     -o build/vcs_ad/simv     -l build/vcs_ad/compile.log     $RTL_FILES     $RNM_FILES     tb/${TOP}.sv

echo "[INFO] Compilation complete: build/vcs_ad/simv"
echo "[INFO] Run with: ./build/vcs_ad/simv"
