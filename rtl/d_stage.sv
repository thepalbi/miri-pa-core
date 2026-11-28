`timescale 1ns / 1ps

`include "constants.sv"

module d_stage(
    input logic clk,
    input logic rst,
    input logic run,

    input logic hzd_nop_d,

    input logic [`DATA_ADDR_SIZE-1:0] f_ir_pc,
    input logic [`DATA_WORD_SIZE-1:0] f_ir,

    // register file iface
    output logic [4:0] rf_raddr_a,
    output logic [4:0] rf_raddr_b,
    input logic [`DATA_WORD_SIZE-1:0] rf_rdata_a,
    input logic [`DATA_WORD_SIZE-1:0] rf_rdata_b,
    input logic a_is_load,
    input logic a_writes_rd,
    input logic [4:0] a_rf_waddr_d,
    input logic m_writes_rd,
    input logic [4:0] m_rf_waddr_d,
    input logic [`DATA_WORD_SIZE-1:0] rf_wdata,

    // stage state
    output reg [4:0] d_rf_waddr_d,
    output reg [`DATA_WORD_SIZE-1:0] d_rs1_data,
    output reg [`DATA_WORD_SIZE-1:0] d_rs2_data,
    output reg d_aluin_b_is_imm,
    output reg [`DATA_WORD_SIZE-1:0] d_imm,
    output reg [`DATA_ADDR_SIZE-1:0] d_pc_tgt,

    output reg [6:0] d_opcode,
    output reg [2:0] d_funct3,
    output reg [6:0] d_funct7,

    output reg d_writes_rd,
    output reg d_is_store,
    output reg d_is_load,

    output reg d_fwd_aluout_rs1,
    output reg d_fwd_aluout_rs2,
    output reg d_fwd_rfwdata_rs1,
    output reg d_fwd_rfwdata_rs2
);

logic [`DATA_WORD_SIZE-1:0] imm;
logic [`DATA_ADDR_SIZE-1:0] offset_eff;

logic [20:0] offset;

logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rf_waddr_d;
logic [`DATA_WORD_SIZE-1:0] rs1_data;
logic [`DATA_WORD_SIZE-1:0] rs2_data;
logic [`DATA_ADDR_SIZE-1:0] pc_tgt;
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic writes_rd;
logic is_store;
logic is_load;
logic fwd_aluout_rs1;
logic fwd_aluout_rs2;
logic fwd_rfwdata_rs1;
logic fwd_rfwdata_rs2;
logic fwd_rfwdata_rfrdataa;
logic fwd_rfwdata_rfrdatab;
logic aluin_b_is_imm;
logic dec_writes_rd;
logic dec_is_store;
logic dec_is_load;
logic [6:0] dec_opcode;

assign offset_eff = offset[`DATA_ADDR_SIZE-1:0];
assign rs1_data = fwd_rfwdata_rfrdataa ? rf_wdata : rf_rdata_a;
assign rs2_data = fwd_rfwdata_rfrdatab ? rf_wdata : rf_rdata_b;
assign rf_raddr_a = rs1;
assign rf_raddr_b = rs2;

// MUX D/A stage registers
assign writes_rd = hzd_nop_d ? 0 : dec_writes_rd;
assign is_store  = hzd_nop_d ? 0 : dec_is_store;
assign is_load   = hzd_nop_d ? 0 : dec_is_load;
assign opcode    = hzd_nop_d ? 0 : dec_opcode;

decoder decoder (
	.ir             (f_ir),
	.rs1            (rs1),
	.rs2            (rs2),
	.rd             (rf_waddr_d),

	.writes_rd      (dec_writes_rd),
	.is_store       (dec_is_store),
	.is_load        (dec_is_load),
	.aluin_b_is_imm (aluin_b_is_imm),
	.imm            (imm),
	.offset         (offset),
	.opcode         (dec_opcode),
	.funct3         (funct3),
	.funct7         (funct7)
);

pc_tgt_gen pc_tgt_gen (
	.pc     (f_ir_pc),
	.offset (offset_eff),
	.pc_tgt (pc_tgt)
);

fwd_checker fwd_checker (
	.rf_r_rs1      (rs1),
	.rf_r_rs2      (rs2),
	.d_writes_rd   (d_writes_rd),
	.d_rf_waddr_d  (d_rf_waddr_d),

	.a_is_load(a_is_load),
    .a_writes_rd(a_writes_rd),
	.a_rf_waddr_d(a_rf_waddr_d),

    .m_writes_rd(m_writes_rd),
	.m_rf_waddr_d(m_rf_waddr_d),

	.fwd_aluout_rs1(fwd_aluout_rs1),
	.fwd_aluout_rs2(fwd_aluout_rs2),
	.fwd_rfwdata_rs1(fwd_rfwdata_rs1),
	.fwd_rfwdata_rs2(fwd_rfwdata_rs2),
	.fwd_rfwdata_rfrdataa(fwd_rfwdata_rfrdataa),
	.fwd_rfwdata_rfrdatab(fwd_rfwdata_rfrdatab)
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        d_rf_waddr_d            <=0;
        d_rs1_data              <=0;
        d_rs2_data              <=0;
        d_aluin_b_is_imm        <=0;
        d_imm                   <=0;
        d_pc_tgt                <=0;
        d_opcode                <=0;
        d_funct3                <=0;
        d_funct7                <=0;
        d_writes_rd             <=0;
        d_is_store              <=0;
        d_is_load               <=0;
        d_fwd_aluout_rs1        <=0;
        d_fwd_aluout_rs2        <=0;
        d_fwd_rfwdata_rs1       <=0;
        d_fwd_rfwdata_rs2       <=0;
    end else begin
        d_rf_waddr_d            <=rf_waddr_d;
        d_rs1_data              <=rs1_data;
        d_rs2_data              <=rs2_data;
        d_aluin_b_is_imm        <=aluin_b_is_imm;
        d_imm                   <=imm;
        d_pc_tgt                <=pc_tgt;
        d_opcode                <=opcode;
        d_funct3                <=funct3;
        d_funct7                <=funct7;
        d_writes_rd             <=writes_rd;
        d_is_store              <=is_store;
        d_is_load               <=is_load;
        d_fwd_aluout_rs1        <=fwd_aluout_rs1;
        d_fwd_aluout_rs2        <=fwd_aluout_rs2;
        d_fwd_rfwdata_rs1       <=fwd_rfwdata_rs1;
        d_fwd_rfwdata_rs2       <=fwd_rfwdata_rs2;
    end
end

endmodule
