`timescale 1ns / 1ps

`include "constants.sv"

module a_stage(
    (* unused *) input logic clk,
    (* unused *) input logic rst,

    input logic [`DATA_WORD_SIZE-1:0] d_aluin_a,
    input logic [`DATA_WORD_SIZE-1:0] d_aluin_b,
    input logic [6:0] d_opcode,
    input logic [2:0] d_funct3,
    input logic [6:0] d_funct7,

    output logic [`DATA_WORD_SIZE-1:0] aluout,
    output logic btaken
);

    alu alu(
        .input1(d_aluin_a),
        .input2(d_aluin_b),
        .opcode(d_opcode),
        .funct3(d_funct3),
        .funct7(d_funct7),
        .result(aluout),
        .taken(btaken)
    );


endmodule
