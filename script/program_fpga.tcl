open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
current_hw_device [get_hw_devices xcu50_u55n_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xcu50_u55n_0] 0]
set_property PROBES.FILE {} [get_hw_devices xcu50_u55n_0]
set_property FULL_PROBES.FILE {} [get_hw_devices xcu50_u55n_0]
set_property PROGRAM.FILE {/home/ubuntu/Projects/StaRR-NIC/hw-open-nic-shell/build/au50/open_nic_shell/open_nic_shell.runs/impl_1/open_nic_shell.bit} [get_hw_devices xcu50_u55n_0]
program_hw_devices [get_hw_devices xcu50_u55n_0]
refresh_hw_device [lindex [get_hw_devices xcu50_u55n_0] 0]
exit