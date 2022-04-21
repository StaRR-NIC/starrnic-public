#!/bin/bash

if [[ -z $PCIMEM ]] || [[ -z $OPEN_NIC_DRIVER ]] || [[ -z $EXTENDED_DEVICE_BDF1 ]] || [[ -z $STARRNIC_IP1 ]]; then
    echo "Please export PCIMEM to point to pcimem binary."
    echo "Please export OPEN_NIC_DRIVER as path to open_nic_driver."
    echo "Please export EXTENDED_DEVICE_BDF to point to the FPGA NIC."
    echo "Please set STARRNIC_IP1"
    exit 1
fi

set -Eeuo pipefail
set -x

START_DIR=$PWD

cd $OPEN_NIC_DRIVER
sudo insmod onic.ko
sudo ifconfig $STARRNIC_IFACE1 $STARRNIC_IP1/24 up
if [[ -n $STARRNIC_IFACE2 ]] && [[ -n $STARRNIC_IP2 ]]; then
    sudo ifconfig $STARRNIC_IFACE2 $STARRNIC_IP2/24 up
fi

# Read temperature
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10400

# Read current splitter control register
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000

# Use counter
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100040 w 0x80000000
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100044 w 0x00
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000 w 0x02

# Bypass
# sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100040 w 0x00
# sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100044 w 0x80000000
# sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x100000 w 0x02

ping 10.0.0.61 -c 1  # this is IP of Intel XL710 NIC. Since this is on switch, all devices can access this.

cd $START_DIR