`timescale 1ns / 1ps

localparam [6:0] OP_IMM = 7'b0010011;
localparam [6:0] OP     = 7'b0110011;
localparam [6:0] STORE  = 7'b0100011;
localparam [6:0] LOAD   = 7'b0000011;
localparam [6:0] BRANCH = 7'b1100011;
localparam [6:0] JAL    = 7'b1101111;

module decoder (
    input logic [31:0] ir,

    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic writes_rd,
    output logic is_store,
    output logic is_load,
    output logic [11:0] imm,
    output logic [20:0] offset,
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7
);
    assign opcode = ir[6:0];
    assign funct3 = ir[14:12];
    assign funct7 = ir[31:25];
    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign rd = ir[11:7];

    assign writes_rd    = (opcode == OP_IMM) || (opcode == OP) || (opcode == LOAD ) || (opcode == JAL);
    assign is_load      = opcode == LOAD;
    assign is_store     = opcode == STORE;

    always_comb begin: offset_pick
        offset = 21'b0;
        if (opcode == JAL)
            // For computing the JAL and BRANCH offset, as our machine limits offsets due
            // to the 12bit address space (4096 addresses), we keep just the 
            // lower part of the offset - sign extended.
            offset = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
        else if (opcode == BRANCH)
            // Branch needs sign extending of 8 bits
            offset = { { 8{ir[31]} }, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
    end

    always_comb begin: imm_pick
        imm = 12'b0;
        if (opcode  == OP_IMM || opcode == LOAD)
            imm = ir[31:20];
        else if (opcode == STORE)
            imm = {ir[31:25], ir[11:7]};
    end

endmodule
