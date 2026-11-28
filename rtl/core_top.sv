`timescale 1ns / 1ps

`include "constants.sv"

module core_top (
    input logic clk,
    input logic rst,
    input logic run,
    input logic imem_w_en,
    input logic imem_rst,
    input logic [`DATA_ADDR_SIZE-1:0] imem_waddr,
    input logic [`DATA_WORD_SIZE-1:0] imem_wdata
);

    // ## SIGNALS

    // General control signals
    logic [`DATA_ADDR_SIZE-1:0] pc;
    logic [`DATA_WORD_SIZE-1:0] ir;
    logic stall;

    // Register file signals
    // read
    logic [4:0] rf_raddr_a;
    logic [4:0] rf_raddr_b;
    logic [`DATA_WORD_SIZE-1:0] rf_rdata_a;
    logic [`DATA_WORD_SIZE-1:0] rf_rdata_b;
    // write
    logic rf_wen;
    logic [4:0] rf_waddr;
    logic [`DATA_WORD_SIZE-1:0] rf_wdata;

    // DMEM signals
    logic dmem_wen;
    logic [`DATA_WORD_SIZE-1:0] dmem_rdata;
    logic [`DATA_ADDR_SIZE-1:0] dmem_rwaddr;
    logic [`DATA_WORD_SIZE-1:0] dmem_wdata;

    // IMEM signals
    logic [`DATA_ADDR_SIZE-1:0] imem_raddr;
    logic [`DATA_WORD_SIZE-1:0] imem_rdata;

    // D-stage signals
    logic [4:0] d_rf_waddr_d;
    logic [`DATA_WORD_SIZE-1:0] d_rs1_data;
    logic [`DATA_WORD_SIZE-1:0] d_rs2_data;
    logic d_aluin_b_is_imm;
    logic [`DATA_WORD_SIZE-1:0] d_imm;

    logic d_pc_wen;
    logic [`DATA_ADDR_SIZE-1:0] d_branch_target;
    logic [6:0] d_opcode;
    logic [2:0] d_funct3;
    logic [6:0] d_funct7;
    logic d_writes_rd;
    logic d_is_store;
    logic d_is_load;
    logic d_fwd_aluout_rs1;
    logic d_fwd_aluout_rs2;
    logic d_fwd_rfwdata_rs1;
    logic d_fwd_rfwdata_rs2;

    // Hazard signals
    logic hzd_stall_f;
    logic hzd_nop_d;

    // A-stage signals
    logic [`DATA_WORD_SIZE-1:0] a_aluout;
    logic [`DATA_WORD_SIZE-1:0] a_rs2_data;
    logic a_is_store;
    logic a_is_load;
    logic a_writes_rd;
    logic [4:0] a_rf_waddr_d;
    logic a_btaken;

    // M-stage signals
    logic [`DATA_WORD_SIZE-1:0] m_dmem_rdata;
    logic m_is_load;
    logic m_writes_rd;
    logic [`DATA_WORD_SIZE-1:0] m_aluout;
    logic [4:0] m_rf_waddr_d;

    // ## datapath

    assign imem_raddr = pc;

    // ## modules
    // ### common

    memory_bank imem(
        .clk(clk),
        .rst(imem_rst),
        .wen(imem_w_en),
        .waddr(imem_waddr),
        .wdata(imem_wdata),
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
        .run(run),
        .stall(hzd_stall_f),
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

        .f_pc(pc),
        .f_ir(ir),

        .a_is_load(a_is_load),
        .a_writes_rd(a_writes_rd),
        .a_rf_waddr_d(a_rf_waddr_d),

        .m_writes_rd(m_writes_rd),
        .m_rf_waddr_d(m_rf_waddr_d),
        .rf_wdata(rf_wdata),

        .branch_taken(a_btaken),
        .hzd_nop_d(hzd_nop_d),

        .rf_raddr_a(rf_raddr_a),
        .rf_raddr_b(rf_raddr_b),
        .rf_rdata_a(rf_rdata_a),
        .rf_rdata_b(rf_rdata_b),

        .d_rf_waddr_d(d_rf_waddr_d),
        .d_rs1_data(d_rs1_data),
        .d_rs2_data(d_rs2_data),
        .d_aluin_b_is_imm(d_aluin_b_is_imm),
        .d_imm(d_imm),
        .d_pc_wen(d_pc_wen),
        .d_branch_target(d_branch_target),
        .d_opcode(d_opcode),
        .d_funct3(d_funct3),
        .d_funct7(d_funct7),
        .d_writes_rd(d_writes_rd),
        .d_is_store(d_is_store),
        .d_is_load(d_is_load),
        .d_fwd_aluout_rs1(d_fwd_aluout_rs1),
        .d_fwd_aluout_rs2(d_fwd_aluout_rs2),
        .d_fwd_rfwdata_rs1(d_fwd_rfwdata_rs1),
        .d_fwd_rfwdata_rs2(d_fwd_rfwdata_rs2)
    );

    hzd_checker hzd_checker (
        .rf_r_rs1     (rf_raddr_a),
        .rf_r_rs2     (rf_raddr_b),
        .d_is_load    (d_is_load),
        .d_rf_waddr_d (d_rf_waddr_d),
        .hzd_stall_f  (hzd_stall_f),
        .hzd_nop_d    (hzd_nop_d)
    );

    a_stage a_stage(
        .clk(clk),
        .rst(rst),

        .d_rs1_data(d_rs1_data),
        .d_rs2_data(d_rs2_data),
        .d_aluin_b_is_imm(d_aluin_b_is_imm),
        .d_imm(d_imm),
        .d_opcode(d_opcode),
        .d_funct3(d_funct3),
        .d_funct7(d_funct7),
        .d_is_store(d_is_store),
        .d_is_load(d_is_load),
        .d_writes_rd(d_writes_rd),
        .d_rf_waddr_d(d_rf_waddr_d),
        .d_fwd_aluout_rs1(d_fwd_aluout_rs1),
        .d_fwd_aluout_rs2(d_fwd_aluout_rs2),
        .d_fwd_rfwdata_rs1(d_fwd_rfwdata_rs1),
        .d_fwd_rfwdata_rs2(d_fwd_rfwdata_rs2),
        .rf_wdata(rf_wdata),

        .a_aluout(a_aluout),
        .a_rs2_data(a_rs2_data),
        .a_btaken(a_btaken),
        .a_is_store(a_is_store),
        .a_is_load(a_is_load),
        .a_writes_rd(a_writes_rd),
        .a_rf_waddr_d(a_rf_waddr_d)
    );

    m_stage m_stage (
    	.clk        (clk),
    	.rst        (rst),
    	.run        (run),

    	.a_is_store (a_is_store),
    	.a_aluout   (a_aluout),
    	.a_rs2_data  (a_rs2_data),
        .a_is_load(a_is_load),
        .a_writes_rd(a_writes_rd),
        .a_rf_waddr_d(a_rf_waddr_d),

        .dmem_rdata_port(dmem_rdata),
    	.dmem_wen   (dmem_wen),
    	.dmem_rwaddr(dmem_rwaddr),
    	.dmem_wdata (dmem_wdata),

        .m_dmem_rdata(m_dmem_rdata),
        .m_is_load(m_is_load),
        .m_writes_rd(m_writes_rd),
        .m_aluout(m_aluout),
        .m_rf_waddr_d(m_rf_waddr_d)
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
