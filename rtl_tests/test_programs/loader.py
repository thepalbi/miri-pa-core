import struct
from pathlib import Path

from cocotb.triggers import FallingEdge


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


def load_imem(dut, program: list[int]):
    """Load the program into IMEM by writing the memory bank directly.

    Like ``load_dmem``, this bypasses the write port so the loader does not
    show up as extra activity in the waveforms. The write port is held
    disabled so the running core cannot overwrite the loaded program.
    """
    dut.imem_w_en.value = 0
    dut.imem_waddr.value = 0
    dut.imem_wdata.value = 0
    dut.imem_rst.value = 0

    # Clear leftovers from previously loaded programs
    for i in range(len(dut.imem.bank)):
        dut.imem.bank[i].value = 0

    for i, instr in enumerate(program):
        dut.imem.bank[i].value = instr


def load_dmem(dut, preconditions):
    """Pre-load data memory.

    Must run after ``reset_core``: the memory bank clears itself on reset.
    """
    for pre in preconditions:
        dut.dmem.bank[pre.index].value = pre.value
