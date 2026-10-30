import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

VERILOG_SOURCES = "single_cycle_top.sv decoder.sv alu.sv register_file.sv memory.sv pc_reg.sv"
TOPMODEL = "single_cycle_top"

@cocotb.test()
async def test_addi(dut):

    program = [
        0b00000000010100000000000010010011,  # addi x1, x0, 5
        0b00000000011100001000000100010011,  # addi x2, x1, 7
    ]

    Clock(dut.clk, 10, unit="ns").start()

    # Reset state
    dut.run.value = 0
    dut.imem_w_en.value = 0
    dut.imem_addr.value = 0
    dut.imem_d.value = 0
    dut.rst.value = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst.value = 0

    # Write program into IMEM
    dut.imem_w_en.value = 1
    for i, instr in enumerate(program):
        dut.imem_addr.value = i + 1
        dut.imem_d.value = instr
        await FallingEdge(dut.clk)

    # Let core run (PC starts on IMEM '0)
    dut.imem_w_en.value = 0
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

    # Reset state
    dut.run.value = 0
    dut.imem_w_en.value = 0
    dut.imem_addr.value = 0
    dut.imem_d.value = 0
    dut.rst.value = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst.value = 0

    # Write program into IMEM
    dut.imem_w_en.value = 1
    for i, instr in enumerate(program):
        dut.imem_addr.value = i + 1
        dut.imem_d.value = instr
        await FallingEdge(dut.clk)

    # Let core run (PC starts on IMEM '0)
    dut.imem_w_en.value = 0
    dut.run.value = 1
    await ClockCycles(dut.clk, 10)

    assert dut.rf.regs[1].value == 5
    assert dut.rf.regs[2].value == 5
    assert dut.rf.regs[3].value == 0
    assert dut.rf.regs[4].value == 2
