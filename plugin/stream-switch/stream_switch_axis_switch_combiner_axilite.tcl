set axis_switch axis_switch_combiner_axilite
create_ip -name axis_switch -vendor xilinx.com -library ip -module_name $axis_switch
set_property -dict {
    CONFIG.ROUTING_MODE {1}
    CONFIG.TDATA_NUM_BYTES {64}
    CONFIG.HAS_TKEEP {1}
    CONFIG.HAS_TLAST {1}
    CONFIG.TUSER_WIDTH {48}
 } [get_ips $axis_switch]
