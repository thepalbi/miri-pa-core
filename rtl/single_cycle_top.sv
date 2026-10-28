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

    // decoder consumes all top-instantaited wires since they have
    // identical name.
    decoder dec(.*);

    logic [word_size-1:0] rf_a;
    logic [word_size-1:0] rf_b;
    logic [word_size-1:0] rf_d;

    memory_bank imem(
        .clk(clk),
        .rst(rst),
        .w_en(imem_w_en),
        .w_addr(imem_addr),
        .r_addr(?),
        .d_out(?)
    );

    memory_bank dmem(
        .clk(clk),
        .rst(rst),
        .w_end(?),
        .w_addr(?),
        .r_addr(?),
        .d_out(?)
    );

    memory_bank dmem();

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
