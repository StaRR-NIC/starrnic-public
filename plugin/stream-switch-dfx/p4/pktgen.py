from scapy.all import Ether, IP, UDP, TCP, wrpcap, raw

packet1 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / ("Hello world!" * 100)
packet2 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / ("Hello world!" * 100)
packet3 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62178) / ("Hello world!" * 100)
packet4 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / TCP(sport=111, dport=62178) / ("Hello world!" * 100)
my_packet = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / (b'\x01'*16)
packets = [packet1, packet2, packet3, packet4, my_packet]

packets = [
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / (b'\xa0'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / (b'\xa1'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62178) / (b'\xa2'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62179) / (b'\xa3'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62180) / (b'\xa4'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / TCP(sport=111, dport=62176) / (b'\xcc'*16),
]

# For p4 register
packets = [
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / (b'\xa0'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / (b'\xa1'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62178) / (b'\xa2'*16),
    Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / TCP(sport=111, dport=62176) / (b'\xcc'*16)
]

wrpcap('traffic_in.pcap', packets)
# with open('traffic_in.user', 'w') as f:
#     for packet in packets:
#         f.write(raw(packet).hex(' '))
#         f.write('\n;\n')