set_property PR_FLOW 1 [current_project]

set partition_name partition1
set rm_intf_name ${partition_name}_rm_intf
# Above should be the name of all the reconfigurable modules.
set rm_inst_name ${rm_intf_name}_inst

source pkt_size_counter/build_rm_pr.tcl
source pkt_size_counter5/build_rm_pr.tcl

# Read floorplan pblock constraints
if {[file exists floorplanning/${board}/floorplan.xdc]} {
    read_xdc -unmanaged floorplanning/${board}/floorplan.xdc
} else {
    puts "Searched for constraints at path: [pwd]/floorplanning/${board}/floorplan.xdc"
    puts "No floorplanning constraints found. Can't implement without floorplan!"
}