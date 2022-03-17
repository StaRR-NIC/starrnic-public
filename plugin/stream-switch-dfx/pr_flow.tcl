set_property PR_FLOW 1 [current_project]

set partition_name partition1
set rm_intf_name ${partition_name}_rm_intf
# Above should be the name of all the reconfigurable modules.
set rm_inst_name ${rm_intf_name}_inst

source pkt_size_counter/build_rm_pr.tcl
source pkt_size_counter5/build_rm_pr.tcl

# Read pblock constraints