#include <core.p4>
#include <xsa.p4>

/*
 * Only considers UDP packets, drops all other packets.
 * Changes src IP, src port, src MAC to dst IP, dst port, dst MAC based on user metadata.
 * Can also swap src/dst.
 */

typedef bit<48>  MacAddr;
typedef bit<32>  IPv4Addr;
typedef bit<16>  UdpPort;

const bit<16> VLAN_TYPE = 0x8100;
const bit<16> IPV4_TYPE = 0x0800;
const bit<8>  UDP_PROT  = 0x11;

// ****************************************************************************** //
// *************************** H E A D E R S  *********************************** //
// ****************************************************************************** //

header eth_mac_t {
    MacAddr dmac; // Destination MAC address
    MacAddr smac; // Source MAC address
    bit<16> type; // Tag Protocol Identifier
}

header vlan_t {
    bit<3>  pcp;  // Priority code point
    bit<1>  cfi;  // Drop eligible indicator
    bit<12> vid;  // VLAN identifier
    bit<16> tpid; // Tag protocol identifier
}

header ipv4_t {
    bit<4>   version;  // Version (4 for IPv4)
    bit<4>   hdr_len;  // Header length in 32b words
    bit<8>   tos;      // Type of Service
    bit<16>  length;   // Packet length in 32b words
    bit<16>  id;       // Identification
    bit<3>   flags;    // Flags
    bit<13>  offset;   // Fragment offset
    bit<8>   ttl;      // Time to live
    bit<8>   protocol; // Next protocol
    bit<16>  hdr_chk;  // Header checksum
    IPv4Addr src;      // Source address
    IPv4Addr dst;      // Destination address
}

header ipv4_opt_t {
    varbit<320> options; // IPv4 options - length = (ipv4.hdr_len - 5) * 32
}

header udp_t {
    UdpPort src_port;  // Source port
    UdpPort dst_port;  // Destination port
    bit<16> length;    // UDP length
    bit<16> checksum;  // UDP checksum
}

// ****************************************************************************** //
// ************************* S T R U C T U R E S  ******************************* //
// ****************************************************************************** //

// header structure
struct headers {
    eth_mac_t    eth;
    vlan_t[2]    vlan;
    ipv4_t       ipv4;
    ipv4_opt_t   ipv4opt;
    udp_t        udp;
}

// User metadata structure
struct metadata {
    bit<16> tuser_size;
    bit<16> tuser_src;
    bit<16> tuser_dst;

    bit<48> smac;
    bit<48> dmac;
    bit<32> sip;
    bit<32> dip;
    bit<16> sport;
    bit<16> dport;
    bit<16> ipsum;

    bit<16> parsed_dport;
    bit<1> is_udp;
    bit<1> drop;
}

// User-defined errors
error {
    InvalidIPpacket
}

// ****************************************************************************** //
// *************************** P A R S E R  ************************************* //
// ****************************************************************************** //

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t smeta) {

    state start {
        transition parse_eth;
    }

    state parse_eth {
        packet.extract(hdr.eth);
        transition select(hdr.eth.type) {
            VLAN_TYPE : parse_vlan;
            IPV4_TYPE : parse_ipv4;
            default   : accept;
        }
    }

    state parse_vlan {
        packet.extract(hdr.vlan.next);
        transition select(hdr.vlan.last.tpid) {
            VLAN_TYPE : parse_vlan;
            IPV4_TYPE : parse_ipv4;
            default   : accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        verify(hdr.ipv4.version == 4 && hdr.ipv4.hdr_len >= 5, error.InvalidIPpacket);
        packet.extract(hdr.ipv4opt, (((bit<32>)hdr.ipv4.hdr_len - 5) * 32));
        transition select(hdr.ipv4.protocol) {
            UDP_PROT  : parse_udp;
            default   : accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
}

// ****************************************************************************** //
// **************************  P R O C E S S I N G   **************************** //
// ****************************************************************************** //

control MyProcessing(inout headers hdr,
                     inout metadata meta,
                     inout standard_metadata_t smeta) {

    MacAddr  tmp_eth_addr;
    IPv4Addr tmp_ip_addr;
    UdpPort  tmp_udp_port;

    // action dropPacket() {
    //     meta.drop = 1;
    // }

    action swap_eth_address() {
        tmp_eth_addr = hdr.eth.dmac;
        hdr.eth.dmac = hdr.eth.smac;
        hdr.eth.smac = tmp_eth_addr;
    }

    action swap_ip_address() {
        tmp_ip_addr  = hdr.ipv4.dst;
        hdr.ipv4.dst = hdr.ipv4.src;
        hdr.ipv4.src = tmp_ip_addr;
    }

    action swap_udp_address() {
        tmp_udp_port     = hdr.udp.dst_port;
        hdr.udp.dst_port = hdr.udp.src_port;
        hdr.udp.src_port = tmp_udp_port;
    }

    action echo_packet() {
        swap_eth_address();
        swap_ip_address();
        swap_udp_address();
    }

    action set_using_metadata() {
        hdr.eth.smac = meta.smac;
        hdr.eth.dmac = meta.dmac;
        hdr.ipv4.src = meta.sip;
        hdr.ipv4.dst = meta.dip;
        hdr.udp.src_port = meta.sport;
        hdr.udp.dst_port = meta.dport;
        hdr.ipv4.hdr_chk = meta.ipsum;
    }

    apply {
        if (hdr.udp.isValid()) {
            meta.is_udp = 1;
            meta.drop = 0;
            meta.parsed_dport = hdr.udp.dst_port;
            if(hdr.udp.dst_port == 16w62176) {
                echo_packet();
            }
            else if (hdr.udp.dst_port == 16w62177) {
                set_using_metadata();
            }
            else {
                meta.drop = 1;
                smeta.drop = 1;
            }
        } else {
            meta.is_udp = 0;
            meta.drop = 1;
            smeta.drop = 1;
        }
    }
}

// ****************************************************************************** //
// ***************************  D E P A R S E R  ******************************** //
// ****************************************************************************** //

control MyDeparser(packet_out packet,
                   in headers hdr,
                   inout metadata meta,
                   inout standard_metadata_t smeta) {
    apply {
        packet.emit(hdr.eth);
        packet.emit(hdr.vlan);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4opt);
        packet.emit(hdr.udp);
    }
}

// ****************************************************************************** //
// *******************************  M A I N  ************************************ //
// ****************************************************************************** //

XilinxPipeline(
    MyParser(),
    MyProcessing(),
    MyDeparser()
) main;