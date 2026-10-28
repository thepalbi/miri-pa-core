import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

VERILOG_SOURCES = "pc_reg.sv"
TOPMODEL = "pc"


async def sync_out(dut, expected):
    await Timer(2, unit="ns")
    assert dut.out.value == expected, (
        f"expected combinational PC out={expected}, got {int(dut.out.value)}"
    )


@cocotb.test()
async def test_combinational_read_path(dut):
    """Combinational out tracks pc_val; pc_val only updates on posedge clk."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await Timer(20, unit="ns")

    dut.w_en.value = 0
    dut.addr_in.value = 0

    dut.w_en.value = 1
    dut.addr_in.value = 10
    await RisingEdge(dut.clk)
    await sync_out(dut, 10)

    dut.w_en.value = 0
    await RisingEdge(dut.clk)
    await sync_out(dut, 11)

    new_pc = 0x63
    dut.w_en.value = 1
    dut.addr_in.value = new_pc
    await Timer(5, unit="ns")
    assert int(dut.out.value) == 11, (
        "addr_in/w_en must not change out until the capturing clock edge"
    )

    await RisingEdge(dut.clk)
    await sync_out(dut, new_pc)

    dut.w_en.value = 0
    await RisingEdge(dut.clk)
    await sync_out(dut, new_pc + 1)
