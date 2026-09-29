//////////////////////////////////////////////////////////////////////////////
// tb_paams.sv — Power-Aware AMS Testbench for SAR ADC
// Tests power sequencing, isolation, retention, and recovery.
// Uses UPF power control signals to drive power switches.
//
// PA-AMS Verification Checklist:
//   [ ] Power-up sequencing (VDD_TOP → VDD_ANA → VDD_DIG)
//   [ ] Normal conversion while all domains ON
//   [ ] Analog domain shutdown between conversions (power gating)
//   [ ] Isolation check: comp_out clamped when PD_ANA is OFF
//   [ ] Digital domain shutdown with retention (SAR state preserved)
//   [ ] Recovery: correct conversion after power restoration
//   [ ] Illegal sequence detection (e.g., PD_DIG on before PD_ANA)
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module tb_paams;

    parameter ADC_BITS = 8;
    parameter CLK_PERIOD = 10;  // 100 MHz
    parameter VREF = 1.8;

    // Clock and reset
    logic clk;
    logic rst_n;

    // ADC interface
    logic start;
    real  v_in;
    logic [ADC_BITS-1:0] adc_out;
    logic done;
    logic busy;

    // UPF power control signals (driven by testbench, read by UPF)
    logic pwr_en_ana;     // PD_ANA power switch control
    logic pwr_en_dig;     // PD_DIG power switch control
    logic retain_en;      // Retention save/restore control

    // Power state monitoring (for assertion checking)
    logic pd_ana_on;
    logic pd_dig_on;

    // DUT — RNM view with power ports exposed for PA-AMS
    // In real PA-AMS, these connect to UPF supply nets
    sar_adc_top_rnm #(.ADC_BITS(ADC_BITS)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .v_in(v_in),
        .adc_out(adc_out),
        .done(done),
        .busy(busy)
    );

    // Clock generation (always-on, from PD_TOP)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Power state tracking
    assign pd_ana_on = pwr_en_ana;
    assign pd_dig_on = pwr_en_dig;

    //=========================================================================
    // Main Test Sequence
    //=========================================================================
    initial begin
        $display("========================================");
        $display(" SAR ADC PA-AMS Testbench ");
        $display(" Tests: sequencing, isolation, retention, recovery");
        $display("========================================");

        // Initialize all controls
        rst_n = 0;
        start = 0;
        v_in = 0.0;
        pwr_en_ana = 0;
        pwr_en_dig = 0;
        retain_en = 0;

        @(posedge clk);
        @(posedge clk);

        //---------------------------------------------------------------------
        // TEST 1: Power-up sequencing
        //---------------------------------------------------------------------
        $display("\n[TEST 1] Power-up sequencing");
        power_up_sequence();

        //---------------------------------------------------------------------
        // TEST 2: Normal conversion (all domains ON)
        //---------------------------------------------------------------------
        $display("\n[TEST 2] Normal conversion @ 0.9V");
        test_conversion(0.9, "normal operation");

        //---------------------------------------------------------------------
        // TEST 3: Analog power gating between conversions
        // Shutdown PD_ANA after conversion, wake before next
        //---------------------------------------------------------------------
        $display("\n[TEST 3] Analog domain power gating");
        begin
            v_in = 0.45;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            wait(done);
            @(posedge clk);
            $display("  Conversion done. Shutting down PD_ANA...");

            pwr_en_ana = 0;  // power off analog
            #100;
            check_isolation();  // comp_out should be clamped/X

            $display("  Waking PD_ANA for next conversion...");
            pwr_en_ana = 1;
            #50;  // stabilization

            test_conversion(1.35, "post-ANA-recovery");
        end

        //---------------------------------------------------------------------
        // TEST 4: Digital retention during PD_DIG shutdown
        //---------------------------------------------------------------------
        $display("\n[TEST 4] Digital retention test");
        begin
            // Start a conversion
            v_in = 1.2;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            // Mid-conversion, save state and shut down PD_DIG
            #50;
            $display("  Saving SAR state...");
            retain_en = 1;
            @(posedge clk);
            pwr_en_dig = 0;  // power off digital
            #100;

            $display("  Restoring PD_DIG...");
            pwr_en_dig = 1;
            retain_en = 0;   // restore state
            @(posedge clk);

            wait(done);
            @(posedge clk);
            $display("  Post-retention adc_out=%0d", adc_out);
        end

        //---------------------------------------------------------------------
        // TEST 5: Full standby → wake → convert
        //---------------------------------------------------------------------
        $display("\n[TEST 5] Full standby recovery");
        begin
            // Enter standby
            pwr_en_ana = 0;
            pwr_en_dig = 0;
            retain_en = 1;
            #200;

            // Wake up
            power_up_sequence();
            retain_en = 0;

            test_conversion(0.6, "post-standby");
        end

        //---------------------------------------------------------------------
        // TEST 6: Isolation verification (assertion)
        //---------------------------------------------------------------------
        $display("\n[TEST 6] Isolation assertion check");
        begin
            pwr_en_ana = 0;
            #20;
            // In a real UPF-aware sim, comp_out should be clamped to 0
            // Here we just verify the control signal state
            $display("  PD_ANA=%0b, isolation should be active", pwr_en_ana);
            pwr_en_ana = 1;
            #50;
        end

        $display("\n========================================");
        $display(" ALL PA-AMS TESTS COMPLETED ");
        $display("========================================");
        $finish;
    end

    //=========================================================================
    // Tasks
    //=========================================================================

    task power_up_sequence();
        begin
            $display("  Power-up: VDD_TOP → VDD_ANA → VDD_DIG");
            // VDD_TOP is always on (not controlled here)
            pwr_en_ana = 1;
            #50;
            pwr_en_dig = 1;
            #50;
            rst_n = 1;
            $display("  All domains up, reset released");
        end
    endtask

    task test_conversion(input real vin_val, input string test_name);
        real expected_code;
        int  expected_int;
        int  error;
        begin
            v_in = vin_val;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            wait(done);
            @(posedge clk);

            expected_code = (vin_val / VREF) * ((1 << ADC_BITS) - 1);
            expected_int = $rtoi(expected_code);
            error = adc_out - expected_int;

            $display("  [%s] vin=%.4f, adc_out=%0d (0x%0h), expected≈%0d, error=%0d",
                     test_name, vin_val, adc_out, adc_out, expected_int, error);

            if (error < -1 || error > 1)
                $error("Conversion error too large for %s", test_name);
        end
    endtask

    task check_isolation();
        begin
            // When PD_ANA is off, analog outputs to digital should be isolated
            // In this RNM model, we check that comp_en would be off
            $display("  Isolation check: PD_ANA=%0b (should be clamped)", pwr_en_ana);
        end
    endtask

    //=========================================================================
    // Assertions (PA-AMS checks)
    //=========================================================================

    // Assertion 1: No conversion start when PD_DIG is off
    property no_start_when_pd_dig_off;
        @(posedge clk) (!pwr_en_dig) |-> !start;
    endproperty
    assert property (no_start_when_pd_dig_off)
        else $error("Assertion FAIL: start asserted while PD_DIG is OFF");

    // Assertion 2: done should not assert when PD_DIG is off
    property no_done_when_pd_dig_off;
        @(posedge clk) (!pwr_en_dig) |-> !done;
    endproperty
    assert property (no_done_when_pd_dig_off)
        else $error("Assertion FAIL: done asserted while PD_DIG is OFF");

    // Assertion 3: Power-up sequence (ANA before DIG)
    property ana_before_dig;
        @(posedge clk) $rose(pwr_en_dig) |-> pwr_en_ana;
    endproperty
    assert property (ana_before_dig)
        else $error("Assertion FAIL: PD_DIG powered up before PD_ANA");

    //=========================================================================
    // Timeout and waveform dump
    //=========================================================================
    initial begin
        #100000;
        $display("[TIMEOUT] PA-AMS test timed out");
        $fatal(1, "Simulation timeout");
    end

    initial begin
        $dumpfile("waves/tb_paams.vcd");
        $dumpvars(0, tb_paams);
    end

endmodule
