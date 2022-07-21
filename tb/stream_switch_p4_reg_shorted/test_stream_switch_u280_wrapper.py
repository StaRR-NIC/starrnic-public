import ipaddress
import itertools
import logging

import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import (AxiLiteBus, AxiLiteMaster, AxiStreamBus,
                           AxiStreamFrame, AxiStreamSink, AxiStreamSource)
from cocotb.utils import get_sim_time, get_sim_steps
from cocotb.triggers import Timer

from scapy.all import Ether, IP, UDP, wrpcap, raw, TCP

packets = [
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / (b'\xa0'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / (b'\xa1'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62178) / (b'\xa2'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / TCP(sport=111, dport=62176) / (b'\xcc'*16)
]


thr_pkt1 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / (b'\xee'*128)
thr_pkt2 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / (b'\xff'*128)

# src mac, dst mac, src ip, dst ip, src port, dst port, ipsum
expectations = [
    ('00:0a:35:bc:7a:bc', 'ff:0a:35:bc:7a:bc', '10.0.0.53', '10.0.0.40', 62176, 111, 0x6664),
    ('aa:bb:cc:dd:ee:ff', '11:22:33:44:55:66', '1.2.3.4', '6.7.8.9', 0xaabb, 0xccdd, 0xeeff),
]


def mac2bytes(mac: str):
    assert len(mac) == 17
    return int("0x{}".format(mac.replace(":", "")), 16).to_bytes(6, 'little')


def ip2bytes(ip: str):
    return int(ipaddress.IPv4Address(ip)).to_bytes(4, 'little')


class TB:
    def __init__(self, dut):
        self.dut = dut
        self.axis_aclk_pd = 4  # ns, 250 Mhz
        self.axil_aclk_pd = 8  # ns, 125 Mhz

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.log.info("Got DUT: {}".format(dut))

        cocotb.fork(Clock(
            dut.axis_aclk, self.axis_aclk_pd, units="ns").start())
        cocotb.fork(Clock(
            dut.axil_aclk, self.axil_aclk_pd, units="ns").start())

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
        # self.sink_tx = [AxiStreamSink(
        #     AxiStreamBus.from_prefix(
        #         dut, "m_axis_adap_tx_250mhz_port{}".format(port)),
        #     dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
        #     for port in [0, 1]]
        # self.sink_rx = [AxiStreamSink(
        #     AxiStreamBus.from_prefix(
        #         dut, "m_axis_qdma_c2h_port{}".format(port)),
        #     dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
        #     for port in [0, 1]]
        self.control = AxiLiteMaster(
            AxiLiteBus.from_prefix(dut, "s_axil"),
            dut.axil_aclk, dut.stream_switch_dfx_inst.axil_aresetn, reset_active_level=False)

        # Probe
        # self.p4_ppl_sink = AxiStreamSink(
        #     AxiStreamBus.from_prefix(
        #         dut.stream_switch_dfx_inst.short_host, "axis_ppl"),
        #     dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)
        self.p4_ppl_sink = AxiStreamSink(
            AxiStreamBus.from_prefix(
                dut, "m_axis_adap_tx_250mhz_port{}".format(0)),
            dut.axis_aclk, dut.stream_switch_dfx_inst.axis_aresetn, reset_active_level=False)

    def set_idle_generator(self, generator=None):
        if generator:
            for source_tx in self.source_tx:
                source_tx.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            # for sink_tx in self.sink_tx:
            #     sink_tx.set_pause_generator(generator())
            self.p4_ppl_sink.set_pause_generator(generator())

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


async def check_thr(tb, source, sink, test_packet1, test_packet2):
    # Pkts on source should arrive at sink
    test_frames = []
    test_frame1 = AxiStreamFrame(bytes(test_packet1), tuser=0)
    test_frame2 = AxiStreamFrame(bytes(test_packet2), tuser=0)
    for _ in range(128):
        await source.send(test_frame1)
        await source.send(test_frame2)
        test_frames.append(test_frame1)
        test_frames.append(test_frame2)
    # tb.log.info("Frames sent")

    tb.log.info("Trying to recv frames")
    for test_frame in test_frames:
        rx_frame = await sink.recv()
        if(len(rx_frame.tdata) != len(test_frame.tdata)):
            tb.log.error("Mismatch in frames")
            await Timer(get_sim_steps(10, units="us"))
            assert False

    assert sink.empty()


async def check_connection(tb, source, sink, test_packet=packets[0]):
    # Pkts on source should arrive at sink
    test_frames = []
    test_frame = AxiStreamFrame(bytes(test_packet), tuser=0)
    await source.send(test_frame)
    test_frames.append(test_frame)
    # tb.log.info("Frames sent")

    for test_frame in test_frames:
        tb.log.info("Trying to recv frames from: {}".format(sink))
        rx_frame = await sink.recv()
        assert len(rx_frame.tdata) == len(test_frame.tdata)
        tb.log.info("Len check done for sink: {}".format(sink))

    assert sink.empty()


async def check_connection_hdr(tb, source, sink, test_packet,
                               smac: str, dmac: str, src: str, dst: str,
                               sport: int, dport: int, ipsum: int):
    # Pkts on source should arrive at sink
    test_frames = []
    test_frame = AxiStreamFrame(bytes(test_packet), tuser=0)
    await source.send(test_frame)
    test_frames.append(test_frame)

    for test_frame in test_frames:
        tb.log.info("Trying to recv frames")
        rx_frame = await sink.recv()
        rx_pkt = Ether(rx_frame.tdata)
        rx_pkt.show()
        assert rx_pkt.src == smac
        assert rx_pkt.dst == dmac
        assert rx_pkt.sport == sport
        assert rx_pkt.dport == dport
        assert rx_pkt[IP].src == src
        assert rx_pkt[IP].dst == dst
        assert rx_pkt[IP].chksum == ipsum

    assert sink.empty()


async def check_drop(tb, source, sink, drop_pkt):
    # This should be dropped
    test_frame = AxiStreamFrame(bytes(drop_pkt), tuser=0)
    await source.send(test_frame)

    # tb.log.info("Trying to recv frames")
    # rx_frame = await sink.recv()
    # assert rx_frame.tdata == b''

    await RisingEdge(tb.dut.axil_aclk)
    await RisingEdge(tb.dut.axil_aclk)

    assert sink.empty()


USE_DEMUX = True
if(USE_DEMUX):
    async def read_switch_config(tb, base):
        tb.log.info("Sending control read command")
        commit_reg = await tb.control.read(0x0000 + base, 4)
        select_reg = await tb.control.read(0x0004 + base, 4)
        tb.log.info(
            "Read demux regs: Commit {}, Select {}"
            .format(commit_reg.data, select_reg.data))

    async def connect_region(tb, base):
        tb.log.info("Configuring master2")
        await tb.control.write(0x0004 + base, b'\x01')              # enable master 2
        await tb.control.write(0x0000 + base, b'\x01')              # commit configuration
        await tb.control.read(0x0004 + base, 4)                     # check configuration (m1)

    async def bypass_region(tb, base):
        tb.log.info("Configuring master1")
        await tb.control.write(0x0004 + base, b'\x00')              # enable master 1
        await tb.control.write(0x0000 + base, b'\x01')              # commit configuration
        await tb.control.read(0x0004 + base, 4)                     # check configuration (m1)

else:
    async def read_switch_config(tb, base):
        tb.log.info("Sending control read command")
        control_reg = await tb.control.read(0x0000 + base, 4)
        mi_mux1 = await tb.control.read(0x0040 + base, 4)
        mi_mux2 = await tb.control.read(0x0044 + base, 4)
        tb.log.info(
            "Read splitter regs: Control {}, MI_MUX1 {}, MI_MUX2 {}"
            .format(control_reg.data, mi_mux1.data, mi_mux2.data))

    async def connect_region(tb, base):
        tb.log.info("Configuring master2")
        await tb.control.write(0x0040 + base, b'\x00\x00\x00\x80')  # disable master1
        await tb.control.write(0x0044 + base, b'\x00')              # enable master 2
        await tb.control.write(0x0000 + base, b'\x02')              # commit configuration
        await tb.control.read(0x0040 + base, 4)                     # check configuration (m1)
        await tb.control.read(0x0044 + base, 4)                     # check configuration (m2)

    async def bypass_region(tb, base):
        tb.log.info("Configuring master1")
        await tb.control.write(0x0040 + base, b'\x00')              # enable master1
        await tb.control.write(0x0044 + base, b'\x00\x00\x00\x80')  # disable master2
        await tb.control.write(0x0000 + base, b'\x02')              # commit configuration
        await tb.control.read(0x0040 + base, 4)                     # check configuration (m1)
        await tb.control.read(0x0044 + base, 4)                     # check configuration (m2)


async def run_test(dut, idle_inserter=None, backpressure_inserter=None):

    tb = TB(dut)

    await tb.reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    base = 0x0000
    reg_base = 0x03000
    dp_base = 0x40000

    # from remote_pdb import RemotePdb; rpdb = RemotePdb("127.0.0.1", 4000)
    # remote_pdb.set_trace()
    await read_switch_config(tb, base)

    # configure splitter master2 to get traffic from slave
    await connect_region(tb, base)

    # # Should be able to send/recv on port 0
    # tb.log.info("Checking port 0 (TX)")
    # await check_connection(tb, tb.source_tx[0], tb.sink_tx[0])
    # tb.log.info("Checking port 0 (RX)")
    # await check_connection(tb, tb.source_rx[0], tb.sink_rx[0])

    # # Non udp packets should be dropped
    # tb.log.info("Checking port 1 (RX) with TCP")
    # await check_drop(tb, tb.source_rx[1], tb.p4_ppl_sink, packets[-1])

    # tb.log.info("Checking port 1 (RX) with UDP packet but with different port")
    # # UDP packets with dst port not in [62176, 62177] should be dropped
    # await check_drop(tb, tb.source_rx[1], tb.p4_ppl_sink, packets[-2])

    # # UDP dst port 62176 should be reflected back with swapped headers
    # tb.log.info("UDP dst port 62176 should be reflected back with swapped headers")
    # await check_connection_hdr(tb, tb.source_rx[1], tb.p4_ppl_sink, packets[0], *expectations[0])

    # # Check if can read data plane registers from control path
    # tb.log.info("Checking data path registers.")
    # bytes_sent_measured = await tb.control.read(dp_base, 4)
    # int_measured = int.from_bytes(bytes_sent_measured.data, 'little')
    # tb.log.info("Measured pkt size: {}".format(int_measured))
    # assert len(packets[0]) == int_measured # We sent using different path

    # UDP dst port 62177 should take headers from register
    await tb.control.write(0x000 + reg_base, mac2bytes(expectations[1][0]))
    smac = await tb.control.read(0x000 + reg_base, 6)

    await tb.control.write(0x008 + reg_base, mac2bytes(expectations[1][1]))
    dmac = await tb.control.read(0x008 + reg_base, 6)

    await tb.control.write(0x010 + reg_base, ip2bytes(expectations[1][2]))
    sip = await tb.control.read(0x010 + reg_base, 4)

    await tb.control.write(0x014 + reg_base, ip2bytes(expectations[1][3]))
    dip = await tb.control.read(0x014 + reg_base, 4)

    await tb.control.write(0x018 + reg_base, expectations[1][4].to_bytes(2, 'little'))
    sport = await tb.control.read(0x018 + reg_base, 2)

    await tb.control.write(0x01C + reg_base, expectations[1][5].to_bytes(2, 'little'))
    dport = await tb.control.read(0x01C + reg_base, 2)

    await tb.control.write(0x020 + reg_base, expectations[1][6].to_bytes(2, 'little'))
    ipsum = await tb.control.read(0x020 + reg_base, 2)

    tb.log.info("Set as: {}, {}, {}, {}, {}, {}, {}"
                .format(smac.data, dmac.data, sip.data, dip.data, sport.data, dport.data, ipsum.data))

    # await check_connection_hdr(tb, tb.source_rx[1], tb.p4_ppl_sink, packets[1], *expectations[1])

    # await check_thr(tb, tb.source_rx[1], tb.p4_ppl_sink, thr_pkt1, thr_pkt2)
    # sim_time = get_sim_time('ns')
    # tb.log.info("Ran for {} ns".format(sim_time))

    # * We want to check that packets are transmitted while the PR region maybe
    #   bypassed or connected freely.
    check_thr_coroutine = cocotb.fork(check_thr(
        tb, tb.source_rx[1], tb.p4_ppl_sink, thr_pkt1, thr_pkt2))

    for _ in range(100):
        await RisingEdge(dut.axis_aclk)

    await bypass_region(tb, base)

    # for _ in range(100):
    #     await RisingEdge(dut.axis_aclk)

    # await bypass_region(tb, base)

    # for _ in range(100):
    #     await RisingEdge(dut.axis_aclk)

    # await connect_region(tb, base)

    for _ in range(100):
        await RisingEdge(dut.axis_aclk)

    await connect_region(tb, base)

    await check_thr_coroutine

    await RisingEdge(dut.axis_aclk)
    await RisingEdge(dut.axis_aclk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()
