`timescale 1ns / 1ps

localparam [6:0] OP_IMM = 7'b0010011;
localparam [6:0] OP     = 7'b0110011;
localparam [6:0] STORE  = 7'b0100011;
localparam [6:0] LOAD   = 7'b0000011;
localparam [6:0] BRANCH = 7'b1100011;
localparam [6:0] JAL    = 7'b1101111;

module decoder (
    input [31:0] ir,

    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output hasRd,
    output isStore,
    output isLoad,
    output logic [11:0] imm,
    output logic [20:0] offset
);
    logic [6:0] opcode;

    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign rd = ir[11:7];

    assign hasRd  = (opcode == OP_IMM) | (opcode == OP) | (opcode == LOAD ) | (opcode == JAL);
    assign isLoad  = opcode == LOAD;
    assign isStore = opcode == STORE;

    assign opcode = ir[6:0];
    always_comb begin
        // Defaults if no branch is matched, to avoid inferring latch
        imm = 12'b0;
        offset = 21'b0;
        case (opcode)
            // TODO: Can we merge this two branches in the case statement ? 
            OP_IMM: imm = {ir[31:20]};
            STORE:  imm = {ir[31:25], ir[11:7]};
            LOAD:   imm = {ir[31:20]};

            // For computing the JAL and BRANCH offset, as our machine limits offsets due
            // to the 12bit address space (4096 addresses), we keep just the 
            // lower part of the offset - sign extended.
            JAL:    offset = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
            // Branch needs sign extending of 8 bits
            BRANCH: offset = { { 8{ir[31]} }, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};

            default: begin
                // TODO: How to better handle this ?
                imm = 12'b0;
                offset = 21'b0;
            end
        endcase
    end

endmodule
