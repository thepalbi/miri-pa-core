`timescale 1ns / 1ps

localparam [6:0] OP_IMM = 7'b0010011;
localparam [6:0] OP     = 7'b0110011;
localparam [6:0] STORE  = 7'b0100011;
localparam [6:0] LOAD   = 7'b0000011;
localparam [6:0] BRANCH = 7'b1100011;

module decoder (
    input [31:0] ir,

    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output hasRd,
    output isStore,
    output isLoad,
    output [12:0] offset_or_imm
);
    logic [6:0] opcode;
    logic [12:0] offset;
    logic offset_sign;

    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign rd = ir[11:7];

    assign hasRd  = (opcode == OP_IMM) | (opcode == OP) | (opcode == LOAD );
    assign isLoad  = opcode == LOAD;
    assign isStore = opcode == STORE;

    assign offset_or_imm = offset;
    assign offset_sign = ir[31];

    assign opcode = ir[6:0];
    always_comb begin
        case (opcode)
            // TODO: Can we merge this two branches in the case statement ? 
            OP_IMM: offset = {offset_sign, ir[31:20]};
            LOAD: offset = {offset_sign, ir[31:20]};

            BRANCH: offset = {offset_sign, ir[7], ir[30:25], ir[11:8], 1'b0};
            STORE:  offset = {offset_sign, ir[31:25], ir[11:7]};
            default: offset = 13'b0;
        endcase
    end

endmodule
