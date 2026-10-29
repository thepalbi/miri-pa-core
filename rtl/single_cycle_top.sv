`timescale 1ns / 1ps

`include "constants.sv"

module single_cycle_top (
    input logic clk,
    input logic rst,
    input logic imem_w_en,
    input logic [`DATA_ADDR_SIZE-1:0] imem_addr,
    input logic [`DATA_WORD_SIZE-1:0] imem_d
);

    // decoder signals
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic writes_rd;
    logic is_store;
    logic is_load;
    logic [11:0] imm;
    logic [20:0] offset;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [word_size-1:0] rf_a;
    logic [word_size-1:0] rf_b;
    logic [word_size-1:0] rf_d;

    logic [DATA_WORD_SIZE-1:0] alu_out;
    logic [DATA_WORD_SIZE-1:0] dmem_d_out;
    logic [DATA_ADDR_SIZE-1:0] pc;
    logic [DATA_WORD_SIZE-1:0] ir;
    logic [DATA_ADDR_SIZE-1:0] offset_eff;
    logic [`DATA_ADDR_SIZE-1:0] dmem_rw_addr;

    logic branch_taken;

    assign offset_eff = offset[DATA_ADDR_SIZE-1:0];

    assign rf_d = is_load ? dmem_d_out : alu_out;
    assign dmem_rw_addr = alu_out[`DATA_ADDR_SIZE-1:0];

    // PC block
    logic pc_w_en;
    logic [`DATA_ADDR_SIZE-1:0] branch_target;
    assign branch_target = (pc + offset_eff)[DATA_ADDR_SIZE-1:0];
    assign pc_w_en = branch_taken | (opcode == OPCODE_JAL);

    // decoder consumes all top-instantiated wires since they have
    // identical name.
    decoder dec(.*);

    pc pc_mod(
        .clk(clk),
        .w_en(pc_w_en),
        .addr_in(branch_target),
        .out(pc)
    );

    memory_bank imem(
        .clk(clk),
        .rst(rst),
        .w_en(imem_w_en),
        .w_addr(imem_addr),
        .r_addr(pc),
        .d_out(ir)
    );


    memory_bank dmem(
        .clk(clk),
        .rst(rst),
        .w_en(is_store),
        .w_addr(dmem_rw_addr),
        .r_addr(dmem_rw_addr),
        .d_out(dmem_d_out)
    );

    logic [`DATA_WORD_SIZE-1:0] imm_sign_extended;
    logic [`DATA_WORD_SIZE-1:0] alu_input2;
    assign imm_sign_extended = {{ 20{imm[11]} }, imm};
    assign alu_input2 = (is_load || is_store) ?
        imm_sign_extended : rf_b;

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
        .w_en(writes_rd),
        .rd(rd),
        .d(rf_d),
        .ra(rs1),
        .rb(rs2),
        .a(rf_a),
        .b(rf_b),
    );

endmodule
