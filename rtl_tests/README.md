### Run with waveforms enabled

Waveform generation produces a `.fst` file in the project root for waveform inspection:

```bash
uv run make WAVES=1
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
uv run make WAVES=1 COCOTB_TEST_FILTER=test_sync_read_write
```

## Directory Structure

| File | Description |
|---|---|
| `Makefile` | Build and test orchestration (includes cocotb's Makefile.sim) |
| `test_memory_bank.py` | Python test module with cocotb test cases |
| `sim_build/` | Generated simulation artifacts (auto-created by make) |
| `results.xml` | JUnit-style test results (generated after each run) |

## Flags Reference

| Flag | Description | Default |
|---|---|---|
| `WAVES=1` | Enable waveform trace (`--trace --trace-fst --trace-structs`) and apply macOS-specific compiler flags for lz4 | not set |
| `COCOTB_TEST_FILTER=<pattern>` | Regex to select which tests to run (any match runs) | all tests |
| `SIM=verilator` | Simulation backend (cocotb supports ghdl, icarus, verilator) | verilator |

## Notes on macOS

On macOS, the lz4 include and library paths are set via Homebrew (`brew --prefix lz4`) automatically when `WAVES=1` is used. On Linux these flags are omitted — ensure your system's lz4 headers are in the standard search path if you encounter issues.
EOF
```

