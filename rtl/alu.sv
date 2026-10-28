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

    always_comb begin: result_pick
        result = '0;
        case (opcode)
            `OPCODE_OP:
                case ({funct7, funct3})
                    {`F7_BASE, `F3_ADD_SUB}: result = input1 + input2;
                    {`F7_SUB, `F3_ADD_SUB}:  result = input1 - input2;
                    {`F7_BASE, `F3_XOR}:     result = input1 ^ input2;
                    {`F7_BASE, `F3_OR}:      result = input1 | input2;
                    {`F7_BASE, `F3_AND}:     result = input1 & input2;
                    {`F7_MULDIV, `F3_MUL}:   result = input1 * input2;
                    {`F7_MULDIV, `F3_DIV}:
                        // RISC-V defines x / 0 as all ones, and INT_MIN / -1 as INT_MIN
                        // (Verilator returns 0 for both).
                        if (input2 == 0)
                            result = '1;
                        else if (input1 == {1'b1, {(word_size-1){1'b0}}} && input2 == '1)
                            result = input1;
                        else
                            result = $signed(input1) / $signed(input2);
                    default: ;
                endcase
            `OPCODE_OP_IMM:
                if (funct3 == `F3_ADD_SUB)
                    result = input1 + input2;
            // lw / sw address: base + offset
            `OPCODE_LOAD, `OPCODE_STORE: result = input1 + input2;
            default: ;
        endcase
    end

    assign taken = (opcode == `OPCODE_BRANCH) && (funct3 == `F3_BEQ) && (input1 == input2);

endmodule
