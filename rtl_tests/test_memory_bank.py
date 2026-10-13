import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

# Small word values exercised across several addresses (32-bit words per constants.sv).
test_words = [
    0x0A,
    0x0B,
    0x0C,
    0x0D,
    0x0E,
    0x0F,
    0x1F,
    0xFF,
]

RTL_DIR = "../rtl"
VERILOG_SOURCES = [f"{RTL_DIR}/memory.sv"]
VERILOG_INCLUDE_DIRS = [RTL_DIR]
TOPLEVEL = "memory_bank"
MODULE = "test_memory_bank"


@cocotb.test()
async def test_read_then_write(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write all these words: %s", test_words)

    await Timer(20, unit="ns")

    dut.w_en.value = 1
    for i, word in enumerate(test_words):
        await FallingEdge(dut.clk)
        dut.addr.value = i
        dut.d_in.value = word

    await FallingEdge(dut.clk)

    dut.w_en.value = 0
    for i, word in enumerate(test_words):
        dut.addr.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.d_out.value == word, f"expected mem[{i}] to be {word}"


@cocotb.test()
async def test_read_write_interleaved(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write all these words: %s", test_words)

    await Timer(20, unit="ns")
    await FallingEdge(dut.clk)

    for i, word in enumerate(test_words):
        dut.w_en.value = 1
        dut.addr.value = i
        dut.d_in.value = word
        await FallingEdge(dut.clk)

        dut.w_en.value = 0
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.d_out.value == word, f"expected mem[{i}] to be {word}"

        await FallingEdge(dut.clk)
