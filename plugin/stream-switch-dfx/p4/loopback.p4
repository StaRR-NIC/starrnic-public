#include <core.p4>
#include <xsa.p4>

/*
 * Only considers UDP packets, drops all other packets.
 * Changes src IP, src port, src MAC to a hard coded value.
 * Dst IP, port, MAC can be hardcoded or copied from src values in the unmodified packet.
 */

typedef bit<48>  MacAddr;
typedef bit<32>  IPv4Addr;
typedef bit<16>  UdpPort;

const bit<16> VLAN_TYPE = 0x8100;
const bit<16> IPV4_TYPE = 0x0800;
const bit<8>  UDP_PROT  = 0x11;

// N3, port 0
const bit<32> SRC_IP    = 0x0a000035;     // 10.0.0.53
const bit<48> SRC_MAC   = 0x000a35bc7abc; // 00:0a:35:bc:7a:bc
const bit<16> SRC_PORT0 = 16w62176;       // 62176
const bit<16> SRC_PORT1 = 16w62177;       // 62177
const bit<16> SRC_PORT2 = 16w62178;       // 62178

// N5 port 1
const bit<32> DST_IP1   = 0x0a00002d;     // 10.0.0.45
const bit<16> DST_PORT1 = 16w60512;       // 60512
const bit<48> DST_MAC1  = 0x000a35029d2d; // 00:0a:35:02:9d:2d

 // N5, port 0
const bit<32> DST_IP2   = 0x0a00002f;     // 10.0.0.47
const bit<16> DST_PORT2 = 16w60513;       // 60513
const bit<48> DST_MAC2  = 0x000a35029d2f; // 00:0a:35:02:9d:2f


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
    bit<2> is_same;
    bit<2> is_udp;
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

    // MacAddr  tmp_eth_addr;
    // IPv4Addr tmp_ip_addr;
    // UdpPort  tmp_udp_port;

    // action dropPacket() {
    //     smeta.drop = 1;
    // }

    // action swap_eth_address() {
    //     tmp_eth_addr = hdr.eth.dmac;
    //     hdr.eth.dmac = hdr.eth.smac;
    //     hdr.eth.smac = tmp_eth_addr;
    // }

    // action swap_ip_address() {
    //     tmp_ip_addr  = hdr.ipv4.dst;
    //     hdr.ipv4.dst = hdr.ipv4.src;
    //     hdr.ipv4.src = tmp_ip_addr;
    // }

    // action swap_udp_address() {
    //     tmp_udp_port     = hdr.udp.dst_port;
    //     hdr.udp.dst_port = hdr.udp.src_port;
    //     hdr.udp.src_port = tmp_udp_port;
    // }

    // action echo_hard1() {
    //     hdr.eth.smac = SRC_MAC;
    //     hdr.ipv4.src = SRC_IP;
    //     hdr.udp.src_port = SRC_PORT1;

    //     hdr.eth.dmac = DST_MAC1;
    //     hdr.ipv4.dst = DST_IP1;
    //     hdr.udp.dst_port = DST_PORT1;
    // }

    // action echo_hard2() {
    //     hdr.eth.smac = SRC_MAC;
    //     hdr.ipv4.src = SRC_IP;
    //     hdr.udp.src_port = SRC_PORT2;

    //     hdr.eth.dmac = DST_MAC2;
    //     hdr.ipv4.dst = DST_IP2;
    //     hdr.udp.dst_port = DST_PORT2;
    // }

    // action echo_packet() {
    //     swap_eth_address();
    //     swap_ip_address();
    //     swap_udp_address();
    // }

    action same() {
        meta.is_same = 0x1;
    }

    action diff() {
        meta.is_same = 0x2;
    }

    apply {
        if (hdr.udp.isValid()) {
            meta.is_udp = 0x2;
            // smeta.drop = 0;
            meta.drop = 0;
            if(hdr.udp.dst_port == SRC_PORT0) {
                same();
            }
            else {
                diff();
            }
        } else {
            meta.is_udp = 0x1;
            meta.drop = 1;
            // smeta.drop = 1;
        }
        // if (hdr.udp.isValid()) {
        //     if (hdr.udp.dst_port == SRC_PORT0) {
        //         echo_packet();
        //     }
        //     else if (hdr.udp.dst_port == SRC_PORT1) {
        //         echo_hard1();
        //     }
        //     else if (hdr.udp.dst_port == SRC_PORT2) {
        //         echo_hard2();
        //     }
        //     else {
        //         // dropPacket();
        //     }
        // }
        // else {
        //     // dropPacket();
        // }
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