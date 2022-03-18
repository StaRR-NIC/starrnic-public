set cur_dir [pwd]
cd pkt_size_counter

set this_rm_name pkt_size_counter

update_compile_order -fileset sources_1
create_reconfig_module -name $this_rm_name -partition_def [get_partition_defs $partition_name ]

add_files -norecurse -scan_for_includes axi_stream_size_counter_rm_counter.sv axi_lite_register_rm_counter.sv pkt_size_counter.sv -of_objects [get_reconfig_modules $this_rm_name]
update_compile_order -fileset $this_rm_name

copy_ip -name axi_lite_clock_converter_rm_counter -dir ${build_dir}/vivado_ip [get_ips  axi_lite_clock_converter]
update_compile_order -fileset sources_1
set_property generate_synth_checkpoint false [get_files  ${build_dir}/vivado_ip/axi_lite_clock_converter_rm_counter/axi_lite_clock_converter_rm_counter.xci]
move_files -of_objects [get_reconfig_modules $this_rm_name] [get_files  ${build_dir}/vivado_ip/axi_lite_clock_converter_rm_counter/axi_lite_clock_converter_rm_counter.xci]
update_compile_order -fileset $this_rm_name

copy_ip -name axi_stream_pipeline_rm_counter -dir ${build_dir}/vivado_ip [get_ips  axi_stream_pipeline]
update_compile_order -fileset sources_1
set_property generate_synth_checkpoint false [get_files  ${build_dir}/vivado_ip/axi_stream_pipeline_rm_counter/axi_stream_pipeline_rm_counter.xci]
move_files -of_objects [get_reconfig_modules $this_rm_name] [get_files  ${build_dir}/vivado_ip/axi_stream_pipeline_rm_counter/axi_stream_pipeline_rm_counter.xci]
update_compile_order -fileset $this_rm_name

create_pr_configuration -name config_counter -partitions [list box_250mhz_inst/stream_switch_dfx_inst/${rm_inst_name}:$this_rm_name ]
set_property PR_CONFIGURATION config_counter [get_runs impl_1]
lappend pr_impl_runs "impl_1"

cd $cur_dir

# # Old non working flow. Works in tcl console GUI, but not in batch mode.
# # Assumes
# #   1. `build_rm.tcl` is already loaded for this RM.
# #   2. This is the first RM of the parition.

# set this_rm_name pkt_size_counter

# update_compile_order -fileset sources_1
# create_partition_def -name $partition_name -module $rm_intf_name
# # ^^ I think without updating compile order Vivado does not remove the RM module from hierarchy
# puts "Creating RM name $this_rm_name for partition $partition_name from interface $rm_intf_name"
# create_reconfig_module -name $this_rm_name -partition_def [get_partition_defs $partition_name ]  -define_from $rm_intf_name

# # Use this set_property syntax if module is already moved to the reconfigurable module fileset
# set_property generate_synth_checkpoint false [get_files -of_objects [get_reconfig_modules $this_rm_name] ${build_dir}/vivado_ip/axi_lite_clock_converter_rm_counter/axi_lite_clock_converter_rm_counter.xci]
# set_property generate_synth_checkpoint false [get_files -of_objects [get_reconfig_modules $this_rm_name] ${build_dir}/vivado_ip/axi_stream_pipeline_rm_counter/axi_stream_pipeline_rm_counter.xci]

# create_pr_configuration -name config_counter -partitions [list box_250mhz_inst/stream_switch_dfx_inst/${rm_inst_name}:$this_rm_name ]
# set_property PR_CONFIGURATION config_counter [get_runs impl_1]
# lappend pr_impl_runs "impl_1"
