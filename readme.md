
# UART-Echo (Verilog + cocotb)

A minimal UART transceiver that **echos every byte it receives**  
(1 start bit, 8 data bits, 1 stop bit).  
Everything is simulation-first:

```

rtl/uart_echo.v            – parameterised RTL (50 MHz, 115 200 baud default)
sim/tests/test_uart_echo.py – cocotb testbench (optional verbose log)
sim/tests/Makefile          – one-line build & run

````

---

## 1  Prerequisites

| Tool | Where it comes from |
|------|--------------------|
| **OSS CAD Suite** (2025-07-16 or newer) | <https://github.com/YosysHQ/oss-cad-suite-build> |
| **Verilator** | bundled in OSS CAD Suite |
| **cocotb 2.x** | bundled in OSS CAD Suite |
| **GTKWave** (view waveforms) | `sudo apt install gtkwave` |

### Activate the OSS CAD Suite

Create **`~/oss-cad-suite/activate`** (see next block) and source it each time:

```bash
source ~/oss-cad-suite/activate    # ⦗OSS CAD Suite⦘ prompt appears
````

<details>
<summary>Example <code>activate</code> script</summary>

```bash
#!/usr/bin/env bash
[[ -n "$_OSSCAD_ACTIVE" ]] && { echo "⦗OSS CAD Suite⦘ already active."; return 0; }

export _OSSCAD_ACTIVE=1 _OSSCAD_OLD_PATH="$PATH" _OSSCAD_OLD_PS1="$PS1"
source "$HOME/oss-cad-suite/environment"

deactivate_oss_cad() {
    [[ -z "$_OSSCAD_ACTIVE" ]] && { echo "Environment is not active."; return 1; }
    export PATH="$_OSSCAD_OLD_PATH" PS1="$_OSSCAD_OLD_PS1"
    unset _OSSCAD_OLD_PATH _OSSCAD_OLD_PS1 _OSSCAD_ACTIVE
    unset -f deactivate_oss_cad
    echo "OSS CAD Suite environment deactivated."
}
```

</details>

---

## 2  Quick start

```bash
git clone <your-repo> uart_echo
cd uart_echo/sim/tests

# Fastest run (Verilator, silent)
make

# Waveform (FST) only
make waves
gtkwave sim_build/uart_echo.fst &

# Verbose log of every echo
make verbose

# Waveform + verbose in one go
make waves_verbose
```

All targets compile with **Verilator** by default (`SIM ?= verilator` in the Makefile).

---

## 3  Makefile targets

| Target                   | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| **`make`**               | Build & run silently (pass/fail only).               |
| **`make waves`**         | Save FST waveform to `sim_build/uart_echo.fst`.      |
| **`make verbose`**       | No waveform, prints `sent / received` for each byte. |
| **`make waves_verbose`** | Combines the two.                                    |

Optional flags:

```bash
# Multi-core Verilator compile
make VFLAGS+=" -j$(nproc)"

# Classic VCD instead of FST
make WAVEFORM=VCD
```

---

## 4  RTL overview (`rtl/uart_echo.v`)

* Parameters `CLK_FREQ` & `BAUD_RATE`; derives `CLKS_PER_BIT`.
* RX FSM — Idle → Start → 8 Data → Stop (mid-bit sampling).
* TX FSM — mirrors RX, returns to Idle after stop bit.
* 32-bit counters avoid Verilator width warnings.

---

## 5  Testbench (`test_uart_echo.py`)

* Generates 50 MHz clock, releases reset.
* Sends 5 fixed bytes + 50 random bytes.
* Waits for echo and asserts equality.
* `VERBOSE=1` prints lines like:
  `sent: 0x55  received: 0x55  OK`
