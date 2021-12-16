#!/bin/bash
set -Eeuo pipefail

# Export DUT and GUI variables before calling this script.
bin_path="/home/ubuntu/opt/modelsim/modelsim-se_2020.1/modeltech/linux_x86_64"
export LIBPYTHON_LOC=$(cocotb-config --libpython)
export MODULE=test_${DUT}
export TOP_LEVEL=${DUT}

if [[ -f ./${DUT}.sv ]]; then
    vlog -64 -incr -sv -work xil_defaultlib ./${DUT}.sv
fi

if [[ ${GUI} == "1" ]]; then
    SIM_ARGS="-gui"
else
    SIM_ARGS="-c"
fi

GUI=$GUI DUT=$DUT $bin_path/vsim -64 ${SIM_ARGS} -do "do {run.do}" -l simulate.log