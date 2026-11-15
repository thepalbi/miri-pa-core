`timescale 1ns / 1ps

`include "constants.sv"

module register_file #(
    parameter word_size = `DATA_WORD_SIZE,
    parameter addr_size = `REG_ADDR_SIZE
) (
    input clk,
    input rst,

    input wen,
    input [addr_size-1:0] waddr_d,
    input [word_size-1:0] wdata_d,

    input [addr_size-1:0] raddr_a,
    input [addr_size-1:0] raddr_b,
    output logic [word_size-1:0] rdata_a,
    output logic [word_size-1:0] rdata_b
);
    reg [word_size-1:0] regs [0:(2 ** addr_size)-1];

    integer i;

    always_comb rdata_a = regs[raddr_a];
    always_comb rdata_b = regs[raddr_b];

    always_ff @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < (2 ** addr_size); i = i + 1)
                regs[i] <= 0;
        end else if (wen && waddr_d != 0) begin
            regs[waddr_d] <= wdata_d;
        end
    end

endmodule
