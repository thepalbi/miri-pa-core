`timescale 1ns / 1ps

`include "constants.sv"

module memory_bank #(
    parameter word_size=`DATA_WORD_SIZE,
    parameter addr_size=`DATA_ADDR_SIZE
) (
    input clk,
    input rst,

    // Write interface
    input w_en,
    input [addr_size-1:0] w_addr,
    input [word_size-1:0] d_in,

    // Read interface
    input [addr_size-1:0] r_addr,
    output logic [word_size-1:0] d_out
);
    reg [word_size-1:0] bank [0:(2 ** addr_size)-1];

    integer i;
    always_ff @ (posedge clk) begin : write_path
        if (rst) begin
            for (i = 0; i < (2 ** addr_size); i = i + 1)
                bank[i] <= 0;
        end else if (w_en) begin
            bank[w_addr] <= d_in;
        end
    end

    always_comb d_out = bank[r_addr];
endmodule
