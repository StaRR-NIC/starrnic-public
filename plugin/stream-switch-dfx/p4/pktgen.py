from scapy.all import Ether, IP, UDP, TCP, wrpcap, raw

packet1 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62176) / "Hello world!"
packet2 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62177) / "Hello world!"
packet3 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / UDP(sport=111, dport=62178) / "Hello world!"
packet4 = Ether(src='ff:0a:35:bc:7a:bc', dst='00:0a:35:bc:7a:bc') / IP(src='10.0.0.40', dst='10.0.0.53') / TCP(sport=111, dport=62178) / "Hello world!"
packets = [packet1, packet2, packet3, packet4]

wrpcap('traffic_in.pcap', packets)
with open('traffic_in.user', 'w') as f:
    for packet in packets:
        f.write(raw(packet).hex(' '))
        f.write('\n;\n')