#!/usr/bin/env python3
"""
check_project.py — Verify SAR ADC PA-AMS project structure and file completeness
Run before committing: python3 scripts/check_project.py
"""
import os
import sys

CHECKLIST = {
    "RTL Files": [
        "rtl/sar_controller.v",
        "rtl/dac_switch_array.v",
        "rtl/sar_adc_top_rnm.v",
        "rtl/sar_adc_top_ams.v",
    ],
    "RNM Models": [
        "ams/sampl_hold_rnm.v",
        "ams/comparator_rnm.v",
        "ams/vref_rnm.v",
    ],
    "Verilog-AMS Models": [
        "ams/sampl_hold_ams.va",
        "ams/comparator_ams.va",
        "ams/dac_ams.va",
    ],
    "UPF": [
        "upf/sar_adc.upf",
    ],
    "Testbenches": [
        "tb/tb_rnm.sv",
        "tb/tb_paams.sv",
    ],
    "Scripts": [
        "scripts/vcs_ad.sh",
        "scripts/xrun_ams.sh",
        "scripts/check_project.py",
    ],
    "Build": [
        "Makefile",
        "README.md",
        ".gitignore",
    ],
}

def main():
    all_ok = True
    total = 0
    found = 0

    for category, files in CHECKLIST.items():
        print(f"\n{category}:")
        for f in files:
            total += 1
            if os.path.exists(f):
                size = os.path.getsize(f)
                print(f"  ✅ {f} ({size} bytes)")
                found += 1
            else:
                print(f"  ❌ {f} MISSING")
                all_ok = False

    print(f"\n{'='*50}")
    print(f"Total: {found}/{total} files present")
    if all_ok:
        print("Project structure is COMPLETE ✅")
        return 0
    else:
        print("Project structure has MISSING FILES ❌")
        return 1

if __name__ == "__main__":
    sys.exit(main())
