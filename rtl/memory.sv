`timescale 1ns / 1ps

`include "constants.sv"

module memory_bank #(
    parameter word_size=`DATA_WORD_SIZE,
    parameter addr_size=`DATA_ADDR_SIZE
) (
    input clk,
    input w_en,
    input [addr_size-1:0] addr,
    input [word_size-1:0] d_in,

    output [word_size-1:0] d_out
);
    reg [word_size-1:0] bank [0:(2 ** addr_size)-1];

    assign d_out = bank[addr];

    always_ff @ (posedge clk) begin
        if (w_en)
            bank[addr] <= d_in;
        else
            bank[addr] <= bank[addr];
    end
endmodule
