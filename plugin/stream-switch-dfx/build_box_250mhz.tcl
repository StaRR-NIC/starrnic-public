# *************************************************************************
#
# Copyright 2020 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# *************************************************************************
# read_verilog -quiet -sv pkt_size_counter.sv
# read_verilog -quiet -sv pkt_size_counter5.sv

# Verilog AXIS modules from https://github.com/alexforencich/verilog-axis/
read_verilog -quiet verilog_axis/priority_encoder.v
read_verilog -quiet verilog_axis/arbiter.v
read_verilog -quiet verilog_axis/axis_arb_mux.v
read_verilog -quiet verilog_axis/axis_demux.v

source stream_switch_axi_crossbar.tcl
read_verilog -quiet stream_switch_address_map_inst.vh
read_verilog -quiet starrnic_bypass.vh
read_verilog -quiet stream_switch_address_map.v

# source stream_switch_axis_switch_combiner_axilite.tcl
# source axis_switch_combiner_tdest.tcl
# source axis_switch_splitter_axilite.tcl
read_verilog -quiet -sv demux_control.sv
# source ila_0_p4.tcl

source p4/vitis_net_p4_0_register.tcl
read_verilog -quiet -sv p4_hdr_register.sv
read_verilog -quiet -sv stream_switch_dfx.sv

if {!$pr} {
    source pkt_size_counter/build_rm.tcl
}