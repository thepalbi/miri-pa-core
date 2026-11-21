import subprocess
import tempfile
import textwrap
from pathlib import Path

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from test_programs.assertions import (
    Assertion,
    Precondition,
    check_assertions,
    extract_directives,
)
from test_programs.loader import (
    load_dmem,
    load_imem,
    program_from_elf_text,
    reset_core,
)

RTL_TESTS_DIR = Path(__file__).resolve().parent.parent
ASM_BUILD_DIR = RTL_TESTS_DIR / "asm_build"
DOCKER_IMAGE = "pwn2de4d/riscv-toolchain:latest"
RISCV_AS = "/opt/riscv32/bin/riscv32-unknown-linux-gnu-as"


def _read_source(source: str | Path) -> str:
    if isinstance(source, Path):
        if not source.is_file():
            raise FileNotFoundError(f"Assembly file not found: {source}")
        return source.read_text()

    return textwrap.dedent(source).lstrip("\n")


def assemble(source: str | Path, *, march: str = "rv32im") -> list[int]:
    """Assemble RISC-V assembly (inline string or .S file) via Docker and return instruction words."""
    asm_text, _, _ = extract_directives(_read_source(source))

    if not asm_text.endswith("\n"):
        asm_text += "\n"

    ASM_BUILD_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=ASM_BUILD_DIR) as tmpdir:
        workdir = Path(tmpdir)
        src_file = workdir / "program.S"
        elf_file = workdir / "program.elf"
        src_file.write_text(asm_text)

        cmd = [
            "docker",
            "run",
            "--rm",
            "-v",
            f"{workdir}:/work",
            "-w",
            "/work",
            DOCKER_IMAGE,
            RISCV_AS,
            f"-march={march}",
            "-o",
            elf_file.name,
            src_file.name,
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as exc:
            details = (exc.stderr or exc.stdout or "").strip()
            raise RuntimeError(
                f"RISC-V assembler failed (exit {exc.returncode}):\n{details}"
            ) from exc

        return program_from_elf_text(elf_file)


async def run_program(
    dut,
    source: str | Path | list[int],
    *,
    cycles: int = 80,
    march: str = "rv32im",
    clock_period_ns: int = 10,
) -> list[int]:
    """Assemble (if needed), reset the core, load IMEM, and run for `cycles` clock cycles."""
    preconditions: list[Precondition] = []
    assertions: list[Assertion] = []
    if isinstance(source, (str, Path)):
        asm_text, preconditions, assertions = extract_directives(
            _read_source(source)
        )
        program = assemble(asm_text, march=march)
    else:
        program = source

    dut.run.value = 0
    dut.imem_w_en.value = 0
    dut.imem_waddr.value = 0
    dut.imem_wdata.value = 0

    Clock(dut.clk, clock_period_ns, unit="ns").start()

    await load_imem(dut, program)

    await reset_core(dut)
    load_dmem(dut, preconditions)

    dut.run.value = 1
    await ClockCycles(dut.clk, cycles)

    check_assertions(dut, assertions)
    return program
