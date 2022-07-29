#!/bin/bash

if [[ -z $PCIMEM ]] || [[ -z $EXTENDED_DEVICE_BDF1 ]]; then
    echo "Please export PCIMEM to point to pcimem binary."
    echo "Please export EXTENDED_DEVICE_BDF to point to the FPGA NIC."
    exit 1
fi

set -Eeuo pipefail
set -x

EXPERIMENT="${1:-}"
if [[ -z $EXPERIMENT ]]; then
    echo "Please specify experiment name (throughput, or latency)."
    exit 1
fi

# Read temperature
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10400

if [[ $EXPERIMENT == "latency" ]]; then
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103000 w 0x35860000
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103004 w 0x000a
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103008 w 0x35029d2f
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10300C w 0x000a
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103010 w 0x0a000039
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103014 w 0x0a00002f
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103018 w 0xf2e1
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10301C w 0xec60
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103020 w 0x662a

elif [[ $EXPERIMENT == "throughput" ]]; then
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103000 w 0x35860000
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103004 w 0x000a
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103008 w 0x35029d2d
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10300C w 0x000a
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103010 w 0x0a000037
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103014 w 0x0a00002d
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103018 w 0xfa00
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10301C w 0xfa01
    sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103020 w 0x662e

else
    echo "Invalid experiment: \"$EXPERIMENT\""
fi

# Read current registers
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103000 "w*2" # src mac
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103008 "w*2" # dst mac
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103010 "w*1" # src ip
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103014 "w*1" # dst ip
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103018 "w*1" # sport
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x10301C "w*1" # dport
sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x103020 "w*1" # chksum