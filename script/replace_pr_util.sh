#!/bin/bash

source /datadrive/StaRR-NIC/starrnic-tools/global_setup.sh
source /datadrive/StaRR-NIC/starrnic-tools/source_fpga_setup.sh

echo "Args (count $#):: $@"

echo "Env: $XILINX_VIVADO, $PCIMTM, $EXTENDED_DEVICE_BDF1, $STARRNIC_SHELL"
if [[ $# -lt 2 ]] || [[ -z $XILINX_VIVADO ]] || [[ -z $PCIMEM ]] || [[ -z $EXTENDED_DEVICE_BDF1 ]] || [[ -z $STARRNIC_SHELL ]]; then
    echo "Usage: replace_pr_util.sh PARTIAL_BITSTREAM BOARD OPTIONAL[LTX FILE]"
    echo "Please export PCIMEM to point to pcimem binary."
    echo "Please export STARRNIC_SHELL as path to starrnic_shell."
    echo "Please export EXTENDED_DEVICE_BDF1 to point to the FPGA NIC."
    echo "Please ensure vivado is in path."
    exit 1
fi

SCRIPTPATH="$(cd -- "$(dirname "$0")" > /dev/null 2>&1; pwd -P)"
$SCRIPTPATH/replace_pr.sh "$@"