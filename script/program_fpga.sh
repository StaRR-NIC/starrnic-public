#!/bin/bash

sudo rmmod onic.ko

# TODO(108anup): Adapt for boards with 2 interfaces.
#  Currently only AU50 is supported.

if [ $# -eq 0 ]; then
    echo "Usage: program_device.sh DEVICE_BDF BITSTREAM_PATH BOARD"
    exit 1
fi

set -Eeuo pipefail
set -x

device_bdf="0000:$1"
bridge_bdf=""
bitstream_path=$2
board=$3

if ! which vivado > /dev/null; then
    echo "Please load vivado settings."
    exit 1
fi

# Infer bridge
if [ -e "/sys/bus/pci/devices/$device_bdf" ]; then
    bridge_bdf=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$device_bdf")))
fi

# Remove
if [ $bridge_bdf != "" ]; then
    echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf}/${device_bdf}/remove" > /dev/null
else
    bridge_bdf=0000:3a:00.0
fi

# Program fpga
vivado -mode tcl -source ./program_fpga.tcl \
    -tclargs -board $board \
    -bitstream_path $bitstream_path

# Rescan
echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf}/rescan" > /dev/null
sudo setpci -s $device_bdf COMMAND=0x02

echo "program_fpga.sh completed"
