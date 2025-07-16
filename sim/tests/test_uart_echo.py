# test_uart_echo.py
# cocotb testbench for uart_echo.v – with optional verbose logging

import os
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

CLK_PERIOD_NS = 20            # 50 MHz
BAUD_RATE     = 115_200
BIT_TIME_NS   = int(1e9 / BAUD_RATE)   # ≈ 8680 ns

# Verbose flag: True to print every echo
VERBOSE = bool(int(os.getenv("VERBOSE", "0")))   # export VERBOSE=1 to enable


async def uart_tx_byte(dut, byte):
    """Drive one UART byte on dut.rx (LSB first)."""
    dut.rx.value = 0
    await Timer(BIT_TIME_NS, unit="ns")

    for i in range(8):
        dut.rx.value = (byte >> i) & 1
        await Timer(BIT_TIME_NS, unit="ns")

    dut.rx.value = 1
    await Timer(BIT_TIME_NS, unit="ns")


async def uart_rx_byte(dut):
    """Capture one UART byte from dut.tx."""
    while int(dut.tx.value) == 1:
        await RisingEdge(dut.clk)

    await Timer(BIT_TIME_NS // 2, unit="ns")

    data = 0
    for i in range(8):
        await Timer(BIT_TIME_NS, unit="ns")
        data |= (int(dut.tx.value) & 1) << i

    await Timer(BIT_TIME_NS, unit="ns")
    return data


@cocotb.test()
async def uart_echo_test(dut):
    """Send bytes and verify they are echoed back."""
    dut.rx.value = 1
    dut.rst.value = 1

    clock = Clock(dut.clk, CLK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst.value = 0

    test_bytes = [0x55, 0xA3, 0x00, 0xFF, 0x42]

    for b in test_bytes + [random.getrandbits(8) for _ in range(50)]:
        cocotb.start_soon(uart_tx_byte(dut, b))
        echoed = await uart_rx_byte(dut)

        if VERBOSE:
            status = "OK" if echoed == b else "FAIL"
            cocotb.log.info(f"sent: 0x{b:02X}  received: 0x{echoed:02X}  {status}")

        assert echoed == b, f"Echo mismatch: sent 0x{b:02X}, got 0x{echoed:02X}"
