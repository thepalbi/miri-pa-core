from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from test_programs import load_imem, reset_core, run_program

VERILOG_SOURCES = "core_top.sv decoder.sv alu.sv register_file.sv memory.sv pc_reg.sv"
TOPMODEL = "core_top"

TB_ROOT = Path(__file__).resolve().parent
PROGRAMS = TB_ROOT / "test_programs"


@cocotb.test()
async def test_addi(dut):

    program = [
        0b00000000010100000000000010010011,  # addi x1, x0, 5
        0b00000000011100001000000100010011,  # addi x2, x1, 7
    ]

    Clock(dut.clk, 10, unit="ns").start()
    await reset_core(dut)
    await load_imem(dut, program)

    # Let core run (PC starts on IMEM '0)
    dut.run.value = 1
    await ClockCycles(dut.clk, 10)

    assert dut.rf.regs[1].value == 5
    assert dut.rf.regs[2].value == 12


@cocotb.test()
async def test_beq_taken(dut):

    program = [
        0b00000000010100000000000010010011,  # addi x1, x0, 5
        0b00000000010100000000000100010011,  # addi x2, x0, 5
        0b00000000001000001000010001100011,  # beq  x1, x2, +8  (skip next instruction)
        0b00000000000100000000000110010011,  # addi x3, x0, 1
        0b00000000001000000000001000010011,  # addi x4, x0, 2
    ]

    Clock(dut.clk, 10, unit="ns").start()
    await reset_core(dut)
    await load_imem(dut, program)

    # Let core run (PC starts on IMEM '0)
    dut.run.value = 1
    await ClockCycles(dut.clk, 10)

    assert dut.rf.regs[1].value == 5
    assert dut.rf.regs[2].value == 5
    assert dut.rf.regs[3].value == 0
    assert dut.rf.regs[4].value == 2


@cocotb.test()
async def test_loop_from_s_file(dut):
    await run_program(dut, PROGRAMS / "test.S", cycles=80)


@cocotb.test()
async def test_inline_asm(dut):
    await run_program(
        dut,
        """
        addi x1, x0, 5
        addi x2, x1, 7
        """,
        cycles=10,
    )

    assert dut.rf.regs[1].value == 5
    assert dut.rf.regs[2].value == 12


@cocotb.test()
async def test_dmem_preload(dut):
    await run_program(
        dut,
        """
        # !dmem[0x10] = 40
        # !dmem[0x14] = 2

        li   x5, 0x10
        nop; nop; nop
        lw   x6, 0(x5)
        nop; nop; nop
        lw   x7, 4(x5)
        nop; nop; nop
        add  x28, x6, x7
        jal  x0, 0

        # ?rf[28] == 42
        # ?dmem[0x10] == 40
        """,
        cycles=40,
    )


def discover_tests_under_path(path: Path) -> list[Path]:
    paths = []
    for p in path.glob("*.S"):
        if p.is_file():
            paths.append(p)
    return paths

@cocotb.test()
@cocotb.parametrize(
    case=[cocotb.Param(p, name=p.stem) for p in discover_tests_under_path(PROGRAMS / "test_forwardings")],
)
async def test_alu_instructions(dut, case: Path):
    await run_program(dut, case, cycles=80)
