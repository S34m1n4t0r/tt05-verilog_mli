import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles



@cocotb.test()
async def test_polarity_low(dut):
    dut._log.info("start with 10 kHz clk_signal")
    clock = Clock(dut.clk, 100, units="us")
    cocotb.start_soon(clock.start())

    # reset
    dut._log.info("reset")
    dut.rst_n.value = 0
    

    dut._log.info("signal=0, polarity=0")
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 10)
    dut._log.info("Value of dut.uo_out: {}".format((dut.uo_out.value)))
    assert int(dut.uo_out.value) == 0

    await ClockCycles(dut.clk, 2*10000)
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 2*10000)
