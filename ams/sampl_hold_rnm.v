//////////////////////////////////////////////////////////////////////////////
// sampl_hold_rnm.v — Sample-and-Hold, SV-RNM (Real Number Modeling)
// Uses SystemVerilog real nets for analog voltage representation.
// This is the RNM view used in digital simulators (VCS, Xcelium).
//
// RNM Key Concept: analog behavior modeled with real numbers on digital nets,
// enabling fast mixed-signal simulation without SPICE solver.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module sampl_hold_rnm (
    input  real   v_in,       // analog input voltage (real net)
    output real   v_out,      // held/sampled voltage (real net)
    input  logic  sample_en,  // sample enable (active high)
    input  logic  clk,        // sampling clock
    input  logic  rst_n       // reset
);

    real v_sampled;

    // Sample on rising edge of clk when sample_en is high
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            v_sampled <= 0.0;
        else if (sample_en)
            v_sampled <= v_in;
    end

    // Output tracks sampled value (track-and-hold behavior)
    assign v_out = v_sampled;

    // RNM debug probe (can be viewed in Verdi FSDB)
    always @(posedge clk) begin
        if (sample_en)
            $display("[RNM S/H] SAMPLE: v_in=%f, v_sampled=%f @ %0t", v_in, v_sampled, $time);
    end

endmodule
