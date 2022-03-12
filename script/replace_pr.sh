#!/bin/bash

# The addresses in this script and logic is specific to the stream-switch design

if [ $# -eq 0 ] || [[ $STARRNIC_SETUP != "true" ]] || [[ -z $XILINX_VIVADO ]]; then
    echo "Usage: replace_pr.sh PARTIAL_BITSTREAM"
    echo "Need to have set STARRNIC_SETUP (includes DEVICE_BDF, EXTENDED_DEVICE_BDF, PCIMEM, STARRNIC_SHELL)"
    echo "Need to have setup Vivado as well"
    exit 1
fi

set -Eeuo pipefail
set -x

partial_bitstream=$1

bypass_region () {
    echo "Bypassing..."
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x100040 w 0x00
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x100044 w 0x80000000
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x100000 w 0x02
    echo ""
}

connect_region () {
    echo "Connecting..."
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x100040 w 0x80000000
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x100044 w 0x00
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x100000 w 0x02
    echo ""
}

read_counter_value () {
    echo "Reading..."
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x140000
}

check_read_temperature () {
    echo "Checking temperature..."
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF/resource2 0x10400
    # TODO: check and assert if above output seems fine
}

check_read_temperature

# Check if current RM works
connect_region
read_counter_value

# Bypass the region
bypass_region
read_counter_value # (should be arbit value)

# Reconfigure
echo "Reconfiguring using $partial_bitstream..."
vivado -mode tcl -source $STARRNIC_SHELL/script/program_fpga.tcl \
    -tclargs -board $BOARD \
    -bitstream_path $partial_bitstream

# move packets back to region
connect_region
read_counter_value