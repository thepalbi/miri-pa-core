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

    dut.w_en.value = 1
    for i, value in enumerate(test_values, start=1):
        await FallingEdge(dut.clk)
        dut.rd.value = i
        dut.d.value = value

    await FallingEdge(dut.clk)

    dut.w_en.value = 0
    for i, value in enumerate(test_values, start=1):
        dut.ra.value = i
        dut.rb.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.a.value == value, f"expected reg[{i}] (port a) to be {value}"
        assert dut.b.value == value, f"expected reg[{i}] (port b) to be {value}"


@cocotb.test()
async def test_write_read_interleaved(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write these values: %s", test_values)

    await Timer(20, unit="ns")
    await reset_dut(dut)
    await FallingEdge(dut.clk)

    for i, value in enumerate(test_values, start=1):
        dut.w_en.value = 1
        dut.rd.value = i
        dut.d.value = value
        await FallingEdge(dut.clk)

        dut.w_en.value = 0
        dut.ra.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.a.value == value, f"expected reg[{i}] to be {value}"

        await FallingEdge(dut.clk)


@cocotb.test()
async def test_zero_register_ignores_writes(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await Timer(20, unit="ns")
    await reset_dut(dut)

    dut.w_en.value = 1
    await FallingEdge(dut.clk)
    dut.rd.value = 0
    dut.d.value = 0xFF

    await FallingEdge(dut.clk)

    dut.w_en.value = 0
    dut.ra.value = 0
    await RisingEdge(dut.clk)
    await Timer(2, unit="ns")
    assert dut.a.value == 0, "reg[0] should stay zero even after a write attempt"
