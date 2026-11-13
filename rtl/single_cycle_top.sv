`timescale 1ns / 1ps

`include "constants.sv"

module single_cycle_top (
    input logic clk,
    input logic rst,
    input logic run,
    input logic imem_w_en,
    input logic [`DATA_ADDR_SIZE-1:0] imem_addr,
    input logic [`DATA_WORD_SIZE-1:0] imem_d
);

    // ## SIGNALS

    // decoder signals
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic writes_rd;
    logic is_store;
    logic is_load;
    logic [`DATA_WORD_SIZE-1:0] imm;
    logic [20:0] offset;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [`DATA_WORD_SIZE-1:0] rf_a;
    logic [`DATA_WORD_SIZE-1:0] rf_b;
    logic [`DATA_WORD_SIZE-1:0] rf_d;

    logic [`DATA_ADDR_SIZE-1:0] imem_raddr;
    logic [`DATA_WORD_SIZE-1:0] imem_rdata;

    logic [`DATA_WORD_SIZE-1:0] alu_out;
    logic [`DATA_WORD_SIZE-1:0] dmem_d_out;
    logic [`DATA_ADDR_SIZE-1:0] pc;
    logic [`DATA_WORD_SIZE-1:0] ir;
    logic [`DATA_ADDR_SIZE-1:0] offset_eff;
    logic [`DATA_ADDR_SIZE-1:0] dmem_rw_addr;

    // PC block
    logic pc_wen;
    logic [`DATA_ADDR_SIZE-1:0] branch_target;

    logic branch_taken;

    // ALU auxiliary signals

    logic [`DATA_WORD_SIZE-1:0] alu_input2;

    // ## datapath

    assign imem_raddr = pc;
    assign offset_eff = offset[`DATA_ADDR_SIZE-1:0];
    assign rf_d = is_load ? dmem_d_out : alu_out;
    assign dmem_rw_addr = alu_out[`DATA_ADDR_SIZE-1:0];
    assign alu_input2 = (is_load || is_store || opcode == `OPCODE_OP_IMM) ?
        imm : rf_b;

    // ## modules
    // ### common

    memory_bank imem(
        .clk(clk),
        .rst(rst),
        .wen(imem_w_en),
        .waddr(imem_addr),
        .wdata(imem_d),
        .raddr(imem_raddr),
        .rdata(imem_rdata)
    );

    memory_bank dmem(
        .clk(clk),
        .rst(rst),
        .wen(is_store && run),
        .waddr(dmem_rw_addr),
        .wdata(rf_b),
        .raddr(dmem_rw_addr),
        .rdata(dmem_d_out)
    );

    // ### stages

    f_stage f_stage(
    .clk(clk),
    .rst(rst),
    .wen_pc(pc_wen),
    .waddr_pc(branch_target),
    .imem_rdata(imem_rdata),
    .f_pc(pc),
    .f_ir(ir)
    );


    branch_tgt_gen branch_tgt_gen (
	.run         (run),
	.pc          (pc),
	.opcode      (opcode),
	.branch_taken(branch_taken),
	.offset      (offset_eff),
	.pc_wen      (pc_wen),
	.branch_tgt  (branch_target)
    );

    // decoder consumes all top-instantiated wires since they have
    // identical name.
    decoder dec(.*);

    alu alu(
        .input1(rf_a),
        .input2(alu_input2),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .result(alu_out),
        .taken(branch_taken)
    );

    register_file rf(
        .clk(clk),
        .rst(rst),
        .wen(writes_rd && run),
        .waddr_d(rd),
        .wdata_d(rf_d),
        .raddr_a(rs1),
        .raddr_b(rs2),
        .rdata_a(rf_a),
        .rdata_b(rf_b)
    );

endmodule
