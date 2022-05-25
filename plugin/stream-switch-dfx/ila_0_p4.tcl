create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0_p4
set_property -dict {
    CONFIG.C_PROBE4_WIDTH {48}
    CONFIG.C_PROBE5_WIDTH {19}
    CONFIG.C_PROBE7_WIDTH {48}
    CONFIG.C_PROBE8_WIDTH {19}
    CONFIG.C_PROBE10_WIDTH {512}
    CONFIG.C_PROBE11_WIDTH {64}
    CONFIG.C_PROBE15_WIDTH {512}
    CONFIG.C_PROBE16_WIDTH {64}
    CONFIG.C_NUM_OF_PROBES {20}
    CONFIG.Component_Name {ila_0_p4}
} [get_ips ila_0_p4]