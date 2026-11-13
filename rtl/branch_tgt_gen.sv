`timescale 1ns / 1ps

`include "constants.sv"

module branch_tgt_gen (
    input logic run,
    input logic [`DATA_ADDR_SIZE-1:0] pc,
    input logic [6:0] opcode,
    input logic branch_taken,
    input logic [`DATA_ADDR_SIZE-1:0] offset,

    output logic pc_wen,
    output logic [`DATA_ADDR_SIZE-1:0] branch_tgt
);
    // TODO: Check that we are doing byte-addressable on the imem
    logic signed [`DATA_ADDR_SIZE-1:0] word_offset;
    // TODO: Review this !
    assign word_offset = $signed(offset) / 4;  // bytes -> words
    assign branch_tgt = run ? pc + word_offset : '0;
    assign pc_wen = !run | branch_taken | (opcode == `OPCODE_JAL);

endmodule
