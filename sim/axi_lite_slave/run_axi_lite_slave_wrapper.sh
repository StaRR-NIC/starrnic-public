#!/bin/bash

bin_path="/home/ubuntu/opt/modelsim/modelsim-se_2020.1/modeltech/linux_x86_64"
# set -Eeuo pipefail
export LIBPYTHON_LOC=$(cocotb-config --libpython)
export DUT=axi_lite_slave_wrapper
export MODULE=test_${DUT}
export TOP_LEVEL=${DUT}
vlog -64 -incr -sv -work xil_defaultlib ./${DUT}.sv

if [[ ${GUI} == "1" ]]; then
    $bin_path/vsim -64 -gui -do "do {run_${DUT}_gui.do}" -l simulate.log
else
    $bin_path/vsim -64 -c -do "do {run_${DUT}.do}" -l simulate.log
fi
