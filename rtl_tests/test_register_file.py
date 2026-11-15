import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

# Small values exercised across several registers (32-bit words per constants.sv).
test_values = [
    0x0A,
    0x0B,
    0x0C,
    0x0D,
    0x0E,
    0x0F,
    0x1F,
    0xFF,
]

VERILOG_SOURCES = "register_file.sv"
TOPMODEL = "register_file"


async def reset_dut(dut):
    dut.rst.value = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst.value = 0


@cocotb.test()
async def test_write_then_read(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write these values: %s", test_values)

    await Timer(20, unit="ns")
    await reset_dut(dut)

    dut.wen.value = 1
    for i, value in enumerate(test_values, start=1):
        await FallingEdge(dut.clk)
        dut.waddr_d.value = i
        dut.wdata_d.value = value

    await FallingEdge(dut.clk)

    dut.wen.value = 0
    for i, value in enumerate(test_values, start=1):
        dut.raddr_a.value = i
        dut.raddr_b.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.rdata_a.value == value, f"expected reg[{i}] (port a) to be {value}"
        assert dut.rdata_b.value == value, f"expected reg[{i}] (port b) to be {value}"


@cocotb.test()
async def test_write_read_interleaved(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write these values: %s", test_values)

    await Timer(20, unit="ns")
    await reset_dut(dut)
    await FallingEdge(dut.clk)

    for i, value in enumerate(test_values, start=1):
        dut.wen.value = 1
        dut.waddr_d.value = i
        dut.wdata_d.value = value
        await FallingEdge(dut.clk)

        dut.wen.value = 0
        dut.raddr_a.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.rdata_a.value == value, f"expected reg[{i}] to be {value}"

        await FallingEdge(dut.clk)


@cocotb.test()
async def test_zero_register_ignores_writes(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await Timer(20, unit="ns")
    await reset_dut(dut)

    dut.wen.value = 1
    await FallingEdge(dut.clk)
    dut.waddr_d.value = 0
    dut.wdata_d.value = 0xFF

    await FallingEdge(dut.clk)

    dut.wen.value = 0
    dut.raddr_a.value = 0
    await RisingEdge(dut.clk)
    await Timer(2, unit="ns")
    assert dut.rdata_a.value == 0, "reg[0] should stay zero even after a write attempt"
