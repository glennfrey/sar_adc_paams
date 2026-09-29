//////////////////////////////////////////////////////////////////////////////
// sar_adc_top_rnm.v — SAR ADC Top-Level, RNM view
// Integrates digital controller + RNM analog frontend.
// This is the "digital-centric" view for fast PA-AMS verification.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module sar_adc_top_rnm #(
    parameter ADC_BITS = 8
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              start,
    input  real               v_in,       // analog input (RNM real net)
    output logic [ADC_BITS-1:0] adc_out,
    output logic              done,
    output logic              busy
);

    // Internal analog signals (real nets)
    real v_sampl;       // sampled voltage
    real v_dac;         // DAC output voltage
    real v_ref;         // reference voltage

    // Digital control signals
    logic sample_en;
    logic comp_en;
    logic comp_out;
    logic [ADC_BITS-1:0] dac_ctrl;

    // Reference voltage (always-on analog)
    vref_rnm #(.VREF_VAL(1.8)) u_vref (
        .v_ref(v_ref),
        .en(1'b1)        // always enabled in this view
    );

    // Sample-and-Hold (RNM)
    sampl_hold_rnm u_sah (
        .v_in(v_in),
        .v_out(v_sampl),
        .sample_en(sample_en),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Comparator (RNM)
    comparator_rnm u_comp (
        .v_in_p(v_sampl),
        .v_in_n(v_dac),
        .comp_out(comp_out),
        .en(comp_en),
        .clk(clk),
        .rst_n(rst_n)
    );

    // DAC (RNM — binary weighted)
    dac_switch_array #(.ADC_BITS(ADC_BITS), .VREF(1.8)) u_dac (
        .dac_ctrl(dac_ctrl),
        .en(comp_en),
        .v_dac(v_dac)
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
