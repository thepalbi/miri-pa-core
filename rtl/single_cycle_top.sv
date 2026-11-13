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
    logic a_btaken;

    logic [4:0] rf_raddr_a;
    logic [4:0] rf_raddr_b;
    logic rf_wen;

    logic dmem_wen;

    logic [`DATA_WORD_SIZE-1:0] rf_rdata_a;
    logic [`DATA_WORD_SIZE-1:0] rf_rdata_b;

    logic [`DATA_ADDR_SIZE-1:0] imem_raddr;
    logic [`DATA_WORD_SIZE-1:0] imem_rdata;

    logic [`DATA_WORD_SIZE-1:0] a_aluout;
    logic [`DATA_WORD_SIZE-1:0] dmem_rdata;
    logic [`DATA_ADDR_SIZE-1:0] pc;
    logic [`DATA_WORD_SIZE-1:0] ir;
    logic [`DATA_ADDR_SIZE-1:0] dmem_rwaddr;
    logic [`DATA_WORD_SIZE-1:0] dmem_wdata;

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

    logic [`DATA_WORD_SIZE-1:0] a_aluin_b;
    logic a_is_store;
    logic a_is_load;
    logic a_writes_rd;
    logic [4:0] a_rf_waddr_d;

    logic [`DATA_WORD_SIZE-1:0] m_dmem_rdata;
    logic m_is_load;
    logic m_writes_rd;
    logic [`DATA_WORD_SIZE-1:0] m_aluout;
    logic [4:0] m_rf_waddr_d;

    logic [`DATA_WORD_SIZE-1:0] rf_wdata;
    logic [4:0] rf_waddr;

    // ## datapath

    assign imem_raddr = pc;

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
        .wen(dmem_wen),
        .waddr(dmem_rwaddr),
        .wdata(dmem_wdata),
        .raddr(dmem_rwaddr),
        .rdata(dmem_rdata)
    );

    register_file rf(
        .clk(clk),
        .rst(rst),

        .wen(rf_wen),
        .waddr_d(rf_waddr),
        .wdata_d(rf_wdata),

        .raddr_a(rf_raddr_a),
        .raddr_b(rf_raddr_b),
        .rdata_a(rf_rdata_a),
        .rdata_b(rf_rdata_b)
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
        .branch_taken(a_btaken),
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

    a_stage a_stage(
        .clk(clk),
        .rst(rst),
        .d_aluin_a(d_aluin_a),
        .d_aluin_b(d_aluin_b),
        .d_opcode(d_opcode),
        .d_funct3(d_funct3),
        .d_funct7(d_funct7),
        .d_is_store(d_is_store),
        .d_is_load(d_is_load),
        .d_writes_rd(d_writes_rd),
        .d_rf_waddr_d(d_rf_waddr_d),

        .aluout(a_aluout),
        .aluin_b(a_aluin_b),
        .btaken(a_btaken),
        .is_store(a_is_store),
        .is_load(a_is_load),
        .writes_rd(a_writes_rd),
        .rf_waddr_d(a_rf_waddr_d)
    );

    m_stage m_stage (
    	.clk        (clk),
    	.rst        (rst),
    	.run        (run),
    	.a_is_store (a_is_store),
    	.a_aluout   (a_aluout),
    	.a_aluin_b  (a_aluin_b),
        .a_is_load(a_is_load),
        .a_writes_rd(a_writes_rd),
        .a_rf_waddr_d(a_rf_waddr_d),
        .dmem_rdata_port(dmem_rdata),
    	.dmem_wen   (dmem_wen),
    	.dmem_rwaddr(dmem_rwaddr),
    	.dmem_wdata (dmem_wdata),
        .dmem_rdata(m_dmem_rdata),
        .is_load(m_is_load),
        .writes_rd(m_writes_rd),
        .aluout(m_aluout),
        .rf_waddr_d(m_rf_waddr_d)
    );

    wb_stage wb_stage (
    	.clk         (clk),
    	.rst         (rst),
    	.run         (run),
    	.m_is_load   (m_is_load),
    	.m_writes_rd (m_writes_rd),
    	.m_rf_waddr_d(m_rf_waddr_d),
    	.m_aluout    (m_aluout),
    	.m_dmem_rdata(m_dmem_rdata),
    	.rf_wen      (rf_wen),
    	.rf_waddr    (rf_waddr),
    	.rf_wdata    (rf_wdata)
    );

endmodule
