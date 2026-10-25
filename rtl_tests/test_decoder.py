import cocotb
from cocotb.triggers import Timer
from riscv_assembler.convert import AssemblyConverter
from dataclasses import dataclass

VERILOG_SOURCES = f"decoder.sv"
TOPMODEL = "decoder"

assembler = AssemblyConverter(output_mode="a", nibble_mode=False)

@dataclass
class TestCase:
    instr: str
    isStore: bool = False
    isLoad: bool = False
    hasRd: bool = False
    rd: int | None = None
    rs1: int | None = None
    rs2: int | None = None
    offset_or_imm: int | None = None
    # Optional literal 32-bit IR. When set, it is driven onto the DUT directly,
    # bypassing the assembler. Used for control-flow instructions (beq, jal),
    # whose offsets the assembler only accepts via code labels.
    raw_ir: int | None = None

    def to_ir_input(self) -> int:
        if self.raw_ir is not None:
            return self.raw_ir
        return int(assembler.convert(self.instr)[0], 2)

CASES = [
    # ---- S-type  -------------------------------------------------------
    TestCase(
        instr="sw x1, 10(x2)",
        isStore=True,
        hasRd=False,
        rs1=2,
        rs2=1,
        offset_or_imm=10,
    ),
    TestCase(
        instr="sw x20, -20(x31)",
        isStore=True,
        hasRd=False,
        rs1=31,
        rs2=20,
        offset_or_imm=-20,
    ),
    # ---- I-type immediate ALU ------------------------------------------
    TestCase(
        instr="addi x5, x6, 25",
        hasRd=True,
        rd=5,
        rs1=6,
        offset_or_imm=25,
    ),
    TestCase(
        instr="lw x1, 10(x2)",
        isLoad=True,
        hasRd=True,
        rd=1,
        rs1=2,
        offset_or_imm=10,
    ),
    # ---- R-type ALU (base + M-extension) ------------------------------
    TestCase(
        instr="add x1, x2, x3",
        hasRd=True,
        rd=1,
        rs1=2,
        rs2=3
    ),
    TestCase(
        instr="sub x7, x8, x9",
        hasRd=True,
        rd=7,
        rs1=8,
        rs2=9,
    ),
    TestCase(
        instr="mul x10, x11, x12",
        hasRd=True,
        rd=10,
        rs1=11,
        rs2=12,
    ),
    TestCase(
        instr="div x10, x11, x12",
        hasRd=True,
        rd=10,
        rs1=11,
        rs2=12,
    ),
    TestCase(
        instr="and x13, x14, x15",
        hasRd=True,
        rd=13,
        rs1=14,
        rs2=15,
    ),
    TestCase(
        instr="or x13, x14, x15",
        hasRd=True,
        rd=13,
        rs1=14,
        rs2=15,
    ),
    TestCase(
        instr="xor x13, x14, x15",
        hasRd=True,
        rd=13,
        rs1=14,
        rs2=15,
    ),
    # ---- B-type branch -------------------------------------------------
    # beq x16, x17, +8  ->  0x01180463
    TestCase(
        instr="beq x16, x17, +8",
        hasRd=False,
        rs1=16,
        rs2=17,
        offset_or_imm=8,
        raw_ir=0b00000001000110000000010001100011,
    ),
    # ---- J-type jump (RVI jal) -----------------------------------------
    # jal x1, +8  ->  0x008000EF
    # jal stores the link (PC+4) in rd, so hasRd is True. The decoder does not
    # yet implement the JAL opcode, so this test is expected to fail on
    # hasRd / offset_or_imm until JAL decoding is added.
    TestCase(
        instr="jal x1, +8",
        hasRd=True,
        rd=1,
        offset_or_imm=8,
        raw_ir=0b00000000100000000000000011101111,
    ),
]

@cocotb.test()
@cocotb.parametrize(
    case=[cocotb.Param(c, name=c.instr) for c in CASES],
)
async def test_decoder_instructions(dut, case: TestCase):
    dut.ir.value = case.to_ir_input()
    await Timer(2, unit="ns")  # TODO: Fix how much to wait for purely comb logic
    assert dut.hasRd.value == int(case.hasRd)
    assert dut.isLoad.value == int(case.isLoad)
    assert dut.isStore.value == int(case.isStore)
    for attr in ['rd', 'rs1', 'rs2', 'offset_or_imm']:
        case_value = getattr(case, attr)
        if case_value is not None:
            dut_value = getattr(dut, attr).value
            assert dut_value == case_value, f"{attr} in dut does not match expected value: {dut_value} != {case_value}"

