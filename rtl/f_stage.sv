`timescale 1ns / 1ps

`include "constants.sv"

module f_stage(
    input logic clk,
    input logic rst,

    // PC write signals
    input logic wen_pc,
    input logic [`DATA_ADDR_SIZE-1:0] waddr_pc,

    // Instruction memory interface signals, read only
    input logic [`DATA_WORD_SIZE-1:0] imem_rdata,

    // Stage interface
    output [`DATA_ADDR_SIZE-1:0] f_pc,
    output [`DATA_WORD_SIZE-1:0] f_ir
);

// TODO: Segment this !
assign f_ir = imem_rdata;

pc pc_mod(
    .clk(clk),
    .w_en(wen_pc),
    .addr_in(waddr_pc),
    .out(f_pc)
);

endmodule
