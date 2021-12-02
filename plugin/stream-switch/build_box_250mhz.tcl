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
read_verilog -quiet -sv byte_counter_250mhz.sv

source stream_switch_axi_crossbar.tcl
read_verilog -quiet stream_switch_address_map_inst.vh
read_verilog -quiet stream_switch_address_map.v

# source stream_switch_axis_switch_combiner_axilite.tcl
source stream_switch_axis_switch_combiner_tdest.tcl
source stream_switch_axis_switch_splitter_axilite.tcl

read_verilog -quiet -sv stream_switch_250mhz.sv
