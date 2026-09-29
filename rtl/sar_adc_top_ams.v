//////////////////////////////////////////////////////////////////////////////
// sar_adc_top_ams.v — SAR ADC Top-Level, AMS view
// Integrates digital controller + Verilog-AMS analog frontend.
// This is the "SPICE-accurate" view for VCS-AD / Xcelium AMS.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module sar_adc_top_ams #(
    parameter ADC_BITS = 8
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              start,
    input  wire               v_in,       // analog input (electrical discipline)
    output logic [ADC_BITS-1:0] adc_out,
    output logic              done,
    output logic              busy
);

    // Internal analog nets (electrical discipline)
    electrical v_sampl;
    electrical v_dac;
    electrical v_ref;

    // Digital control signals
    logic sample_en;
    logic comp_en;
    logic comp_out;
    logic [ADC_BITS-1:0] dac_ctrl;

    // Reference voltage (1.8V ideal source)
    // In real design, this comes from a bandgap; here ideal for capstone
    assign v_ref = 1.8;  // simplified; real AMS would use vsource

    // Sample-and-Hold (AMS)
    sampl_hold_ams u_sah (
        .v_in(v_in),
        .v_out(v_sampl),
        .sample_en(sample_en),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Comparator (AMS)
    comparator_ams u_comp (
        .v_in_p(v_sampl),
        .v_in_n(v_dac),
        .comp_out(comp_out),
        .en(comp_en),
        .clk(clk),
        .rst_n(rst_n)
    );

    // DAC (AMS)
    dac_ams #(.ADC_BITS(ADC_BITS), .VREF(1.8)) u_dac (
        .dac_ctrl(dac_ctrl),
        .en(comp_en),
        .v_out(v_dac),
        .v_ref(v_ref)
    );

    // SAR Controller (Digital)
    sar_controller #(.ADC_BITS(ADC_BITS)) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .comp_out(comp_out),
        .sample_en(sample_en),
        .comp_en(comp_en),
        .dac_ctrl(dac_ctrl),
        .adc_out(adc_out),
        .done(done),
        .busy(busy)
    );

endmodule
