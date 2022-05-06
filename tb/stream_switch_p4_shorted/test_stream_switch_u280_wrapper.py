import itertools
import logging

import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import (AxiLiteBus, AxiLiteMaster, AxiStreamBus,
                           AxiStreamFrame, AxiStreamSink, AxiStreamSource)

from scapy.all import Ether, IP, UDP, wrpcap, raw, TCP

my_packet = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / (b'\xaa'*16)
my_packet2 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / (b'\xbb'*16)
my_packet3 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / TCP(sport=111, dport=62178) / (b'\xcc'*16)

"""
Eth:
dmac: 00 0a 35 bc 7a bc
smac: ff 0a 35 bc 7a bc
type: 08 00

IP:
version: 4
hdr_len: 5
tos: 00
len: 00 3c
id: 00 01
flags, offset: 00 00
ttl: 40
proto: 11
chksum: 66 54
src: 0a 00 00 28
dst: 0a 00 00 35

UDP:
src_port: 00 6f
dst_port: f2 e0
length: 00 18
chksum: f0 09

Payload: 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
"""


class TB:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.log.info("Got DUT: {}".format(dut))

        cocotb.fork(Clock(dut.axis_aclk, 2, units="ns").start())
        cocotb.fork(Clock(dut.axil_aclk, 4, units="ns").start())

        self.source_tx = [AxiStreamSource(
            AxiStreamBus.from_prefix(
                dut, "s_axis_qdma_h2c_port{}".format(port)),
            dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
            for port in [0, 1]]
        self.source_rx = [AxiStreamSource(
            AxiStreamBus.from_prefix(
                dut, "s_axis_adap_rx_250mhz_port{}".format(port)),
            dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
            for port in [0, 1]]
        self.sink_tx = [AxiStreamSink(
            AxiStreamBus.from_prefix(
                dut, "m_axis_adap_tx_250mhz_port{}".format(port)),
            dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
            for port in [0, 1]]
        self.sink_rx = [AxiStreamSink(
            AxiStreamBus.from_prefix(
                dut, "m_axis_qdma_c2h_port{}".format(port)),
            dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
            for port in [0, 1]]
        self.control = AxiLiteMaster(
            AxiLiteBus.from_prefix(dut, "s_axil"),
            dut.axil_aclk, dut.stream_switch_dfx_inst.axil_aresetn, reset_active_level=False)

    def set_idle_generator(self, generator=None):
        if generator:
            for source_tx in self.source_tx:
                source_tx.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            for sink_tx in self.sink_tx:
                sink_tx.set_pause_generator(generator())

    async def reset(self):
        self.dut.mod_rstn.setimmediatevalue(1)
        # mod rst signals are synced with the axilite clock not axistream clock
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.mod_rstn.value = 0
        await RisingEdge(self.dut.axil_aclk)
        await RisingEdge(self.dut.axil_aclk)
        self.dut.mod_rstn.value = 1
        await RisingEdge(self.dut.mod_rst_done)
        # await RisingEdge(self.dut.axil_aclk)
        # await RisingEdge(self.dut.axil_aclk)


async def check_connection(tb, source, sink, my_packet=my_packet):
    # Pkts on source should arrive at sink
    test_frames = []
    # test_frame = AxiStreamFrame(b'101010101')
    # pkt_bytearray = bytearray(bytes(my_packet))
    # pkt_bytearray.reverse()
    test_frame = AxiStreamFrame(bytes(my_packet))
    await source.send(test_frame)
    test_frames.append(test_frame)
    tb.log.info("Frames sent")

    for test_frame in test_frames:
        tb.log.info("Trying to recv frames")
        rx_frame = await sink.recv()
        assert rx_frame.tdata == test_frame.tdata

    assert sink.empty()


async def check_drop(tb, source, sink, drop_pkt, my_packet=my_packet):
    # This should be dropped
    test_frame = AxiStreamFrame(bytes(drop_pkt))
    await source.send(test_frame)

    # This should not be dropped
    test_frames = []
    test_frame = AxiStreamFrame(bytes(my_packet))
    await source.send(test_frame)
    test_frames.append(test_frame)
    tb.log.info("Frames sent")

    for test_frame in test_frames:
        tb.log.info("Trying to recv frames")
        rx_frame = await sink.recv()
        assert rx_frame.tdata == test_frame.tdata

    assert sink.empty()


async def run_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    base = 0x0000
    dp_base = 0x40000

    dut.log.info( "Sending control read command")

    # from remote_pdb import RemotePdb; rpdb = RemotePdb("127.0.0.1", 4000)
    # remote_pdb.set_trace()
    control_reg = await tb.control.read(0x0000 + base, 4)
    mi_mux1 = await tb.control.read(0x0040 + base, 4)
    mi_mux2 = await tb.control.read(0x0044 + base, 4)
    dut.log.info(
        "Read splitter regs: Control {}, MI_MUX1 {}, MI_MUX2 {}"
        .format(control_reg.data, mi_mux1.data, mi_mux2.data))

    # configure splitter master1 to get traffic from slave
    tb.log.info("Configuring splitter master1")
    await tb.control.write(0x0040 + base, b'\x00')
    await tb.control.write(0x0000 + base, b'\x02')  # commit configuration
    await tb.control.read(0x0040 + base, 4)  # check configuration

    # Should be able to send/recv on port 0
    await check_connection(tb, tb.source_tx[0], tb.sink_tx[0])
    await check_connection(tb, tb.source_rx[0], tb.sink_rx[0])

    # Packets recvd on wire on port 1 should be sent to tx on port 0
    await check_connection(tb, tb.source_rx[1], tb.sink_tx[0])
    await check_connection(tb, tb.source_rx[1], tb.sink_tx[0], my_packet2)
    await check_drop(tb, tb.source_rx[1], tb.sink_tx[0], my_packet3)

    await RisingEdge(dut.axis_aclk)
    await RisingEdge(dut.axis_aclk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()
