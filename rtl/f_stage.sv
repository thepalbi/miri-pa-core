`timescale 1ns / 1ps

`include "constants.sv"

module f_stage(
    input logic clk,
    input logic rst,
    input logic run,

    // PC write signals
    input logic wen_pc,
    input logic [`DATA_ADDR_SIZE-1:0] waddr_pc,

    // Instruction memory interface signals, read only
    input logic [`DATA_WORD_SIZE-1:0] imem_rdata,

    // Stage interface
    output reg [`DATA_ADDR_SIZE-1:0] f_pc,
    output reg [`DATA_WORD_SIZE-1:0] f_ir
);

logic [`DATA_ADDR_SIZE-1:0] next_pc;

pc pc_mod(
    .clk(clk),
    .rst(rst),
    .run(run),
    .w_en(wen_pc),
    .addr_in(waddr_pc),
    .out(next_pc)
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        f_ir <= 0;
        f_pc <= 0;
    end else begin
        f_ir <= imem_rdata;
        f_pc <= next_pc;
    end
end

endmodule
