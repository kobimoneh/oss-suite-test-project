TOPLEVEL_LANG ?= verilog
SIM           ?= verilator          # export SIM=verilator for speed
TOPLEVEL := uart_echo
COCOTB_TEST_MODULES := test_uart_echo

VERILOG_SOURCES := ../../rtl/uart_echo.v

# ------------ targets -------------------------------------------------
.PHONY: waves verbose waves_verbose

#  make              → silent run
#  make waves        → waveform only
#  make verbose      → no waves, prints every echo
#  make waves_verbose→ both in a single run
waves:
	$(MAKE) sim WAVEFORM=FST

verbose:
	$(MAKE) sim VERBOSE=1

waves_verbose:
	$(MAKE) sim WAVEFORM=FST VERBOSE=1

include $(shell cocotb-config --makefiles)/Makefile.sim
