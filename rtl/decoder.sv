`timescale 1ns / 1ps

`include "constants.sv"

module decoder (
    input logic [31:0] ir,

    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic writes_rd,
    output logic is_store,
    output logic is_load,
    output logic [`DATA_WORD_SIZE-1:0] imm,
    output logic [20:0] offset,
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7
);
    localparam int IMM_SIZE = 12;

    logic [IMM_SIZE-1:0] imm_12;

    assign opcode = ir[6:0];
    assign funct3 = ir[14:12];
    assign funct7 = ir[31:25];
    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign rd = ir[11:7];

    assign writes_rd    = (opcode == `OPCODE_OP_IMM) || (opcode == `OPCODE_OP) || (opcode == `OPCODE_LOAD ) || (opcode == `OPCODE_JAL);
    assign is_load      = opcode == `OPCODE_LOAD;
    assign is_store     = opcode == `OPCODE_STORE;

    always_comb begin: offset_pick
        offset = 21'b0;
        if (opcode == `OPCODE_JAL)
            // For computing the JAL and BRANCH offset, as our machine limits offsets due
            // to the 12bit address space (4096 addresses), we keep just the 
            // lower part of the offset - sign extended.
            offset = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
        else if (opcode == `OPCODE_BRANCH)
            // Branch needs sign extending of 8 bits
            offset = { { 8{ir[31]} }, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
    end

    sign_extender #(.tgt_size(`DATA_WORD_SIZE), .src_size(IMM_SIZE)) se(
        .src(imm_12),
        .tgt(imm)
    );

    always_comb begin: imm_pick
        imm_12 = 0;
        if (opcode  == `OPCODE_OP_IMM || opcode == `OPCODE_LOAD)
            imm_12 = ir[31:20];
        else if (opcode == `OPCODE_STORE)
            imm_12 = {ir[31:25], ir[11:7]};
    end

endmodule
