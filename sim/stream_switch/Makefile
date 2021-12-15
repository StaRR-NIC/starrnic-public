TOPLEVEL_LANG = verilog

RTL_LIBRARY=xil_defaultlib
SIM ?= modelsim
WAVES ?= 0
GUI ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ns

TOPLEVEL = stream_switch_250mhz
MODULE   = test_stream_switch

SIM_ARGS=-modelsimini /home/ubuntu/Projects/StaRR-NIC/open-nic-shell/build/au50/open_nic_shell/open_nic_shell.sim/sim_1/behav/modelsim/modelsim.ini -voptargs="+acc" -L xil_defaultlib -L xpm -L axis_infrastructure_v1_1_0 -L axis_register_slice_v1_1_22 -L axi_infrastructure_v1_1_0 -L fifo_generator_v13_2_5 -L axi_clock_converter_v2_1_21 -L axis_switch_v1_1_22 -L generic_baseblocks_v2_1_0 -L axi_register_slice_v2_1_22 -L axi_data_fifo_v2_1_21 -L axi_crossbar_v2_1_23 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib

include $(shell cocotb-config --makefiles)/Makefile.sim