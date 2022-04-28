from scapy.all import Ether, IP, UDP, wrpcap, raw

packet1 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / "Hello world!"
packet2 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / "Hello world!"
packet3 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62178) / "Hello world!"

wrpcap('pcap/traffic_in.pcap', [packet1, packet2, packet3])
with open('traffic_in.user', 'w') as f:
    for packet in [packet1, packet2, packet3]:
        f.write(raw(packet).hex(' '))
        f.write('\n;\n')