# Without MODULE, run every test module (run_tests.sh calls back into this Makefile per module).
ifeq ($(strip $(MODULE)),)
.DEFAULT_GOAL := all-modules

all-modules:
	./run_tests.sh

clean:
	rm -rf sim_build results.xml dump.fst
else
SIM ?= verilator
TOPLEVEL_LANG = verilog

RTL_DIR := $(abspath ../rtl)
VERILOG_SOURCES := $(addprefix $(RTL_DIR)/,$(shell uv run python discover_tests.py $(MODULE) sources))
VERILOG_INCLUDE_DIRS := $(RTL_DIR)

COCOTB_TOPLEVEL := $(shell uv run python discover_tests.py $(MODULE) toplevel)
COCOTB_TEST_MODULES := $(MODULE)
SIM_BUILD := sim_build/$(MODULE)

# Waveform generation and platform-specific flags (only when WAVES=1)
ifeq ($(strip $(WAVES)),1)
# Enable waveform generation, in FST format
EXTRA_ARGS += --trace --trace-fst --trace-structs
# Separate build dir, so switching WAVES never reuses a stale build
SIM_BUILD := $(SIM_BUILD)_waves

# Only apply brew-based paths on macOS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  export CPPFLAGS += -I$(shell brew --prefix lz4)/include
  export LDFLAGS += -L$(shell brew --prefix lz4)/lib
endif
endif

export PYTHONPATH := $(abspath .):$(PYTHONPATH)

include $(shell uv run cocotb-config --makefiles)/Makefile.sim
endif
