onerror {
quit -f -code 1
}
set pli [exec cocotb-config --lib-name-path vpi questa]
vsim -voptargs=+acc -onfinish stop \
    -L xil_defaultlib -L xpm -L axis_infrastructure_v1_1_0 -L axis_register_slice_v1_1_22 \
    -L axi_infrastructure_v1_1_0 -L fifo_generator_v13_2_5 -L axi_clock_converter_v2_1_21 \
    -L axis_switch_v1_1_22 -L generic_baseblocks_v2_1_0 -L axi_register_slice_v2_1_22 \
    -L axi_data_fifo_v2_1_21 -L axi_crossbar_v2_1_23 -L unisims_ver -L unimacro_ver \
    -L secureip -lib xil_defaultlib \
    -pli $pli \
    xil_defaultlib.axi_lite_slave_wrapper xil_defaultlib.glbl
log -recursive /*
add log -r *