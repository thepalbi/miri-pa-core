`timescale 1ns / 1ps

`include "constants.sv"

module d_stage(
    input logic clk,
    input logic rst,
    input logic run,

    input logic branch_taken,

    input logic [`DATA_ADDR_SIZE-1:0] f_pc,
    input logic [`DATA_WORD_SIZE-1:0] f_ir,

    // register file iface
    output logic [4:0] rf_raddr_a,
    output logic [4:0] rf_raddr_b,
    input logic [`DATA_WORD_SIZE-1:0] rf_rdata_a,
    input logic [`DATA_WORD_SIZE-1:0] rf_rdata_b,

    // stage state
    output logic [4:0] rf_waddr_d,
    output logic [`DATA_WORD_SIZE-1:0] aluin_a,
    output logic [`DATA_WORD_SIZE-1:0] aluin_b,
    output logic pc_wen,
    output logic [`DATA_ADDR_SIZE-1:0] branch_target,

    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,

    output logic writes_rd,
    output logic is_store,
    output logic is_load
);
logic [`DATA_WORD_SIZE-1:0] imm;
logic [`DATA_ADDR_SIZE-1:0] offset_eff;

logic [20:0] offset;

assign offset_eff = offset[`DATA_ADDR_SIZE-1:0];

assign aluin_a = rf_rdata_a;
assign aluin_b = (is_load || is_store || opcode == `OPCODE_OP_IMM) ?
    imm : rf_rdata_b;


decoder decoder (
	.ir       (f_ir),
	.rs1      (rf_raddr_a),
	.rs2      (rf_raddr_b),
	.rd       (rf_waddr_d),

	.writes_rd(writes_rd),
	.is_store (is_store),
	.is_load  (is_load),
	.imm      (imm),
	.offset   (offset),
	.opcode   (opcode),
	.funct3   (funct3),
	.funct7   (funct7)
);

branch_tgt_gen branch_tgt_gen (
	.run         (run),
	.pc          (f_pc),
	.opcode      (opcode),
	.branch_taken(branch_taken),
	.offset      (offset_eff),
	.pc_wen      (pc_wen),
	.branch_tgt  (branch_target)
);

endmodule
