`timescale 1ns / 1ps

`include "constants.sv"

module m_stage(
    (* unused *) input logic clk,
    (* unused *) input logic rst,
    input logic run,

    input logic a_is_store,
    input logic [`DATA_WORD_SIZE-1:0] a_aluout,
    input logic [`DATA_WORD_SIZE-1:0] a_aluin_b,
    input logic a_is_load,
    input logic a_writes_rd,
    input logic [4:0] a_rf_waddr_d,

    // ports to dmem
    input logic [`DATA_WORD_SIZE-1:0] dmem_rdata_port,

    output logic dmem_wen,
    output logic [`DATA_ADDR_SIZE-1:0] dmem_rwaddr,
    output logic [`DATA_WORD_SIZE-1:0] dmem_wdata,
    output logic [`DATA_WORD_SIZE-1:0] aluout,

    output logic is_load,
    output logic writes_rd,
    output logic [`DATA_WORD_SIZE-1:0] dmem_rdata,
    output logic [4:0] rf_waddr_d
);

    assign dmem_rwaddr = a_aluout[`DATA_ADDR_SIZE-1:0];
    assign dmem_wen = run & a_is_store;
    assign dmem_wdata = a_aluin_b;
    assign aluout = a_aluout;
    assign is_load = a_is_load;
    assign writes_rd = a_writes_rd;
    assign dmem_rdata = dmem_rdata_port;
    assign rf_waddr_d = a_rf_waddr_d;

endmodule
