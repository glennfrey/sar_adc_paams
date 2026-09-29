###############################################################################
# Makefile — SAR ADC PA-AMS Capstone Project
# Supports: Icarus (local/Mac), VCS-AD (Alpinum server), Xcelium (server)
###############################################################################

# Tool selection (override with: make TOOL=vcsad rnm)
TOOL := icarus

# Directories
RTL_DIR   := rtl
AMS_DIR   := ams
TB_DIR    := tb
UPF_DIR   := upf
BUILD_DIR := build
WAVE_DIR  := waves

# File lists
RTL_FILES := $(RTL_DIR)/sar_controller.v $(RTL_DIR)/dac_switch_array.v
RNM_FILES := $(AMS_DIR)/sampl_hold_rnm.v $(AMS_DIR)/comparator_rnm.v $(AMS_DIR)/vref_rnm.v

#-------------------------------------------------------------------------
# Icarus Verilog (local/Mac — RNM only, no UPF)
#-------------------------------------------------------------------------
.PHONY: icarus-rnm sim wave clean

icarus-rnm: $(BUILD_DIR)/tb_rnm.vvp
	@echo "[RUN] Icarus RNM simulation"
	@vvp $(BUILD_DIR)/tb_rnm.vvp

$(BUILD_DIR)/tb_rnm.vvp: $(RTL_FILES) $(RNM_FILES) $(RTL_DIR)/sar_adc_top_rnm.v $(TB_DIR)/tb_rnm.sv
	@mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	iverilog -g2012 -o $@ 		$(RTL_FILES) $(RNM_FILES) $(RTL_DIR)/sar_adc_top_rnm.v 		$(TB_DIR)/tb_rnm.sv

# Aliases
sim: icarus-rnm

wave: $(WAVE_DIR)/tb_rnm.vcd
	gtkwave $(WAVE_DIR)/tb_rnm.vcd &

#-------------------------------------------------------------------------
# VCS-AD (Alpinum server)
#-------------------------------------------------------------------------
.PHONY: vcsad-rnm vcsad-paams vcsad-ams vcsad-run

vcsad-rnm:
	@mkdir -p $(BUILD_DIR)/vcs_ad $(WAVE_DIR)
	./scripts/vcs_ad.sh rnm

vcsad-paams:
	@mkdir -p $(BUILD_DIR)/vcs_ad $(WAVE_DIR)
	./scripts/vcs_ad.sh paams

vcsad-ams:
	@mkdir -p $(BUILD_DIR)/vcs_ad $(WAVE_DIR)
	./scripts/vcs_ad.sh ams

vcsad-run: $(BUILD_DIR)/vcs_ad/simv
	cd $(BUILD_DIR)/vcs_ad && ./simv -l run.log

$(BUILD_DIR)/vcs_ad/simv:
	$(MAKE) vcsad-rnm

#-------------------------------------------------------------------------
# Xcelium AMS (Alpinum server fallback)
#-------------------------------------------------------------------------
.PHONY: xrun-rnm xrun-paams xrun-ams

xrun-rnm:
	@mkdir -p $(BUILD_DIR)/xrun_ams $(WAVE_DIR)
	./scripts/xrun_ams.sh rnm

xrun-paams:
	@mkdir -p $(BUILD_DIR)/xrun_ams $(WAVE_DIR)
	./scripts/xrun_ams.sh paams

xrun-ams:
	@mkdir -p $(BUILD_DIR)/xrun_ams $(WAVE_DIR)
	./scripts/xrun_ams.sh ams

#-------------------------------------------------------------------------
# Utility
#-------------------------------------------------------------------------
clean:
	rm -rf $(BUILD_DIR) $(WAVE_DIR) *.log
	@echo "[CLEAN] Build artifacts removed"

help:
	@echo "SAR ADC PA-AMS Capstone — Available Targets"
	@echo "============================================"
	@echo "Local (Icarus):"
	@echo "  make icarus-rnm     — RNM simulation (Mac/local)"
	@echo ""
	@echo "Server (VCS-AD):"
	@echo "  make vcsad-rnm      — RNM simulation"
	@echo "  make vcsad-paams    — Power-aware AMS with UPF"
	@echo "  make vcsad-ams      — Verilog-AMS simulation"
	@echo ""
	@echo "Server (Xcelium):"
	@echo "  make xrun-rnm       — RNM simulation"
	@echo "  make xrun-paams     — Power-aware AMS"
	@echo "  make xrun-ams       — Verilog-AMS simulation"
	@echo ""
	@echo "Utility:"
	@echo "  make clean          — Remove build artifacts"
	@echo "  make help           — Show this help"
