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

    def to_ir_input(self) -> int:
        return int(assembler.convert(self.instr)[0], 2)

CASES = [
    TestCase(
        instr="add x1, x2, x3",
        hasRd=True,
        rd=1,
        rs1=2,
        rs2=3
    ),
    TestCase(
        instr="lw x1, 10(x2)",
        isLoad=True,
        hasRd=True,
        rd=1,
        rs1=2,
        offset_or_imm=10,
    ),
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

