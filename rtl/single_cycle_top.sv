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
    logic branch_taken;

    logic [4:0] rf_raddr_a;
    logic [4:0] rf_raddr_b;
    logic [4:0] rf_waddr_d;

    logic [`DATA_WORD_SIZE-1:0] rf_rdata_a;
    logic [`DATA_WORD_SIZE-1:0] rf_rdata_b;
    logic [`DATA_WORD_SIZE-1:0] rf_d;

    logic [`DATA_ADDR_SIZE-1:0] imem_raddr;
    logic [`DATA_WORD_SIZE-1:0] imem_rdata;

    logic [`DATA_WORD_SIZE-1:0] alu_out;
    logic [`DATA_WORD_SIZE-1:0] dmem_d_out;
    logic [`DATA_ADDR_SIZE-1:0] pc;
    logic [`DATA_WORD_SIZE-1:0] ir;
    logic [`DATA_ADDR_SIZE-1:0] dmem_rw_addr;

    logic [4:0] d_rf_waddr_d;
    logic [`DATA_WORD_SIZE-1:0] d_aluin_a;
    logic [`DATA_WORD_SIZE-1:0] d_aluin_b;
    logic d_pc_wen;
    logic [`DATA_ADDR_SIZE-1:0] d_branch_target;

    logic [6:0] d_opcode;
    logic [2:0] d_funct3;
    logic [6:0] d_funct7;

    logic d_writes_rd;
    logic d_is_store;
    logic d_is_load;

    // ## datapath

    assign imem_raddr = pc;
    assign rf_d = d_is_load ? dmem_d_out : alu_out;
    assign dmem_rw_addr = alu_out[`DATA_ADDR_SIZE-1:0];

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
        .wen(d_is_store && run),
        .waddr(dmem_rw_addr),
        .wdata(rf_rdata_b),
        .raddr(dmem_rw_addr),
        .rdata(dmem_d_out)
    );

    // ### stages

    f_stage f_stage(
    .clk(clk),
    .rst(rst),
    .wen_pc(d_pc_wen),
    .waddr_pc(d_branch_target),
    .imem_rdata(imem_rdata),
    .f_pc(pc),
    .f_ir(ir)
    );

    d_stage d_stage(
        .clk(clk),
        .rst(rst),
        .run(run),
        .branch_taken(branch_taken),
        .f_pc(pc),
        .f_ir(ir),

        .rf_raddr_a(rf_raddr_a),
        .rf_raddr_b(rf_raddr_b),
        .rf_rdata_a(rf_rdata_a),
        .rf_rdata_b(rf_rdata_b),

        .rf_waddr_d(d_rf_waddr_d),
        .aluin_a(d_aluin_a),
        .aluin_b(d_aluin_b),
        .pc_wen(d_pc_wen),
        .branch_target(d_branch_target),
        .opcode(d_opcode),
        .funct3(d_funct3),
        .funct7(d_funct7),
        .writes_rd(d_writes_rd),
        .is_store(d_is_store),
        .is_load(d_is_load)
    );


    alu alu(
        .input1(d_aluin_a),
        .input2(d_aluin_b),
        .opcode(d_opcode),
        .funct3(d_funct3),
        .funct7(d_funct7),
        .result(alu_out),
        .taken(branch_taken)
    );

    register_file rf(
        .clk(clk),
        .rst(rst),
        .wen(d_writes_rd && run),
        .waddr_d(d_rf_waddr_d),
        .wdata_d(rf_d),
        .raddr_a(rf_raddr_a),
        .raddr_b(rf_raddr_b),
        .rdata_a(rf_rdata_a),
        .rdata_b(rf_rdata_b)
    );

endmodule
