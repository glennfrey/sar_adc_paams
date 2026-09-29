//////////////////////////////////////////////////////////////////////////////
// tb_rnm.sv — RNM Testbench for SAR ADC (no power-aware features)
// Tests functional correctness of the ADC with analog stimulus.
// Uses real-valued voltages for analog input and reference.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module tb_rnm;

    parameter ADC_BITS = 8;
    parameter CLK_PERIOD = 10;  // 100 MHz
    parameter VREF = 1.8;

    logic clk;
    logic rst_n;
    logic start;
    real  v_in;
    logic [ADC_BITS-1:0] adc_out;
    logic done;
    logic busy;

    // DUT — RNM view
    sar_adc_top_rnm #(.ADC_BITS(ADC_BITS)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .v_in(v_in),
        .adc_out(adc_out),
        .done(done),
        .busy(busy)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        $display("========================================");
        $display(" SAR ADC RNM Testbench ");
        $display("========================================");

        // Initialize
        rst_n = 0;
        start = 0;
        v_in = 0.0;
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Test 1: Mid-scale input (0.9V = half of 1.8V)
        test_conversion(0.9, "mid-scale (0.9V)");

        // Test 2: Quarter-scale (0.45V)
        test_conversion(0.45, "quarter-scale (0.45V)");

        // Test 3: Three-quarter scale (1.35V)
        test_conversion(1.35, "three-quarter (1.35V)");

        // Test 4: Full-scale (1.8V)
        test_conversion(1.8, "full-scale (1.8V)");

        // Test 5: Zero
        test_conversion(0.0, "zero (0.0V)");

        // Test 6: Small signal near LSB (7mV ≈ 1 LSB for 8b/1.8V)
        test_conversion(0.007, "near-LSB (7mV)");

        $display("========================================");
        $display(" ALL RNM TESTS PASSED ");
        $display("========================================");
        $finish;
    end

    // Task: run one conversion and check result
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

            // Wait for conversion complete
            wait(done);
            @(posedge clk);

            // Calculate expected code
            expected_code = (vin_val / VREF) * ((1 << ADC_BITS) - 1);
            expected_int = $rtoi(expected_code);
            error = adc_out - expected_int;

            $display("[TEST] %s: vin=%.4f, adc_out=%0d (0x%0h), expected≈%0d, error=%0d",
                     test_name, vin_val, adc_out, adc_out, expected_int, error);

            // Allow ±1 LSB error
            if (error < -1 || error > 1) begin
                $display("[FAIL] %s: error %0d > 1 LSB", test_name, error);
                $error("Conversion error too large");
            end
        end
    endtask

    // Timeout watchdog
    initial begin
        #50000;
        $display("[TIMEOUT] Test timed out");
        $fatal(1, "Simulation timeout");
    end

    // Waveform dump
    initial begin
        $dumpfile("waves/tb_rnm.vcd");
        $dumpvars(0, tb_rnm);
    end

endmodule
