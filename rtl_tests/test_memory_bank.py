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

VERILOG_SOURCES = "memory.sv"
TOPMODEL = "memory_bank"

@cocotb.test()
async def test_read_then_write(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write all these words: %s", test_words)

    await Timer(20, unit="ns")

    dut.wen.value = 1
    for i, word in enumerate(test_words):
        await FallingEdge(dut.clk)
        dut.waddr.value = i
        dut.wdata.value = word

    await FallingEdge(dut.clk)

    dut.waddr.value = 0
    dut.wen.value = 0
    for i, word in enumerate(test_words):
        dut.raddr.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        assert dut.rdata.value == word, f"expected mem[{i}] to be {word}"


import os
from cocotb.triggers import Timer
FAIL_HOLD_MS = float(os.environ.get("COCOTB_FAIL_HOLD_MS", "10"))
async def check(condition, msg=""):
  if not condition:
      await Timer(FAIL_HOLD_MS, unit="ns")
      raise AssertionError(msg)
# usage
# await check(dut.rdata.value == word, f"expected mem[{i}] to be {word}")


@cocotb.test()
async def test_read_write_in_same_clk_posedge(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut._log.info("about to write all these words: %s", test_words)

    await Timer(20, unit="ns")
    await FallingEdge(dut.clk)

    for i, word in enumerate(test_words):
        
        dut.wen.value = 1
        dut.waddr.value = i
        dut.wdata.value = word

        dut.raddr.value = i
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        await check(dut.rdata.value == word, f"expected mem[{i}] to be {word}")

        await FallingEdge(dut.clk)


@cocotb.test()
async def test_sync_read_write(dut):
    """Test writes two words for addresses 0x1 and 0x2. Then, starts reading 1 while 2
    is being written, and finishes reading the new value over 2.
    """
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await RisingEdge(dut.clk) # Start from fresh cycle

    dut.wen.value = 1
    dut.waddr.value = 0x01
    dut.wdata.value = 0x0A

    await RisingEdge(dut.clk)

    dut.waddr.value = 0x02
    dut.wdata.value = 0x0B

    await RisingEdge(dut.clk)

    dut.raddr.value = 0x01
    dut.waddr.value = 0x02
    dut.wdata.value = 0x0C

    await RisingEdge(dut.clk)
    await Timer(2, unit="ns")

    assert dut.rdata.value == 0x0A

    dut.raddr.value = 0x02
    dut.wen.value = 0

    await RisingEdge(dut.clk)
    await Timer(2, unit="ns")

    assert dut.rdata.value == 0x0C

    # Wait a bit more to see results in waveform
    await Timer(10, unit="ns")
