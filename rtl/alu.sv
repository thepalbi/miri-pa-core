`timescale 1ns / 1ps

`include "constants.sv"

module alu #(
    parameter word_size = `DATA_WORD_SIZE
) (
    input [word_size-1:0] input1,
    input [word_size-1:0] input2,

    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,

    output logic [word_size-1:0] result,
    output logic taken
);

    always_comb begin
        result = 0;
        taken = 0;

        if (opcode == `OPCODE_OP) begin
            if (funct7 == `F7_BASE && funct3 == `F3_ADD_SUB) begin
                result = input1 + input2;
            end
            else if (funct7 == `F7_SUB && funct3 == `F3_ADD_SUB) begin
                result = input1 - input2;
            end
            else if (funct7 == `F7_BASE && funct3 == `F3_XOR) begin
                result = input1 ^ input2;
            end
            else if (funct7 == `F7_BASE && funct3 == `F3_OR) begin
                result = input1 | input2;
            end
            else if (funct7 == `F7_BASE && funct3 == `F3_AND) begin
                result = input1 & input2;
            end
            else if (funct7 == `F7_MULDIV && funct3 == `F3_MUL) begin
                result = input1 * input2;
            end
            else if (funct7 == `F7_MULDIV && funct3 == `F3_DIV) begin
                // RISC-V: dividing by 0, becomes '1
                if (input2 == 0) begin
                    result = '1;
                end
                // RISC-V: -2^31 / -1, stays -2^31
                else if (input1 == {1'b1, {(word_size-1){1'b0}}} && input2 == '1) begin
                    result = input1;
                end
                else begin
                    result = $signed(input1) / $signed(input2);
                end
            end
        end
        else if (opcode == `OPCODE_OP_IMM) begin
            if (funct3 == `F3_ADD_SUB) begin
                result = input1 + input2;
            end
        end
        else if (opcode == `OPCODE_LOAD) begin
            result = input1 + input2;
        end
        else if (opcode == `OPCODE_STORE) begin
            result = input1 + input2;
        end
        else if (opcode == `OPCODE_BRANCH) begin
            if (funct3 == `F3_BEQ && input1 == input2) begin
                taken = 1;
            end
        end
    end

endmodule
