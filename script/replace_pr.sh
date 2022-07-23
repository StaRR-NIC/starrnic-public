#!/bin/bash

# Works for au280 and u50
# The addresses in this script and logic is specific to the stream-switch design

echo "Got args: $#"
if [[ $# -lt 2 ]] || [[ -z $XILINX_VIVADO ]] || [[ -z $PCIMEM ]] || [[ -z $EXTENDED_DEVICE_BDF1 ]] || [[ -z $STARRNIC_SHELL ]]; then
    echo "Usage: replace_pr.sh PARTIAL_BITSTREAM BOARD OPTIONAL[LTX FILE]"
    echo "Please export PCIMEM to point to pcimem binary."
    echo "Please export STARRNIC_SHELL as path to starrnic_shell."
    echo "Please export EXTENDED_DEVICE_BDF1 to point to the FPGA NIC."
    echo "Please ensure vivado is in path."
    exit 1
fi

set -Eeuo pipefail
# set -x

partial_bitstream=$1
board=$2
probes_path="${3:-}"

read_counter_value () {
    echo "Counter value"
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x140000 | tail -n 1
}

check_read_temperature () {
    echo "Checking temperature"
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10400 | tail -n 1
    # TODO: check and assert if above output seems fine
}

# check_region () {
#     echo "Current regions (0x80000000 means not in use)"
#     echo "Counter"
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100044 | tail -n 1
#     echo "Bypass"
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100040 | tail -n 1
# }

# bypass_region () {
#     echo "Bypassing counter"
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100040 w 0x00 | tail -n 1
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100044 w 0x80000000 | tail -n 1
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000 w 0x02 | tail -n 1
# }

# connect_region () {
#     echo "Connecting counter"
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100040 w 0x80000000 | tail -n 1
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100044 w 0x00 | tail -n 1
#     sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000 w 0x02 | tail -n 1
# }

check_region () {
    echo "0 means bypass, 1 means connected"
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100004 | tail -n 1
}

bypass_region () {
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100004 w 0x0 | tail -n 1
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000 w 0x1 | tail -n 1
}

connect_region () {
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100004 w 0x1 | tail -n 1
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000 w 0x1 | tail -n 1
}

echo "--------------------------------------------------------------------------------"
check_read_temperature
check_region
echo ""

# # Check if current RM works
# connect_region
# read_counter_value
# check_region
# echo ""

# Bypass the region
echo "Bypassing"
bypass_region
read_counter_value # (should be arbit value)
check_region
echo ""

# Reconfigure
echo "Reconfiguring using $partial_bitstream..."
echo ""
vivado -mode tcl -source $STARRNIC_SHELL/script/program_fpga.tcl \
    -tclargs -board $board \
    -bitstream_path $partial_bitstream \
    -probes_path $probes_path
echo ""

# move packets back to region
echo "Connecting back"
connect_region
read_counter_value
check_region
echo ""
echo "--------------------------------------------------------------------------------"
