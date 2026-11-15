`timescale 1ns / 1ps

`include "constants.sv"

module wb_stage(
    (* unused *) input logic clk,
    (* unused *) input logic rst,
    input logic run,

    input logic m_is_load,
    input logic m_writes_rd,
    input logic [4:0] m_rf_waddr_d,
    input logic [`DATA_WORD_SIZE-1:0] m_aluout,
    input logic [`DATA_WORD_SIZE-1:0] m_dmem_rdata,

    output logic rf_wen,
    output logic [4:0] rf_waddr,
    output logic [`DATA_WORD_SIZE-1:0] rf_wdata
);

    assign rf_wen = run & m_writes_rd;
    assign rf_wdata = m_is_load ? m_dmem_rdata : m_aluout;
    assign rf_waddr = m_rf_waddr_d;

endmodule
