set cur_dir [pwd]
cd pkt_size_counter5
set this_rm_name pkt_size_counter5
create_reconfig_module -name $this_rm_name -partition_def [get_partition_defs $partition_name ]

read_verilog -quiet -sv axi_lite_register_rm_counter5.sv
read_verilog -quiet -sv axi_stream_size_counter_rm_counter5.sv
read_verilog -quiet -sv pkt_size_counter5.sv

copy_ip -name axi_lite_clock_converter_rm_counter5 -dir ${build_dir}/vivado_ip [get_ips  axi_lite_clock_converter]
update_compile_order -fileset sources_1
set_property generate_synth_checkpoint false [get_files  ${build_dir}/vivado_ip/axi_lite_clock_converter_rm_counter5/axi_lite_clock_converter_rm_counter5.xci]
move_files -of_objects [get_reconfig_modules $this_rm_name] [get_files  ${build_dir}/vivado_ip/axi_lite_clock_converter_rm_counter5/axi_lite_clock_converter_rm_counter5.xci]
update_compile_order -fileset $this_rm_name

copy_ip -name axi_stream_pipeline_rm_counter5 -dir ${build_dir}/vivado_ip [get_ips  axi_stream_pipeline]
update_compile_order -fileset sources_1
set_property generate_synth_checkpoint false [get_files  ${build_dir}/vivado_ip/axi_stream_pipeline_rm_counter5/axi_stream_pipeline_rm_counter5.xci]
move_files -of_objects [get_reconfig_modules $this_rm_name] [get_files  ${build_dir}/vivado_ip/axi_stream_pipeline_rm_counter5/axi_stream_pipeline_rm_counter5.xci]
update_compile_order -fileset $this_rm_name


create_pr_configuration -name config_counter5 -partitions [list box_250mhz_inst/stream_switch_dfx_inst/${rm_inst_name}:$this_rm_name ]
# Check if this is correct...
create_run child_0_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2021} -pr_config config_counter5
cd $cur_dir