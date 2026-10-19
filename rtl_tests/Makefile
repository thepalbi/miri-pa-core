SIM ?= verilator
TOPLEVEL_LANG = verilog

RTL_DIR := $(abspath ../rtl)
VERILOG_SOURCES := $(RTL_DIR)/memory.sv
VERILOG_INCLUDE_DIRS := $(RTL_DIR)

COCOTB_TOPLEVEL = memory_bank
COCOTB_TEST_MODULES = test_memory_bank

# Waveform generation and platform-specific flags (only when WAVES=1)
ifeq ($(strip $(WAVES)),1)
# Enable waveform generation, in FST format
EXTRA_ARGS += --trace --trace-fst --trace-structs

# Only apply brew-based paths on macOS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  export CPPFLAGS += -I$(shell brew --prefix lz4)/include
  export LDFLAGS += -L$(shell brew --prefix lz4)/lib
endif
endif

export PYTHONPATH := $(abspath .):$(PYTHONPATH)

include $(shell uv run cocotb-config --makefiles)/Makefile.sim
