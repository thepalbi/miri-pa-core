`timescale 1ns / 1ps

`include "constants.sv"

module pc_tgt_gen (
    input logic [`DATA_ADDR_SIZE-1:0] pc,
    input logic [`DATA_ADDR_SIZE-1:0] offset,

    output logic [`DATA_ADDR_SIZE-1:0] pc_tgt
);
    // TODO: Check that we are doing byte-addressable on the imem
    logic signed [`DATA_ADDR_SIZE-1:0] word_offset;
    assign word_offset = $signed(offset) / 4;  // bytes -> words

    assign pc_tgt = pc + word_offset;

endmodule
