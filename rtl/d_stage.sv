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
    output reg [4:0] d_rf_waddr_d,
    output reg [`DATA_WORD_SIZE-1:0] d_aluin_a,
    output reg [`DATA_WORD_SIZE-1:0] d_aluin_b,
    output reg d_pc_wen,
    output reg [`DATA_ADDR_SIZE-1:0] d_branch_target,

    output reg [6:0] d_opcode,
    output reg [2:0] d_funct3,
    output reg [6:0] d_funct7,

    output reg d_writes_rd,
    output reg d_is_store,
    output reg d_is_load
);
logic [`DATA_WORD_SIZE-1:0] imm;
logic [`DATA_ADDR_SIZE-1:0] offset_eff;

logic [20:0] offset;

logic [4:0] rf_waddr_d;
logic [`DATA_WORD_SIZE-1:0] aluin_a;
logic [`DATA_WORD_SIZE-1:0] aluin_b;
logic pc_wen;
logic [`DATA_ADDR_SIZE-1:0] branch_target;
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic writes_rd;
logic is_store;
logic is_load;

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

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        d_rf_waddr_d      <=0;
        d_aluin_a         <=0;
        d_aluin_b         <=0;
        d_pc_wen          <=0;
        d_branch_target   <=0;
        d_opcode          <=0;
        d_funct3          <=0;
        d_funct7          <=0;
        d_writes_rd       <=0;
        d_is_store        <=0;
        d_is_load         <=0;
    end else begin
        d_rf_waddr_d      <=rf_waddr_d;
        d_aluin_a         <=aluin_a;
        d_aluin_b         <=aluin_b;
        d_pc_wen          <=pc_wen;
        d_branch_target   <=branch_target;
        d_opcode          <=opcode;
        d_funct3          <=funct3;
        d_funct7          <=funct7;
        d_writes_rd       <=writes_rd;
        d_is_store        <=is_store;
        d_is_load         <=is_load;
    end

end

endmodule
