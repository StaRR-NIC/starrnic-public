# This file is sourced from its parent directory.
# CONFIG.JSON_TIMESTAMP {1654704126}
set p4_file [pwd]/p4/register.p4
puts "Using p4 file: ${p4_file}"

create_ip -name vitis_net_p4 -vendor xilinx.com -library ip -version 1.0 -module_name vitis_net_p4_0
set_property -dict [list \
    CONFIG.USER_META_DATA_WIDTH {274} \
    CONFIG.P4_FILE ${p4_file} \
    CONFIG.TOTAL_LATENCY {25} \
    CONFIG.S_AXI_ADDR_WIDTH {0} \
    CONFIG.M_AXI_HBM_DATA_WIDTH {256} \
    CONFIG.M_AXI_HBM_ADDR_WIDTH {33} \
    CONFIG.M_AXI_HBM_ID_WIDTH {6} \
    CONFIG.M_AXI_HBM_PROTOCOL {0} \
    CONFIG.USER_METADATA_ENABLES { \
        metadata.drop {input true output true} \
        metadata.is_udp {input true output true} \
        metadata.parsed_dport {input true output true} \
        metadata.ipsum {input true output true} \
        metadata.dport {input true output true} \
        metadata.sport {input true output true} \
        metadata.dip {input true output true} \
        metadata.sip {input true output true} \
        metadata.dmac {input true output true} \
        metadata.smac {input true output true} \
        metadata.tuser_dst {input true output true} \
        metadata.tuser_src {input true output true} \
        metadata.tuser_size {input true output true} \
    } \
    CONFIG.USER_META_FORMAT { \
        metadata.drop {length 1 start 0 end 0} \
        metadata.is_udp {length 1 start 1 end 1} \
        metadata.parsed_dport {length 16 start 2 end 17} \
        metadata.ipsum {length 16 start 18 end 33} \
        metadata.dport {length 16 start 34 end 49} \
        metadata.sport {length 16 start 50 end 65} \
        metadata.dip {length 32 start 66 end 97} \
        metadata.sip {length 32 start 98 end 129} \
        metadata.dmac {length 48 start 130 end 177} \
        metadata.smac {length 48 start 178 end 225} \
        metadata.tuser_dst {length 16 start 226 end 241} \
        metadata.tuser_src {length 16 start 242 end 257} \
        metadata.tuser_size {length 16 start 258 end 273} \
    } \
] [get_ips vitis_net_p4_0]
