//////////////////////////////////////////////////////////////////////////////
// vref_rnm.v — Reference Voltage Generator, SV-RNM
// Simple real-valued voltage source for DAC reference.
// Can be turned off for power-domain shutdown testing (PA-AMS).
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module vref_rnm (
    output real   v_ref,      // reference voltage output
    input  logic  en          // enable (power domain control)
);

    parameter real VREF_VAL = 1.8;  // 1.8V reference

    assign v_ref = en ? VREF_VAL : 0.0;

endmodule
