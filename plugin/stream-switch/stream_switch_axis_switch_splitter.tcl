set axis_switch axis_switch_splitter
create_ip -name axis_switch -vendor xilinx.com -library ip -module_name $axis_switch
set_property -dict [list 
    CONFIG.NUM_SI {1}
    CONFIG.NUM_MI {2}
    CONFIG.ROUTING_MODE {1}
    CONFIG.TDATA_NUM_BYTES {512}
    CONFIG.HAS_TKEEP {1}
    CONFIG.HAS_TLAST {1}
    CONFIG.TDEST_WIDTH {0}
    CONFIG.TUSER_WIDTH {48}
    CONFIG.DECODER_REG {0}
] [get_ips $axis_switch]