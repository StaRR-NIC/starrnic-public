import ipaddress

def mac2bytes(mac: str):
    assert len(mac) == 17
    return int("0x{}".format(mac.replace(":", "")), 16).to_bytes(6, 'big').hex()

def ip2bytes(ip: str):
    return int(ipaddress.IPv4Address(ip)).to_bytes(4, 'big').hex()


cmd = "sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2"
base = 0x103000

srcmac = '00:0a:35:dd:4b:c4'
srcip = '10.0.0.55'

# n5 port 0
dstmac = '00:0a:35:02:9d:2f'
dstip = '10.0.0.47'

# n5 port 1
dstmac = '00:0a:35:02:9d:2d'
dstip = '10.0.0.45'

sport = 64000
dport = 64001
ipchksum = 0xeb03

print("{} 0x{:X} w 0x{}".format(cmd, 0x000 + base, mac2bytes(srcmac)[-8:]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x004 + base, mac2bytes(srcmac)[:4]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x008 + base, mac2bytes(dstmac)[-8:]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x00C + base, mac2bytes(dstmac)[:4]))
print("{} 0x{:X} w 0x{}".format(cmd, 0x010 + base, ip2bytes(srcip)))
print("{} 0x{:X} w 0x{}".format(cmd, 0x014 + base, ip2bytes(dstip)))
print("{} 0x{:X} w 0x{}".format(cmd, 0x018 + base, sport.to_bytes(2, 'big').hex()))
print("{} 0x{:X} w 0x{}".format(cmd, 0x01C + base, dport.to_bytes(2, 'big').hex()))
print("{} 0x{:X} w 0x{}".format(cmd, 0x020 + base, ipchksum.to_bytes(2, 'big').hex()))