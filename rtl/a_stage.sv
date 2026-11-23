`timescale 1ns / 1ps

`include "constants.sv"

module a_stage(
    input logic clk,
    input logic rst,

    input logic [`DATA_WORD_SIZE-1:0] d_aluin_a,
    input logic [`DATA_WORD_SIZE-1:0] d_aluin_b,
    input logic [6:0] d_opcode,
    input logic [2:0] d_funct3,
    input logic [6:0] d_funct7,
    input logic d_is_store,
    input logic d_is_load,
    input logic d_writes_rd,
    input logic [4:0] d_rf_waddr_d,
    input logic d_fwd_aluout_aluin_a,
    input logic d_fwd_aluout_aluin_b,
    input logic d_fwd_mdmemrdata_aluin_a,
    input logic d_fwd_mdmemrdata_aluin_b,
    input logic [`DATA_WORD_SIZE-1:0] m_dmem_rdata,

    output reg [`DATA_WORD_SIZE-1:0] a_aluout,
    output reg [`DATA_WORD_SIZE-1:0] a_aluin_b,
    output reg a_btaken,
    output reg a_is_store,
    output reg a_is_load,
    output reg a_writes_rd,
    output reg [4:0] a_rf_waddr_d
);
    logic [`DATA_WORD_SIZE-1:0] aluout;
    logic [`DATA_WORD_SIZE-1:0] aluin_a;
    logic [`DATA_WORD_SIZE-1:0] aluin_b;
    logic btaken;
    logic is_store;
    logic is_load;
    logic writes_rd;
    logic [4:0] rf_waddr_d;

    assign is_store = d_is_store;
    assign aluin_a =    d_fwd_mdmemrdata_aluin_a ? m_dmem_rdata :
                        d_fwd_aluout_aluin_a ? a_aluout :
                        d_aluin_a;
    assign aluin_b =    d_fwd_mdmemrdata_aluin_b ? m_dmem_rdata :
                        d_fwd_aluout_aluin_b ? a_aluout :
                        d_aluin_b;
    assign is_load = d_is_load;
    assign writes_rd = d_writes_rd;
    assign rf_waddr_d = d_rf_waddr_d;

    alu alu(
        .input1(aluin_a),
        .input2(aluin_b),
        .opcode(d_opcode),
        .funct3(d_funct3),
        .funct7(d_funct7),
        .result(aluout),
        .taken(btaken)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            a_aluout        <=0;
            a_aluin_b       <=0;
            a_btaken        <=0;
            a_is_store      <=0;
            a_is_load       <=0;
            a_writes_rd     <=0;
            a_rf_waddr_d    <=0;
        end else begin
            a_aluout        <=aluout;
            a_aluin_b       <=aluin_b;
            a_btaken        <=btaken;
            a_is_store      <=is_store;
            a_is_load       <=is_load;
            a_writes_rd     <=writes_rd;
            a_rf_waddr_d    <=rf_waddr_d;
        end

    end


endmodule
