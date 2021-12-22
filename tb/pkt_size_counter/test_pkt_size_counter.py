import itertools
import logging

import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import (AxiLiteBus, AxiLiteMaster, AxiStreamBus,
                           AxiStreamFrame, AxiStreamSink, AxiStreamSource)


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.log.info("Got DUT: {}".format(dut))

        cocotb.fork(Clock(dut.axis_aclk, 2, units="ns").start())
        cocotb.fork(Clock(dut.axil_aclk, 4, units="ns").start())

        self.source_tx = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "s_axis"),
            dut.axis_aclk, dut.axis_aresetn, reset_active_level=False)
        self.sink_tx = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "m_axis"),
            dut.axis_aclk, dut.axis_aresetn, reset_active_level=False)
        self.control = AxiLiteMaster(
            AxiLiteBus.from_prefix(dut, "s_axil"),
            dut.axil_aclk, dut.axil_aresetn, reset_active_level=False)

    def set_idle_generator(self, generator=None):
        if generator:
            self.source_tx.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.sink_tx.set_pause_generator(generator())

    async def reset(self):
        self.dut.axil_aresetn.setimmediatevalue(1)
        self.dut.axis_aresetn.setimmediatevalue(1)
        # mod rst signals are synced with the axilite clock not axistream clock
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.axil_aresetn.value = 0
        self.dut.axis_aresetn.value = 0
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.axil_aresetn.value = 1
        self.dut.axis_aresetn.value = 1
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)

async def run_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    base = 0x0000

    dut.log.info("Sending control read command")
    reg = await tb.control.read(0x0000 + base, 4)
    dut.log.info("Read reg: {}".format(reg.data))

    test_frames = []
    test_frame = AxiStreamFrame(b'101010101')
    await tb.source_tx.send(test_frame)
    test_frames.append(test_frame)

    tb.log.info("Frames sent")

    for test_frame in test_frames:
        tb.log.info("Trying to recv frames")
        rx_frame = await tb.sink_tx.recv()
        assert rx_frame.tdata == test_frame.tdata
    assert tb.sink_tx.empty()

    bytes_sent_measured = await tb.control.read(0x0000 + base, 4)
    int_measured = int.from_bytes(bytes_sent_measured.data, 'little')
    assert len(test_frames[-1].tdata) == int_measured

    await RisingEdge(dut.axis_aclk)
    await RisingEdge(dut.axis_aclk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()
