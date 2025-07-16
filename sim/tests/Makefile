# ------------------------------------------------------------
# cocotb / Verilator Makefile — UART-echo
# ------------------------------------------------------------
TOPLEVEL_LANG ?= verilog
SIM           ?= verilator
TOPLEVEL      := uart_echo
COCOTB_TEST_MODULES := test_uart_echo
VERILOG_SOURCES     := ../../rtl/uart_echo.v

# -------- Waveform format -----------------------------------
WAVE ?= VCD                  # make WAVE=FST waves  for FST instead of VCD

ifeq ($(WAVE),FST)
TRACE_ARGS = --trace-fst
WAVEFILE   = uart_echo.fst
else
TRACE_ARGS = --trace
WAVEFILE   = dump.vcd
endif

# -------- Targets -------------------------------------------
.PHONY: waves verbose waves_verbose

waves:
	WAVES=1 $(MAKE) sim EXTRA_ARGS="$(TRACE_ARGS)"

verbose:
	$(MAKE) sim VERBOSE=1

waves_verbose:
	WAVES=1 $(MAKE) sim EXTRA_ARGS="$(TRACE_ARGS)" VERBOSE=1

include $(shell cocotb-config --makefiles)/Makefile.sim
