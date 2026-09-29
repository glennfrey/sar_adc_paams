`timescale 1ns/1ps
module sampl_hold_rnm (
    input real v_in,
    output real v_out,
    input logic sample_en, clk, rst_n
);
    real v_sampled;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) v_sampled <= 0.0;
        else if (sample_en) v_sampled <= v_in;
    end
    assign v_out = sample_en ? v_in : v_sampled;
endmodule
