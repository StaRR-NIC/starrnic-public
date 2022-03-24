#!/bin/bash

sudo rmmod onic.ko

if [[ $# -ne 2 ]] || [[ -z EXTENDED_DEVICE_BDF1 ]] || [[ -z $XILINX_VIVADO ]]; then
    echo "Usage: program_device.sh BITSTREAM_PATH BOARD"
    echo "Please export EXTENDED_DEVICE_BDF1 and EXTENDED_DEVICE_BDF2 (if needed for 2 port boards)"
    echo "Please load vivado into system path."
    exit 1
fi

set -Eeuo pipefail
set -x

bridge_bdf=""
bitstream_path=$1
board=$2

# Infer bridge
if [ -e "/sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1" ]; then
    bridge_bdf=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1")))
    # Both devices will be on the same bridge as they are on the same FPGA board.
fi

# Remove
if [[ $bridge_bdf != "" ]]; then
    echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf}/${EXTENDED_DEVICE_BDF1}/remove" > /dev/null
    if [[ -n $EXTENDED_DEVICE_BDF2 ]] && [[ -e "/sys/bus/pci/devices/${bridge_bdf}/${EXTENDED_DEVICE_BDF2}" ]]; then
        echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf}/${EXTENDED_DEVICE_BDF2}/remove" > /dev/null
    fi
else
    echo "Could not find brigde_bdf for the device $EXTENDED_DEVICE_BDF1"
    echo "If remove was called on the device already, then manually set bridge_bdf here and comment 'exit 1'."

    # bridge_bdf="0000:3a:00.0" # AU50  on n1
    # bridge_bdf="0000:85:00.0" # AU280 on n3

    exit 1
fi

# Program fpga
vivado -mode tcl -source ./program_fpga.tcl \
    -tclargs -board $board \
    -bitstream_path $bitstream_path

# Rescan
echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf}/rescan" > /dev/null
sudo setpci -s $EXTENDED_DEVICE_BDF1 COMMAND=0x02
if [[ -n $EXTENDED_DEVICE_BDF2 ]]; then
    sudo setpci -s $EXTENDED_DEVICE_BDF2 COMMAND=0x02
fi

echo "program_fpga.sh completed"
