set axis_switch axis_switch_combiner_tdest
create_ip -name axis_switch -vendor xilinx.com -library ip -module_name $axis_switch
set_property -dict {
    CONFIG.TDATA_NUM_BYTES {64}
    CONFIG.HAS_TKEEP {1}
    CONFIG.HAS_TLAST {1}
    CONFIG.TUSER_WIDTH {48}
    CONFIG.ARB_ON_TLAST {1}
 } [get_ips $axis_switch]
