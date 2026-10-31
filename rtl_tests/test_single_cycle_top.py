from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from test_programs.loader import (
    load_imem,
    program_from_bin,
    program_from_elf_text,
    reset_core,
)

VERILOG_SOURCES = "single_cycle_top.sv decoder.sv alu.sv register_file.sv memory.sv pc_reg.sv"
TOPMODEL = "single_cycle_top"

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
async def test_loop_from_assembled_elf(dut):
    """
    Build (from rtl_tests/test_programs):
      docker run -v `pwd`:/work -w /work pwn2de4d/riscv-toolchain:latest \\
        /opt/riscv32/bin/riscv32-unknown-linux-gnu-as -march=rv32im -o test test.S
    Optional flat binary (no ELF header/footer):
      ... objcopy -O binary -j .text test test.bin
    """
    elf_path = PROGRAMS / "test"
    bin_path = PROGRAMS / "test.bin"
    if bin_path.is_file():
        program = program_from_bin(bin_path)
    elif elf_path.is_file():
        program = program_from_elf_text(elf_path)
    else:
        cocotb.log.warning("skip test_loop_from_assembled_elf: no test or test.bin")
        return

    Clock(dut.clk, 10, unit="ns").start()
    await reset_core(dut)
    await load_imem(dut, program)

    dut.run.value = 1
    await ClockCycles(dut.clk, 80)

    assert dut.rf.regs[1].value == 0
    assert dut.rf.regs[2].value == 20
