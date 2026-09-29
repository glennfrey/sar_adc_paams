#!/bin/bash
###############################################################################
# xrun_ams.sh — Xcelium AMS Compilation Script for SAR ADC
#
# Xcelium is the Cadence mixed-signal simulator.
# Use this if VCS-AD is not available or has license issues.
#
# USAGE:
#   ./scripts/xrun_ams.sh rnm      # RNM simulation
#   ./scripts/xrun_ams.sh ams      # AMS simulation
#   ./scripts/xrun_ams.sh paams    # PA-AMS with UPF
###############################################################################

set -e

MODE=${1:-rnm}
TOP=""
UPF_OPT=""

# Source tool setup
# source /tools/cadence/xcelium/21.09.001/setup.sh 2>/dev/null || true

echo "=========================================="
echo " SAR ADC Xcelium AMS Compilation"
echo " Mode: $MODE"
echo "=========================================="

mkdir -p build/xrun_ams
mkdir -p waves

RTL_FILES="rtl/sar_controller.v rtl/dac_switch_array.v"
RNM_FILES="ams/sampl_hold_rnm.v ams/comparator_rnm.v ams/vref_rnm.v"
AMS_VA_FILES="ams/sampl_hold_ams.va ams/comparator_ams.va ams/dac_ams.va"

case $MODE in
    rnm)
        TOP="tb_rnm"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_rnm.v"
        xrun -sv             -timescale 1ns/1ps             -access +rwc             -linedebug             -makedir build/xrun_ams             -l build/xrun_ams/compile.log             $RTL_FILES $RNM_FILES tb/${TOP}.sv
        ;;

    ams)
        TOP="tb_ams"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_ams.v"
        xrun -sv -ams             -timescale 1ns/1ps             -access +rwc             -linedebug             -makedir build/xrun_ams             -l build/xrun_ams/compile.log             $RTL_FILES $AMS_VA_FILES tb/${TOP}.sv
        ;;

    paams)
        TOP="tb_paams"
        RTL_FILES="$RTL_FILES rtl/sar_adc_top_rnm.v"
        xrun -sv             -upf upf/sar_adc.upf             -timescale 1ns/1ps             -access +rwc             -linedebug             -makedir build/xrun_ams             -l build/xrun_ams/compile.log             $RTL_FILES $RNM_FILES tb/${TOP}.sv
        ;;

    *)
        echo "[ERROR] Unknown mode: $MODE"
        echo "Usage: $0 {rnm|ams|paams}"
        exit 1
        ;;
esac
