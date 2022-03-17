# Assumes 
#   1. `build_rm.tcl` is already loaded for this RM.
#   2. This is the first RM of the parition.

set this_rm_name pkt_size_counter

create_partition_def -name $partition_name -module $rm_intf_name
create_reconfig_module -name $this_rm_name -partition_def [get_partition_defs $partition_name ]  -define_from $rm_intf_name

set_property generate_synth_checkpoint false [get_files -of_objects [get_reconfig_modules $this_rm_name] ${build_dir}/vivado_ip/axi_lite_clock_converter_rm_counter/axi_lite_clock_converter_rm_counter.xci]
set_property generate_synth_checkpoint false [get_files -of_objects [get_reconfig_modules $this_rm_name] ${build_dir}/vivado_ip/axi_stream_pipeline_rm_counter/axi_stream_pipeline_rm_counter.xci]

create_pr_configuration -name config_counter -partitions [list box_250mhz_inst/stream_switch_dfx_inst/${rm_inst_name}:$this_rm_name ]
set_property PR_CONFIGURATION config_counter [get_runs impl_1]
lappend pr_impl_runs "impl_1"