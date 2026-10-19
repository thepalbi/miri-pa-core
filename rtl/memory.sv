`timescale 1ns / 1ps

`include "constants.sv"

module memory_bank #(
    parameter word_size=`DATA_WORD_SIZE,
    parameter addr_size=`DATA_ADDR_SIZE
) (
    input clk,

    // Write interface
    input w_en,
    input [addr_size-1:0] w_addr,
    input [word_size-1:0] d_in,

    // Read interface
    input [addr_size-1:0] r_addr,
    output logic [word_size-1:0] d_out
);
    reg [word_size-1:0] bank [0:(2 ** addr_size)-1];

    always_ff @ (posedge clk) begin
        if (w_en)
            bank[w_addr] <= d_in;
    end

    always_ff @ (posedge clk) begin
        d_out <= bank[r_addr];
    end
endmodule
