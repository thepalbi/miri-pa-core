SIM ?= verilator
TOPLEVEL_LANG = verilog

RTL_DIR := $(abspath ../rtl)
VERILOG_SOURCES := $(RTL_DIR)/memory.sv
VERILOG_INCLUDE_DIRS := $(RTL_DIR)

TOPLEVEL = memory_bank
MODULE = test_memory_bank

# Verilator -Werror-style defaults on COMBDLY/NULLPORT in memory.sv
COMPILE_ARGS += -Wno-COMBDLY -Wno-NULLPORT

export PYTHONPATH := $(abspath .):$(PYTHONPATH)

include $(shell uv run cocotb-config --makefiles)/Makefile.sim
