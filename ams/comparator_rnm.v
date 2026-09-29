//////////////////////////////////////////////////////////////////////////////
// comparator_rnm.v — Comparator, SV-RNM (Real Number Modeling)
// Compares two real-valued voltages and produces digital output.
// Includes power-aware behavior: output goes to X when not enabled.
//
// RNM Key Concept: real inputs + digital output = analog/digital boundary.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module comparator_rnm (
    input  real   v_in_p,     // positive input (from S/H)
    input  real   v_in_n,     // negative input (from DAC)
    output logic  comp_out,   // digital output: 1 if v_in_p > v_in_n
    input  logic  en,         // comparator enable (power gating)
    input  logic  clk,        // comparison clock (for synchronous sampling)
    input  logic  rst_n
);

    logic comp_raw;

    // Continuous comparison (analog behavior)
    assign comp_raw = (v_in_p > v_in_n) ? 1'b1 : 1'b0;

    // Registered output with enable (power-aware: X when disabled)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            comp_out <= 1'b0;
        else if (en)
            comp_out <= comp_raw;
        else
            comp_out <= 1'bx;  // power-gated: output unknown
    end

    // RNM debug
    always @(posedge clk) begin
        if (en)
            $display("[RNM COMP] v_in_p=%f, v_in_n=%f, comp_out=%b @ %0t", 
                     v_in_p, v_in_n, comp_out, $time);
    end

endmodule
