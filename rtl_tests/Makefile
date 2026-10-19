SIM ?= verilator
TOPLEVEL_LANG = verilog

RTL_DIR := $(abspath ../rtl)
VERILOG_SOURCES := $(RTL_DIR)/memory.sv
VERILOG_INCLUDE_DIRS := $(RTL_DIR)

TOPLEVEL = memory_bank
COCOTB_TEST_MODULES = test_memory_bank

export PYTHONPATH := $(abspath .):$(PYTHONPATH)

include $(shell uv run cocotb-config --makefiles)/Makefile.sim
