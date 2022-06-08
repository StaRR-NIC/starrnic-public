set cur_dir [pwd]
cd pkt_size_counter
update_compile_order -fileset sources_1

# We need to copy these IPs because they differ in their names.
# TODO:(108anup) copy to project folder instaed of manage ip project folder. Otherwise idempotency lost.
copy_ip -name axi_lite_clock_converter_rm_counter -dir ${build_dir}/vivado_ip [get_ips  axi_lite_clock_converter]
update_compile_order -fileset sources_1

copy_ip -name axi_stream_pipeline_rm_counter -dir ${build_dir}/vivado_ip [get_ips  axi_stream_pipeline]
update_compile_order -fileset sources_1

read_verilog -quiet -sv axi_lite_register_rm_counter.sv
read_verilog -quiet -sv axi_stream_size_counter_rm_counter.sv
read_verilog -quiet -sv pkt_size_counter.sv
update_compile_order -fileset sources_1
cd $cur_dir