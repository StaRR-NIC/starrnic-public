create_pblock pblock_rm_filler_inst
add_cells_to_pblock [get_pblocks pblock_rm_filler_inst] [get_cells -quiet [list box_250mhz_inst/stream_switch_dfx_inst/rm_filler_inst]]
resize_pblock [get_pblocks pblock_rm_filler_inst] -add {CLOCKREGION_X1Y5:CLOCKREGION_X2Y6}
set_property SNAPPING_MODE ON [get_pblocks pblock_rm_filler_inst]
