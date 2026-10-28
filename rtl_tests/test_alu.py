import cocotb
from cocotb.triggers import Timer
from dataclasses import dataclass

VERILOG_SOURCES = "alu.sv"
TOPMODEL = "alu"

# RV32I opcodes, mirroring alu.sv / decoder.sv.
OP_IMM = 0b0010011
OP = 0b0110011
STORE = 0b0100011
LOAD = 0b0000011
BRANCH = 0b1100011

# (opcode, funct3, funct7) for each supported instruction. mul / div are RV32M.
ENCODINGS = {
    "add": (OP, 0b000, 0b0000000),
    "sub": (OP, 0b000, 0b0100000),
    "mul": (OP, 0b000, 0b0000001),
    "div": (OP, 0b100, 0b0000001),
    "and": (OP, 0b111, 0b0000000),
    "or": (OP, 0b110, 0b0000000),
    "xor": (OP, 0b100, 0b0000000),
    "addi": (OP_IMM, 0b000, 0b0000000),
    "lw": (LOAD, 0b010, 0b0000000),
    "sw": (STORE, 0b010, 0b0000000),
    "beq": (BRANCH, 0b000, 0b0000000),
}

INT_MIN = 0x80000000


def u32(x: int) -> int:
    """Two's complement 32-bit view of x, so negative values can be written naturally."""
    return x & 0xFFFFFFFF


@dataclass
class TestCase:
    name: str
    instr: str
    input1: int
    input2: int
    result: int
    taken: bool = False
    # Overrides the instruction's funct7, e.g. for I-type where it holds immediate bits
    funct7: int | None = None


CASES = [
    # ---- R-type ALU ----------------------------------------------------
    TestCase("add", "add", 2, 3, 5),
    TestCase("add_negative", "add", u32(-10), 4, u32(-6)),
    TestCase("add_wraparound", "add", 0xFFFFFFFF, 1, 0),
    # Equal inputs must not raise taken outside of beq
    TestCase("add_equal_inputs", "add", 7, 7, 14),
    TestCase("sub", "sub", 10, 4, 6),
    TestCase("sub_negative_result", "sub", 3, 5, u32(-2)),
    TestCase("and", "and", 0xF0F0F0F0, 0xFF00FF00, 0xF000F000),
    TestCase("or", "or", 0xF0F0F0F0, 0xFF00FF00, 0xFFF0FFF0),
    TestCase("xor", "xor", 0xF0F0F0F0, 0xFF00FF00, 0x0FF00FF0),
    # ---- R-type RV32M --------------------------------------------------
    TestCase("mul", "mul", 6, 7, 42),
    TestCase("mul_negative", "mul", u32(-6), 7, u32(-42)),
    TestCase("mul_overflow", "mul", 0x10000, 0x10001, 0x10000),
    TestCase("div", "div", 42, 6, 7),
    TestCase("div_truncates_toward_zero", "div", u32(-7), 2, u32(-3)),
    TestCase("div_by_zero", "div", 42, 0, 0xFFFFFFFF),
    TestCase("div_overflow", "div", INT_MIN, u32(-1), INT_MIN),
    # ---- I-type --------------------------------------------------------
    TestCase("addi", "addi", 5, u32(-1), 4),
    # imm[11:5] lands in the funct7 bits; 0b0100000 must not turn addi into a sub
    TestCase("addi_funct7_is_imm", "addi", 5, 0x400, 0x405, funct7=0b0100000),
    TestCase("lw_address", "lw", 0x100, 0x10, 0x110),
    # ---- S-type --------------------------------------------------------
    TestCase("sw_address", "sw", 0x100, u32(-4), 0xFC),
    # ---- B-type --------------------------------------------------------
    TestCase("beq_taken", "beq", 0x1234, 0x1234, 0, taken=True),
    TestCase("beq_not_taken", "beq", 0x1234, 0x4321, 0),
]


@cocotb.test()
@cocotb.parametrize(
    case=[cocotb.Param(c, name=c.name) for c in CASES],
)
async def test_alu_instructions(dut, case: TestCase):
    opcode, funct3, funct7 = ENCODINGS[case.instr]
    dut.input1.value = case.input1
    dut.input2.value = case.input2
    dut.opcode.value = opcode
    dut.funct3.value = funct3
    dut.funct7.value = funct7 if case.funct7 is None else case.funct7
    await Timer(2, unit="ns")
    assert dut.result.value == case.result, f"result mismatch: {dut.result.value} != {case.result:#x}"
    assert dut.taken.value == int(case.taken), f"taken mismatch: {dut.taken.value} != {int(case.taken)}"
