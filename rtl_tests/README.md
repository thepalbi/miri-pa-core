### Run all test modules, or a single one

```bash
uv run make                                   # all test modules
uv run make MODULE=test_register_file         # one test module
```

`WAVES=1` and `COCOTB_TEST_FILTER` below work with `MODULE=...` as well.

### Run with waveforms enabled

Waveform generation produces a `dump.fst` file in `rtl_tests/` for waveform inspection. Every module writes the same file, so use `MODULE=...` to get the waveform of a specific module:

```bash
uv run make MODULE=test_register_file WAVES=1
```

After running, open the generated `dump.fst` in [GTKWave](http://gtkwave.sourceforge.net/):

```bash
gtkwave dump.fst
```

### Run a single test

Use `COCOTB_TEST_FILTER` to select specific tests. It accepts a regex pattern:

```bash
# Run exactly one test
uv run make COCOTB_TEST_FILTER=test_sync_read_write

# Run any test matching "read" in its name
uv run make COCOTB_TEST_FILTER=read
```

You can combine it with `WAVES=1` for waveform output on a specific test:

```bash
uv run make MODULE=test_memory_bank WAVES=1 COCOTB_TEST_FILTER=test_sync_read_write
```

## Directory Structure

| File | Description |
|---|---|
| `Makefile` | Build and test orchestration (includes cocotb's Makefile.sim); runs all modules when `MODULE` is not set |
| `run_tests.sh` | Runs every `test_*.py` module, one `make MODULE=...` each |
| `discover_tests.py` | Reads `VERILOG_SOURCES` and `TOPMODEL` from a test module, for the Makefile |
| `test_alu.py` | Python test module with cocotb test cases for `alu` |
| `test_memory_bank.py` | Python test module with cocotb test cases for `memory_bank` |
| `test_register_file.py` | Python test module with cocotb test cases for `register_file` |
| `sim_build/` | Generated simulation artifacts, one directory per module (`<module>_waves` when built with `WAVES=1`) |
| `results.xml` | JUnit-style test results (generated after each run) |

## Flags Reference

| Flag | Description | Default |
|---|---|---|
| `WAVES=1` | Enable waveform trace (`--trace --trace-fst --trace-structs`) and apply macOS-specific compiler flags for lz4 | not set |
| `COCOTB_TEST_FILTER=<pattern>` | Regex to select which tests to run (any match runs) | all tests |
| `SIM=verilator` | Simulation backend (cocotb supports ghdl, icarus, verilator) | verilator |


## Adding a test module

Each `test_*.py` module declares the Verilog file and top-level module it tests:

```python
VERILOG_SOURCES = "memory.sv"  # file in ../rtl
TOPMODEL = "memory_bank"       # top-level module
```

### Adding a RISC-V assembly test

In tests for `core_top` (e.g., `test_core_top.py`), use `run_program` from `test_programs` to assemble RISC-V assembly on the fly via Docker, load IMEM, and run the core. Temporary build artifacts go into `asm_build/` (git-ignored).

Docker must be running, with the toolchain image pulled beforehand:

```bash
docker pull pwn2de4d/riscv-toolchain:latest
```

Post-conditions can be embedded directly in assembly comments. A comment whose text starts with `!` is parsed as an assertion and removed before assembly:

```asm
    addi x1, x0, 5
    addi x2, x1, 7

# !rf[1] == 5
// !rf[2] == 12
```

`rf[i]` is register-file index `i`; the right-hand side is a decimal or hexadecimal integer. After the program finishes, `run_program` checks every assertion and reports all failures. Both `#` and `//` comment styles are accepted.

**From a `.S` file** (pass a `Path`):

```python
from pathlib import Path
import cocotb
from test_programs import run_program

PROGRAMS = Path(__file__).resolve().parent / "test_programs"

@cocotb.test()
async def test_loop_from_s_file(dut):
    await run_program(dut, PROGRAMS / "test.S", cycles=80)
```

**From an inline assembly string** (pass a `str`):

```python
@cocotb.test()
async def test_inline_asm(dut):
    await run_program(
        dut,
        """
        addi x1, x0, 5
        addi x2, x1, 7

        # !rf[1] == 5
        # !rf[2] == 12
        """,
        cycles=10,
    )
```

You can also pass `march="rv32im"` (default) or `clock_period_ns=10` to `run_program`, or call `assemble(source)` directly to get the `list[int]` instruction words.
