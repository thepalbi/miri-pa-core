`timescale 1ns / 1ps

`include "constants.sv"

module memory_bank #(
    parameter word_size=`DATA_WORD_SIZE,
    parameter addr_size=`DATA_ADDR_SIZE
) (
    input clk,
    input rst,

    // Write interface
    input wen,
    input [addr_size-1:0] waddr,
    input [word_size-1:0] wdata,

    // Read interface
    input [addr_size-1:0] raddr,
    output logic [word_size-1:0] rdata
);
    reg [word_size-1:0] bank [0:(2 ** addr_size)-1];

    integer i;
    always_ff @ (posedge clk) begin : write_path
        if (rst) begin
            for (i = 0; i < (2 ** addr_size); i = i + 1)
                bank[i] <= 0;
        end else if (wen) begin
            bank[waddr] <= wdata;
        end
    end

    always_comb rdata = bank[raddr];
endmodule
