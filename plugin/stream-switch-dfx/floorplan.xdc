create_pblock {pblock_gnblk1[0].rm_flr_inst}
add_cells_to_pblock [get_pblocks {pblock_gnblk1[0].rm_flr_inst}] [get_cells -quiet [list {box_250mhz_inst/stream_switch_dfx_inst/genblk1[0].rm_filler_inst}]]
resize_pblock [get_pblocks {pblock_gnblk1[0].rm_flr_inst}] -add {CLOCKREGION_X1Y5:CLOCKREGION_X2Y6}
set_property SNAPPING_MODE ON [get_pblocks {pblock_gnblk1[0].rm_flr_inst}]
