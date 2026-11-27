`timescale 1ns / 1ps

`include "constants.sv"

module m_stage(
    input logic clk,
    input logic rst,
    input logic run,

    input logic a_is_store,
    input logic [`DATA_WORD_SIZE-1:0] a_aluout,
    input logic [`DATA_WORD_SIZE-1:0] a_rs2_data,
    input logic a_is_load,
    input logic a_writes_rd,
    input logic [4:0] a_rf_waddr_d,

    // ports to dmem
    input logic [`DATA_WORD_SIZE-1:0] dmem_rdata_port,

    output logic dmem_wen,
    output logic [`DATA_ADDR_SIZE-1:0] dmem_rwaddr,
    output logic [`DATA_WORD_SIZE-1:0] dmem_wdata,

    output reg [`DATA_WORD_SIZE-1:0] m_aluout,
    output reg m_is_load,
    output reg m_writes_rd,
    output reg [`DATA_WORD_SIZE-1:0] m_dmem_rdata,
    output reg [4:0] m_rf_waddr_d
);

    assign dmem_rwaddr = a_aluout[`DATA_ADDR_SIZE-1:0];
    assign dmem_wen = run & a_is_store;
    assign dmem_wdata = a_rs2_data;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            m_is_load       <=0;
            m_writes_rd     <=0;
            m_dmem_rdata    <=0;
            m_rf_waddr_d    <=0;
            m_aluout        <=0;
        end else begin
            m_is_load       <=a_is_load;
            m_writes_rd     <=a_writes_rd;
            m_dmem_rdata    <=dmem_rdata_port;
            m_rf_waddr_d    <=a_rf_waddr_d;
            m_aluout        <=a_aluout;
        end
    end

endmodule
