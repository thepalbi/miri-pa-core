`timescale 1ns / 1ps

`include "constants.sv"

module register_file #(
    parameter word_size = `DATA_WORD_SIZE,
    parameter addr_size = `REG_ADDR_SIZE
) (
    input clk,
    input rst,

    input has_read,
    input [addr_size-1:0] rd,
    input [word_size-1:0] d,

    input [addr_size-1:0] ra,
    input [addr_size-1:0] rb,
    output logic [word_size-1:0] a,
    output logic [word_size-1:0] b
);
    reg [word_size-1:0] regs [0:(2 ** addr_size)-1];

    integer i;

    always_comb a = regs[ra];
    always_comb b = regs[rb];

    always_ff @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < (2 ** addr_size); i = i + 1)
                regs[i] <= 0;
        end else if (has_read && rd != 0) begin
            regs[rd] <= d;
        end
    end

endmodule
