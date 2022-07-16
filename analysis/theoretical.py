import matplotlib.pyplot as plt
import numpy as np


MIN_FRAME = 64
MAX_FRAME = 1518

G_TO_M = 1000
NANO_TO_MICRO = 1000
BITS_PER_BYTE = 8

# All units in bytes
PREAMBLE = 8
INTER_PACKET_GAP = 12
ETH_HDR = 18
IP_HDR = 20
UDP_HDR = 8
FLIT_SIZE = 64


def _payload(frame):
    return frame - (ETH_HDR + IP_HDR + UDP_HDR)


def _frame(payload):
    return ETH_HDR + IP_HDR + UDP_HDR + payload


def _wire_frame(frame):
    return PREAMBLE + frame + INTER_PACKET_GAP


def _bytes_per_flit(frame):
    flits_per_frame = frame / FLIT_SIZE
    ceil_flits_per_frame = np.ceil(flits_per_frame)

    bytes_per_flit = frame / ceil_flits_per_frame
    return bytes_per_flit


# Production
def expected_gbps(cycle_per_us=250, flits_per_cycle=1, frame=64):
    flits_per_frame = frame / FLIT_SIZE
    ceil_flits_per_frame = np.ceil(flits_per_frame)
    bytes_per_flit = frame / ceil_flits_per_frame
    gbps = bytes_per_flit * flits_per_cycle * cycle_per_us / NANO_TO_MICRO
    return gbps


# Theoretical max
def _theoretical_max_frame_gbps(payload=18, link_gbps=100):
    frame = _frame(payload)
    wire_frame = _wire_frame(frame)

    max_frame_gbps = link_gbps * frame / wire_frame
    return max_frame_gbps


# Requirements
def required_m_frames_ps(payload=18, link_gbps=100):
    frame = _frame(payload)
    wire_frame = _wire_frame(frame)

    m_frames_ps = link_gbps * G_TO_M / (wire_frame * BITS_PER_BYTE)
    return m_frames_ps


def required_flits_per_cycle(payload=18, link_gbps=100):
    frame = _frame(payload)
    m_frames_ps = required_m_frames_ps(payload, link_gbps)

    flits_per_frame = frame / FLIT_SIZE
    ceil_flits_per_frame = np.ceil(flits_per_frame)
    # m_filts_ps = flits_per_frame * m_frames_ps
    ceil_m_flits_ps = ceil_flits_per_frame * m_frames_ps

    cycle_per_us = 250
    us_per_cycle = 1 / cycle_per_us
    # ns_per_cycle = NANO_TO_MICRO / cycle_per_us
    flits_per_cycle = ceil_m_flits_ps * us_per_cycle
    return flits_per_cycle


# Production
def _ideal_produced_gbps(payload=18, flits_per_cycle=1, cycle_per_us=250):
    frame = _frame(payload)
    bytes_per_flit = _bytes_per_flit(frame)

    gbps = BITS_PER_BYTE * bytes_per_flit * flits_per_cycle * cycle_per_us / NANO_TO_MICRO
    return gbps


# Measured
def measured_m_frames_ps(measured_gbps, payload=18):
    frame = _frame(payload)

    m_frames_ps = measured_gbps * G_TO_M / (BITS_PER_BYTE * frame)
    return m_frames_ps


def measured_cycles_per_flit(measured_gbps, cycles_per_us=250, payload=18):
    frame = _frame(payload)
    bytes_per_flit = _bytes_per_flit(frame)

    m_flits_ps = measured_gbps * G_TO_M / (BITS_PER_BYTE * bytes_per_flit)
    flits_per_cycle = m_flits_ps / cycles_per_us
    return 1 / flits_per_cycle


frame = np.arange(MIN_FRAME, MAX_FRAME+1)
payload = _payload(frame)
ideal_produced_gbps = _ideal_produced_gbps(payload)
theoretical_max_frame_gbps = _theoretical_max_frame_gbps(payload, 100)

fig, ax = plt.subplots()
ax.plot(frame, ideal_produced_gbps, label="Max thr due to clock & flit size")
ax.plot(frame, theoretical_max_frame_gbps, label="Max thr due to pkt headers")
ax.plot(frame, np.minimum(theoretical_max_frame_gbps, ideal_produced_gbps), label="Max thr")
ax.set_ylabel('Throughput (Gbps)')
ax.set_xlabel('Frame size (bytes)')
ax.grid(True)
ax.legend()
ax.set_xticks([x for x in range(MIN_FRAME, MAX_FRAME+1, 64)] + [MAX_FRAME])
ax.set_xticklabels(ax.get_xticks(), rotation=45)

# figname = fpath.replace(".csv", ".pdf")
fig.savefig("theoretical.pdf", pad_inches=0.01, bbox_inches="tight")
