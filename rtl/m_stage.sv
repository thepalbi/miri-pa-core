`timescale 1ns / 1ps

`include "constants.sv"

module m_stage(
    (* unused *) input logic clk,
    (* unused *) input logic rst,
    input logic run,

    input logic a_is_store,
    input logic [`DATA_WORD_SIZE-1:0] a_aluout,
    input logic [`DATA_WORD_SIZE-1:0] a_aluin_b,

    output logic dmem_wen,
    output logic [`DATA_ADDR_SIZE-1:0] dmem_rwaddr,
    output logic [`DATA_WORD_SIZE-1:0] dmem_wdata
);

    assign dmem_rwaddr = a_aluout[`DATA_ADDR_SIZE-1:0];
    assign dmem_wen = run & a_is_store;
    assign dmem_wdata = a_aluin_b;

endmodule
