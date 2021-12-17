import itertools
import logging

import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import (AxiLiteBus, AxiLiteMaster, AxiStreamBus,
                           AxiStreamSink, AxiStreamSource, AxiStreamFrame)


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.log.info("Got DUT: {}".format(dut))

        cocotb.fork(Clock(dut.aclk, 2, units="ns").start())
        cocotb.fork(Clock(dut.s_axi_ctrl_aclk, 4, units="ns").start())

        self.source = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "s_axis"),
            dut.aclk, dut.aresetn, reset_active_level=False)
        self.sink1 = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "m_axis1"),
            dut.aclk, dut.aresetn, reset_active_level=False)
        self.sink2 = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "m_axis2"),
            dut.aclk, dut.aresetn, reset_active_level=False)
        self.control = AxiLiteMaster(
            AxiLiteBus.from_prefix(dut, "s_axi_ctrl"),
            dut.s_axi_ctrl_aclk, dut.s_axi_ctrl_aresetn, reset_active_level=False)

    def set_idle_generator(self, generator=None):
        if generator:
            self.control.write_if.aw_channel.set_pause_generator(generator())
            self.control.write_if.w_channel.set_pause_generator(generator())
            self.control.read_if.ar_channel.set_pause_generator(generator())

            self.source.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.control.write_if.b_channel.set_pause_generator(generator())
            self.control.read_if.r_channel.set_pause_generator(generator())

            self.sink1.set_pause_generator(generator())
            self.sink2.set_pause_generator(generator())

    async def reset(self):
        self.dut.aresetn.setimmediatevalue(1)
        self.dut.s_axi_ctrl_aresetn.setimmediatevalue(1)

        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 0
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 1
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)

        await RisingEdge(self.dut.s_axi_ctrl_aclk)
        await RisingEdge(self.dut.s_axi_ctrl_aclk)
        self.dut.s_axi_ctrl_aresetn.value = 0
        await RisingEdge(self.dut.s_axi_ctrl_aclk)
        await RisingEdge(self.dut.s_axi_ctrl_aclk)
        self.dut.s_axi_ctrl_aresetn.value = 1
        await RisingEdge(self.dut.s_axi_ctrl_aclk)
        await RisingEdge(self.dut.s_axi_ctrl_aclk)

async def run_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    # from remote_pdb import RemotePdb; rpdb = RemotePdb("127.0.0.1", 4000)
    # remote_pdb.set_trace()
    base = 0x0000
    control_reg = await tb.control.read(0x0000 + base, 4)
    mi_mux1 = await tb.control.read(0x0040 + base, 4)
    mi_mux2 = await tb.control.read(0x0044 + base, 4)
    dut.log.info(
        "Read splitter regs: Control {}, MI_MUX1 {}, MI_MUX2 {}"
        .format(control_reg.data, mi_mux1.data, mi_mux2.data))

    # configure master1 to get traffic from slave
    tb.log.info("Configuring master1")
    await tb.control.write(0x0040 + base, b'\x00')
    await tb.control.write(0x0000 + base, b'\x02')  # commit configuration
    await tb.control.read(0x0040 + base, 4)  # check configuration

    tb.log.info("Testing master1")
    test_frames = []
    test_frame = AxiStreamFrame(b'101010101')
    await tb.source.send(test_frame)
    test_frames.append(test_frame)
    for test_frame in test_frames:
        tb.log.info("Trying to recv frames")
        rx_frame = await tb.sink1.recv()
        assert rx_frame.tdata == test_frame.tdata

    assert tb.sink1.empty()
    assert tb.sink2.empty()

    # configure master2 to get traffic from slave
    tb.log.info("Configuring master2")
    await tb.control.write(0x0040 + base, b'\x00\x00\x00\x80') # disable master1
    await tb.control.write(0x0044 + base, b'\x00')
    await tb.control.write(0x0000 + base, b'\x02')  # commit configuration
    await tb.control.read(0x0040 + base, 4)  # check configuration

    control_reg = await tb.control.read(0x0000 + base, 4)
    mi_mux1 = await tb.control.read(0x0040 + base, 4)
    mi_mux2 = await tb.control.read(0x0044 + base, 4)
    dut.log.info(
        "Read splitter regs: Control {}, MI_MUX1 {}, MI_MUX2 {}"
        .format(control_reg.data, mi_mux1.data, mi_mux2.data))

    tb.log.info("Testing master2")
    test_frames = []
    test_frame = AxiStreamFrame(b'1111111111')
    await tb.source.send(test_frame)
    test_frames.append(test_frame)
    for test_frame in test_frames:
        tb.log.info("Trying to recv frames")
        rx_frame = await tb.sink2.recv()
        assert rx_frame.tdata == test_frame.tdata

    assert tb.sink1.empty()
    assert tb.sink2.empty()

    control_reg = await tb.control.read(0x0000 + base, 4)
    mi_mux1 = await tb.control.read(0x0040 + base, 4)
    mi_mux2 = await tb.control.read(0x0044 + base, 4)
    dut.log.info(
        "Read splitter regs: Control {}, MI_MUX1 {}, MI_MUX2 {}"
        .format(control_reg.data, mi_mux1.data, mi_mux2.data))

    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()
