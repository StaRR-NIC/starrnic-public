create_pblock pblock_partition1_rm_intf_inst
add_cells_to_pblock [get_pblocks pblock_partition1_rm_intf_inst] [get_cells -quiet [list box_250mhz_inst/stream_switch_dfx_inst/partition1_rm_intf_inst]]
resize_pblock [get_pblocks pblock_partition1_rm_intf_inst] -add {CLOCKREGION_X2Y4:CLOCKREGION_X5Y7}
set_property SNAPPING_MODE ON [get_pblocks pblock_partition1_rm_intf_inst]
