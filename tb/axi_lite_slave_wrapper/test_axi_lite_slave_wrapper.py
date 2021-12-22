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

        cocotb.fork(Clock(dut.axil_aclk, 2, units="ns").start())

        self.control = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.axil_aclk, dut.axil_aresetn, reset_active_level=False)

    def set_idle_generator(self, generator=None):
        if generator:
            self.control.write_if.aw_channel.set_pause_generator(generator())
            self.control.write_if.w_channel.set_pause_generator(generator())
            self.control.read_if.ar_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.control.write_if.b_channel.set_pause_generator(generator())
            self.control.read_if.r_channel.set_pause_generator(generator())

    async def reset(self):
        self.dut.axil_aresetn.setimmediatevalue(1)
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.axil_aresetn.value = 0
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.axil_aresetn.value = 1
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)

async def run_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    # from remote_pdb import RemotePdb; rpdb = RemotePdb("127.0.0.1", 4000)
    # remote_pdb.set_trace()
    base = 0x1000
    control_reg = await tb.control.read(0x0000 + base, 4)
    mi_mux = await tb.control.read(0x0040 + base, 4)
    print("Read splitter regs: Control {}, MI_MUX {}".format(control_reg.data, mi_mux.data))

    # await RisingEdge(dut.axil_aclk)
    # await RisingEdge(dut.axil_aclk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()
