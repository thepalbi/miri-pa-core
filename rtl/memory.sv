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
    output reg [word_size-1:0] d_out,
);
    // main memory bank
    reg [word_size-1:0] bank [0:(2 ** addr_size)-1];

    always @ (*)
        d_out <= bank[addr];

    always @ (posedge clk) begin
        if (w_en)
            bank[addr] <= d_in;
    end
endmodule