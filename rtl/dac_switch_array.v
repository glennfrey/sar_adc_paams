//////////////////////////////////////////////////////////////////////////////
// dac_switch_array.v — Digital-to-Analog Converter Switch Control
// Generates thermometer-coded switch signals from SAR digital word
// In a real implementation, this drives analog switches; here it's
// the digital interface to the RNM/AMS DAC model.
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module dac_switch_array #(
    parameter ADC_BITS = 8,
    parameter VREF     = 1.8    // reference voltage in volts (for RNM calibration)
)(
    input  wire [ADC_BITS-1:0] dac_ctrl,    // SAR trial value
    input  wire                en,          // DAC enable
    output real                v_dac        // DAC output voltage (RNM)
);

    // Simple binary-weighted DAC model: Vdac = (dac_ctrl / 2^N) * VREF
    // In RNM, we use real-valued continuous assignment
    assign v_dac = en ? (real'(dac_ctrl) / real'(1 << ADC_BITS)) * VREF : 0.0;

endmodule
