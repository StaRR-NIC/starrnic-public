# Export GUI and DUT before calling this.

onerror {
quit -f -code 1
}

set pli [exec cocotb-config --lib-name-path vpi questa]
if {${env(GUI)}} {
    set onfinish "stop"
} else {
    set onfinish "exit"
}

vsim -voptargs=+acc -onfinish $onfinish \
    -L xil_defaultlib -L xpm -L axis_infrastructure_v1_1_0 -L axis_register_slice_v1_1_22 \
    -L axi_infrastructure_v1_1_0 -L fifo_generator_v13_2_5 -L axi_clock_converter_v2_1_21 \
    -L axis_switch_v1_1_22 -L generic_baseblocks_v2_1_0 -L axi_register_slice_v2_1_22 \
    -L axi_data_fifo_v2_1_21 -L axi_crossbar_v2_1_23 -L unisims_ver -L unimacro_ver \
    -L secureip -lib xil_defaultlib \
    -pli $pli \
    xil_defaultlib.${env(DUT)} xil_defaultlib.glbl

# vsim -voptargs="+acc" -onfinish $onfinish \
#      +transport_int_delays +pulse_e/0 +pulse_int_e/0 \
#      +pulse_r/0 +pulse_int_r/0 \
#      -L xil_defaultlib -L simprims_ver -L secureip \
#      -lib xil_defaultlib xil_defaultlib.${env(DUT)} xil_defaultlib.glbl

log -recursive /*

if {${env(GUI)}} { 
    add log -r *
} else {
    onbreak resume
    run -all
    quit
}