import ipaddress

def mac2bytes(mac: str):
    assert len(mac) == 17
    return int("0x{}".format(mac.replace(":", "")), 16).to_bytes(6, 'big').hex()

def ip2bytes(ip: str):
    return int(ipaddress.IPv4Address(ip)).to_bytes(4, 'big').hex()


cmd = "sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2"
base = 0x103000

experiment = "throughput"

# ------------------------------------------
# References
# n3 port rx (1)
n3_port1 = '00:0a:35:86:00:01'  # "00:0a:35:ec:b9:9e"
srcip = '10.0.0.57'

# n3 port tx (0)
n3_port0 = '00:0a:35:86:00:00'  # "00:0a:35:23:1d:87"
srcip = '10.0.0.55'

# n5 port 0
n5_port0 = '00:0a:35:02:9d:2f'
dstip = '10.0.0.47'

# n5 port 1
n5_port1 = '00:0a:35:02:9d:2d'
dstip = '10.0.0.45'

# ------------------------------------------
# Throughput Experiment
# n3 port tx (0)
srcmac = n3_port0
srcip = '10.0.0.55'

# n5 port 1
dstmac = n5_port1
dstip = '10.0.0.45'

sport = 64000
dport = 64001
ipchksum = 0x662e

# ------------------------------------------
# Latency Experiment
if(experiment == "latency"):
    # ^^^ n3 tx (port 0), we keep mac different so that the switch
    # does not learn a bad port to mac mapping.
    srcip = '10.0.0.57'  # n3 rx (port 1), because the recver has this in socket

    # n5 port 0
    dstmac = n5_port0
    dstip = '10.0.0.47'

    sport = 62177
    dport = 60512
    ipchksum = 0x662a

print("{} 0x{:X} w 0x{}".format(cmd, 0x000 + base, mac2bytes(srcmac)[-8:]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x004 + base, mac2bytes(srcmac)[:4]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x008 + base, mac2bytes(dstmac)[-8:]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x00C + base, mac2bytes(dstmac)[:4]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x010 + base, ip2bytes(srcip)))
print("{} 0x{:X} w 0x{}".format(cmd, 0x014 + base, ip2bytes(dstip)))
print("{} 0x{:X} w 0x{}".format(cmd, 0x018 + base, sport.to_bytes(2, 'big').hex()))
print("{} 0x{:X} w 0x{}".format(cmd, 0x01C + base, dport.to_bytes(2, 'big').hex()))
print("{} 0x{:X} w 0x{}".format(cmd, 0x020 + base, ipchksum.to_bytes(2, 'big').hex()))

from scapy.all import Ether, IP, UDP, wrpcap, raw, TCP
print("DUT RX")
(Ether(src='00:0a:35:02:9d:2f', dst='00:0a:35:bd:11:be') / IP(id=0, src='10.0.0.47', dst='10.0.0.57') / UDP(sport=60512, dport=62177) / (b'\xa0'*64)).show2()
print("DUT TX")
(Ether(src=srcmac, dst=dstmac) / IP(id=0, src=srcip, dst=dstip) / UDP(sport=sport, dport=dport) / (b'\xa0'*64)).show2()