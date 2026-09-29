`timescale 1ns/1ps
module sar_controller #(
    parameter ADC_BITS = 8
)(
    input wire clk, rst_n, start, comp_out,
    output wire sample_en,
    output wire comp_en,
    output wire [ADC_BITS-1:0] dac_ctrl,
    output reg [ADC_BITS-1:0] adc_out,
    output reg done, busy
);
    localparam IDLE=0, SAMPLE=1, CONV_START=2, CONV_READ=3, DONE=4;
    reg [2:0] state;
    reg [ADC_BITS-1:0] sar_reg;
    reg [$clog2(ADC_BITS):0] bit_cnt;

    assign sample_en = (state == SAMPLE);
    assign comp_en   = (state == CONV_START);
    assign dac_ctrl  = (state == CONV_START) ? (sar_reg | (1 << bit_cnt)) : sar_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; sar_reg <= 0; bit_cnt <= 0;
            adc_out <= 0; done <= 0; busy <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    if (start) begin
                        busy <= 1; bit_cnt <= ADC_BITS-1; sar_reg <= 0;
                        state <= SAMPLE;
                    end
                end
                SAMPLE: state <= CONV_START;
                CONV_START: state <= CONV_READ;
                CONV_READ: begin
                    if (comp_out) sar_reg[bit_cnt] = 1'b1;
                    else          sar_reg[bit_cnt] = 1'b0;

                    if (bit_cnt == 0) begin
                        adc_out <= sar_reg;
                        done <= 1; busy <= 0; state <= DONE;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        state <= CONV_START;
                    end
                end
                DONE: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
