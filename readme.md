## UART Echo — Verilog + cocotb demo

An ultra-small UART transceiver that **echos each received byte** (1 start, 8 data, 1 stop).
Everything is simulation-first: you get a parameterised RTL module, a cocotb testbench, and a Makefile that hides the simulator details.

```
rtl/uart_echo.v          ──> the design
sim/tests/test_uart_echo.py ──> Python test (cocotb)
sim/tests/Makefile          ──> single-line commands:  make, make waves, …
```

---

### 1  Quick start (Linux / WSL)

```bash
# 1.  Activate OSS-CAD-Suite (installs Verilator, Icarus, GTKWave, cocotb, …)
source ~/oss-cad-suite/activate    # ⦗OSS CAD Suite⦘ prompt appears

# 2.  Grab the project (or clone your repo)
git clone <this-repo> uart_echo
cd uart_echo/sim/tests

# 3.  Fastest run (Verilator, no waves)
make                # ~1 s wall-time

# 4.  Waveform + verbose log
make waves_verbose  # FST dumped to sim_build/uart_echo.fst
gtkwave sim_build/uart_echo.fst &
```

> **Tip** If you skipped the `activate` script, the `make` targets will fail
> because cocotb & Verilator aren’t on your `PATH`.

---

### 2  Makefile targets

| Target                          | What it does                           | Typical use       |
| ------------------------------- | -------------------------------------- | ----------------- |
| `make`                          | Compile & run (silent)                 | CI, quick check   |
| `make waves`                    | Save FST waveform (no per-byte prints) | Debug timing      |
| `make verbose`                  | Print every echo (`sent / received`)   | Functional debug  |
| `make waves_verbose`            | **waves + verbose** in one go          | Deep dive         |
| <small>`SIM=icarus …`</small>   | Force Icarus instead of Verilator      | Cross-sim check   |
| <small>`WAVEFORM=VCD …`</small> | Save classic VCD instead of FST        | Third-party tools |

All flags can be mixed on the CLI:

```bash
# Multi-core Verilator compile, verbose, VCD trace
make waves_verbose SIM=verilator VFLAGS+=" -j$(nproc)" WAVEFORM=VCD
```

---

### 3  RTL highlights (`rtl/uart_echo.v`)

* **Parameters**
  `CLK_FREQ` (default 50 MHz) and `BAUD_RATE` (115 200) generate
  `CLKS_PER_BIT` internally.
* **RX FSM**
  *Idle → Start → Data\[8] → Stop* with mid-bit sampling.
* **TX FSM**
  Mirrors RX, returns to *Idle* after the stop bit (`tx_state <= 0`).
* 32-bit counters (`rx_clk_cnt`, `tx_clk_cnt`) keep Verilator happy.

---

### 4  Testbench (`test_uart_echo.py`)

* Starts a 50 MHz clock, toggles `rst`.
* Sends 5 fixed bytes + 50 random bytes.
* Waits for the echo, asserts equality.
* `VERBOSE=1` (env var) prints:

```
sent: 0x55  received: 0x55  OK
```

---

### 5  Wave viewing

```bash
# FST (default for Verilator/Icarus with WAVES=1)
gtkwave sim_build/uart_echo.fst &

# Convert to VCD later if you like
fst2vcd sim_build/uart_echo.fst > dump.vcd
```

Add signals such as `clk`, `rx`, `tx`, `uut.rx_state`, `uut.tx_state`,
`uut.rx_byte`, `uut.tx_byte` to watch the protocol.

---

### 6  Performance cheatsheet

| Simulator     | Waves | Time (9 ms sim) |
| ------------- | ----- | --------------- |
| **Verilator** | off   | **≈ 1 s**       |
| Verilator     | FST   | 1-3 s           |
| Icarus        | off   | 5-6 s           |
| Icarus        | FST   | 20-25 s         |

Export `SIM=verilator` in your shell to make it the default.

---

### 7  Customising

* **Different baud or clock** – edit the two parameters at the top of
  `uart_echo.v`; keep `BIT_TIME_NS` in the testbench in sync.
* **Parity / FIFO / flow-control** – expand the FSM
  and add new cocotb tests.
* **Hardware bring-up** – the RTL drops into an FPGA project unchanged;
  reuse the cocotb test as a golden reference.

---

### 8  Prerequisites

* [**OSS CAD Suite**](https://github.com/YosysHQ/oss-cad-suite-build)
  (2025-07-16 or newer).
  Activate it with:

  ```bash
  source ~/oss-cad-suite/activate       # sets PATH, prompt, etc.
  ```
* Bash, make, Python 3 (bundled in OSS suite).
* Optional: GTKWave for viewing waveforms (`sudo apt install gtkwave`).

That’s it—clone, `make`, and you’re echoing bytes.
Issues or pull requests welcome!
