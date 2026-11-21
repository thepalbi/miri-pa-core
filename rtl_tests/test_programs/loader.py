import struct
from pathlib import Path

from cocotb.triggers import RisingEdge, FallingEdge


def program_from_bytes(raw: bytes) -> list[int]:
    """32-bit little-endian RISC-V words (drop trailing partial word)."""
    n = len(raw) - (len(raw) % 4)
    return [
        int.from_bytes(raw[i : i + 4], "little")
        for i in range(0, n, 4)
    ]


def program_from_bin(path: Path) -> list[int]:
    return program_from_bytes(path.read_bytes())


def program_from_elf_text(path: Path) -> list[int]:
    """Extract `.text` from an `as`-produced relocatable ELF (no program headers)."""
    data = path.read_bytes()
    if data[:4] != b"\x7fELF":
        return program_from_bytes(data)

    e_shoff = struct.unpack_from("<I", data, 32)[0]
    e_shentsize = struct.unpack_from("<H", data, 46)[0]
    e_shnum = struct.unpack_from("<H", data, 48)[0]
    e_shstrndx = struct.unpack_from("<H", data, 50)[0]

    shstr_off = struct.unpack_from(
        "<I", data, e_shoff + e_shstrndx * e_shentsize + 16
    )[0]

    def sh_name(sh_idx: int) -> str:
        name_off = struct.unpack_from("<I", data, e_shoff + sh_idx * e_shentsize)[0]
        end = data.index(b"\x00", shstr_off + name_off)
        return data[shstr_off + name_off : end].decode()

    for sh_idx in range(e_shnum):
        sh_base = e_shoff + sh_idx * e_shentsize
        if sh_name(sh_idx) != ".text":
            continue
        sh_offset, sh_size = struct.unpack_from("<II", data, sh_base + 16)
        return program_from_bytes(data[sh_offset : sh_offset + sh_size])

    raise ValueError(f"no .text section in {path}")


async def reset_core(dut):
    """Runs two duty cycles, with the rst signal high."""
    dut.rst.value = 0
    await FallingEdge(dut.clk)
    dut.rst.value = 1
    await FallingEdge(dut.clk)
    dut.rst.value = 0


async def load_imem(dut, program: list[int]):
    """Same addressing as the hand-written tests (word i at IMEM index i + 1)."""
    from cocotb.triggers import FallingEdge

    dut.imem_rst.value = 0
    await FallingEdge(dut.clk)
    dut.imem_rst.value = 1;
    await FallingEdge(dut.clk)
    dut.imem_rst.value = 0;

    dut.imem_w_en.value = 1
    for i, instr in enumerate(program):
        dut.imem_waddr.value = i
        dut.imem_wdata.value = instr
        await RisingEdge(dut.clk)
    dut.imem_w_en.value = 0


def load_dmem(dut, preconditions):
    """Pre-load data memory.

    Must run after ``reset_core``: the memory bank clears itself on reset.
    """
    for pre in preconditions:
        dut.dmem.bank[pre.index].value = pre.value
