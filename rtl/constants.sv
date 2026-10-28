`define DATA_WORD_SIZE 32
`define DATA_ADDR_SIZE 12

`define REG_ADDR_SIZE 5

// RV32I opcodes
`define OPCODE_OP_IMM 7'b0010011
`define OPCODE_OP     7'b0110011
`define OPCODE_STORE  7'b0100011
`define OPCODE_LOAD   7'b0000011
`define OPCODE_BRANCH 7'b1100011
`define OPCODE_JAL    7'b1101111

// funct3 / funct7 encodings
`define F3_ADD_SUB 3'b000
`define F3_XOR     3'b100
`define F3_OR      3'b110
`define F3_AND     3'b111
`define F3_MUL     3'b000
`define F3_DIV     3'b100
`define F3_BEQ     3'b000

`define F7_BASE   7'b0000000
`define F7_SUB    7'b0100000
`define F7_MULDIV 7'b0000001
