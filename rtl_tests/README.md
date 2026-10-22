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
