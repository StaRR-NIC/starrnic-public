#!/bin/bash

START_DIR=$PWD
PCIMEM_PATH="/home/ubuntu/opt/pcimem"
DRIVER_PATH="/home/ubuntu/Projects/StaRR-NIC/open-nic-driver"

cd $DRIVER_PATH
sudo insmod onic.ko
sudo ifconfig enp59s0 10.0.0.57/24 up

cd $PCIMEM_PATH
sudo ./pcimem /sys/bus/pci/devices/0000:3b:00.0/resource2 0x10400
# sudo ./pcimem /sys/bus/pci/devices/0000:3b:00.0/resource2 0x100000
sudo ./pcimem /sys/bus/pci/devices/0000:3b:00.0/resource2 0x100040 w 0x00
sudo ./pcimem /sys/bus/pci/devices/0000:3b:00.0/resource2 0x100000 w 0x02

ping 10.0.0.61 -c 1

cd $START_DIR