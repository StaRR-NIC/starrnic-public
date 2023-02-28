# StaRR-NIC

We explore FPGA partial reconfiguration primitives to build runtime reconfigurable FPGA NICs.  
This code accompanies the technical report:

<b>CMU technical report number: CMU-CS-23-100  
Title: StaRRNIC: Enabling Runtime Reconfigurable FPGA NICs  
Authors: Anup Agarwal (Carnegie Mellon University), Daehyeok Kim (University of Texas at Austin), Srinivasan Seshan (Carnegie Mellon University)</b>

The technical report is to be released (expected March 2023).

This is a work in progress. For any questions/concerns/feedback, please email anupa@andrew.cmu.edu.

## Scope
This code serves as a reference on how to perform a partial reconfiguration (PR) operation on an FPGA to go from one packet processing application to another, while the FPGA is serving packets at line rate all along. During the PR operation, packets are diverted away from the old application, then a new application is programmed and lastly, the traffic is divereted to the new application. For a brief period, the packets are not processed by any application. This shows the <i>loss of functionality</i> tradeoff.

During the PR operation, one can also tradeoff <i>performance</i> (e.g., by reconfiguring one replica of an application at a time), or tradeoff <i>resources</i> (e.g., by having both old and new applications running for a brief period of time).

Depending on the application you put in the reconfigurable region of the FPGA, you may need to change the floorplan or use more aggresive placement/route options with compiler to meet timing. (https://www.xilinx.com/content/dam/xilinx/support/documents/sw_manuals/xilinx2022_2/ug909-vivado-partial-reconfiguration.pdf).

## Code Structure:

- `plugin/stream-switch-dfx` has the main logic that allows zero downtime runtime reconfiguration.
- `scripts/` has scripts we use to tell the xilinx toolchain to copmile the design for partial reconfiguration. It also has scripts for reconfiguring the FPGA design (loading partial bitstreams) at runtime.
- `reference-scripts/` reference scripts for setting up toolchain and environment variables.

## Setup
Note, some scripts we use may have hardcoded paths to installed tools/files.
We provide the paths where we install such tools/files.

- Hardware setup
  - Physically install an FPGA supported by Open-NIC (https://github.com/Xilinx/open-nic).
  - Install FPGA driver and update firmware (follow your FPGA board's data sheet and user guide, e.g., we used (https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#gettingStarted).
    - We install these at `/opt`.
  - Obtain board files for your FPGA (from https://www.xilinx.com/member/alveo-vivado.html#u280).
    - We install these at `/datadrive/board-files`.
  - Clone and compile open-nic-driver (follow open-nic-driver README, https://github.com/Xilinx/open-nic-driver).
  - Clone pcimem (follow pcimem README https://github.com/billfarrow/pcimem).
- Build setup
  - Install Vivado 2021.1 (for open-nic-shell), Vitis 2021.1 (if also using VitisP4Net, i.e., Xilinx's P4 toolchain).
    - We install them at `/tools/Xilinx`.
    - Vivado requires a license (obtain from Xilinx).
    - The P4 toolchain also requires a license (obtain from Xilinx).
- Simulation setup (We use Mentor modelsim with cocotb for Xilinx IPs and custom sources using Xilinx simulation library and custom flow with cocotb)
  - Install modelsim.
    - This requires a license. Our academic institution provided this. We installed it at `/opt`.
  - Install cocotb and required sub-packages (cocotb-axi, cocotb-eth, etc.) (from https://github.com/corundum/corundum/wiki/Getting-Started).
    - `pip install cocotb cocotb-bus cocotb-test cocotbext-axi cocotbext-eth cocotbext-pcie pytest scapy`
    - `pip install tox pytest-xdist pytest-sugar`
- At some places we refer to some environment variables (`exec reference-scripts/sample_env_setup.sh`), please find their reference values here:
  ```
  export PCIMEM_PATH="$HOME/opt/pcimem"
  export PCIMEM="$PCIMEM_PATH/pcimem"
  export STARRNIC_SHELL="$HOME/Projects/StaRR-NIC/starrnic-public"
  export EXTENDED_DEVICE_BDF1="0000:86:00.0"
  export EXTENDED_DEVICE_BDF2="0000:86:00.1"
  export STARRNIC_IP1="10.0.0.55"
  export STARRNIC_IP2="10.0.0.53"
  export STARRNIC_IFACE1=enp134s0f0
  export STARRNIC_IFACE2=enp134s0f1
  ```

## Build
- Ensure modelsim and vitis are in path and their settings are loaded, e.g., `exec scripts/sample_toolchain_setup.sh`.
- For hardware (bitstream generation)
  ```
  cd $STARRNIC_SHELL/script
  vivado -mode tcl -source ./build.tcl -tclargs \
  -board_repo /datadrive/board-files -board au280 \
  -impl 1 -post_impl 1 -user_plugin ../plugin/stream-switch-dfx \
  -tag <any tag you want to add> -pr 1

  # The -pr flag denotes whether the design should support partial reconfiguration (PR) or not.
  # Setting -pr 0 allows testing/debugging the static FPGA design.
  # Setting -pr 1 enables PR.

  # This will create bitstream in (if there were no errors)
  $STARRNIC_SHELL/build/au280_<tag>/open_nic_shell/open_nic_shell.runs/impl_1/open_nic_shell.bit
  # Check runme.log for errors in the directory for the run that failed.
  ```
- For simulation (generating simulation sources and dependencies for module)
  - E.g. for `stream_switch_dfx` module (this can also be used for any verilog modules that are instantiated within the `stream_switch_dfx` hierarchy):
    ```
    cd script

    vivado -mode tcl -source ./build.tcl -tclargs \
    -board_repo /datadrive/board-files -board au280 \
    -user_plugin ../plugin/stream-switch-dfx \
    -sim 1 -sim_lib_path $HOME/opt/xilinx_sim_libs/Vivado2020.2/compile_simlib \
    -sim_path $HOME/opt/modelsim/modelsim-se_2020.1/modeltech/linux_x86_64 \
    -sim_top stream_switch_dfx -pr 0
    ```
  - <b>Ensure that that partial reconfiguration is disabled when building for simulation. </b>
  - `sim_lib_path` specifies libraries used by Xilinx IPs. If the directory pointed by `sim_lib_path` is empty, the build script will compile and install the sim libraries. (this is one time and can take ~hours). These libraries can be used across Xilinx projects.
  - `sim_path` is path to modelsim installation
  - This command will create simulation sources in `build/au280_<tag>/open_nic_shell/open_nic_shell.sim/sim_1/behav/modelsim` and can be used to simulate any module instantiated within `sim_top`.

## Running on hardware
- Program the FPGA (use `$STARRNIC_SHELL/script/program_fpga.sh`)
  ```
  EXTENDED_DEVICE_BDF1=0000:86:00.0 EXTENDED_DEVICE_BDF2=0000:86:00.1 ./script/program_fpga.sh ./build/au280_<tag>/open_nic_shell/open_nic_shell.runs/impl_1/open_nic_shell.bit au280
  ```
  The first time you program, you also need to warm reboot the machine as the FPGA pcie device changes from an accelerator to a memory controller. You do not need to warm reboot if you already have a open nic design running on the FPGA.
- Configure the NIC
  - If using `stream_switch_dfx` plugin, then run/refer:
    ```
    ./script/configure_stream_switch_demux.sh
    # This script configures the on FPGA interconnect and also configures the netdev interfaces.
    ```
  - For other plugins:
    - Install `open-nic-driver`
      ```
      # From open-nic-driver root
      sudo insmod onic.ko
      ```
    - Set ip and bring FPGA dev if up
      ```
      sudo ifconfig $STARRNIC_IFACE1 $STARRNIC_IP1/24 up
      ```
- Test by pinging
  ```
  ping 10.0.0.61
  ```
- Read packet size counter in hex (for `stream_switch_dfx`)
  ```
  sudo $PCIMEM /sys/bus/pci/devices/$EXTENDED_DEVICE_BDF1/resource2 0x140000
  ```

## Running simulation
```
cd $STARRNIC_SHELL/build/au280_<tag>/open_nic_shell/open_nic_shell.sim/sim_1/behav/modelsim
# Copy over common scripts used by all tests (one time)
ln -s $STARRNIC_SHELL/tb/script/* ./

# Copy over scripts used by specific test
ln -s $STARRNIC_SHELL/tb/<module-to-test>/* ./
## E.g. for stream_switch_dfx
ln -s $STARRNIC_SHELL/tb/stream_switch_dfx/* ./

# Compile the simulation files using modelsim
./compile.sh # (autogenerated during building step by vivado)

# Run the simulation
DUT=<module-to-test> GUI=0 DEBUG=0 ./run.sh
## E.g.,
DUT=stream_switch_dfx GUI=0 DEBUG=0 ./run.sh
## Set GUI=1 to see waveform
```

## Stream-switch-dfx plugin overview
This is a plugin that fits in the user logic box of the Open NIC shell. In this plugin we instantiate an interconnect and some packet processing modules (applications). The interconnect allows us to control how traffic is diverted to different applications. In the basic benchmarking workflow, we have a single region that holds the applications and the interconnect either sends traffic to the application or bypasses the application. To perform the reconfiguration operation, we bypass the application. Then we upload the new partial bitstream that reprograms the application area. Lastly, we start diverting traffic back to the application area. In this process there is no loss in throughput and there is no packet loss. There may be a minor bump in latency when the interconnect is reprogrammed.

## Performing partial reconfiguration
- Follow "build" instructions to build the stream-switch-dfx plugin.
- Follow "running on hardware" instructions to program the FPGA and configure the interconnect.
- `sudo ifconfig $STARRNIC_IFACE1 down`. We use U280 board with 2 QSFP ports. Our benchmarking setup consists of a U280 board connected to a traffic generator and receiver. The traffic generator sends packets on the QSFP port 0, the FPGA fowards these packets to QSFP port 1, these are then received by the reciever. The generator and reciever share the same hardware clock allowing us to measure latency and the packets never cross the PCIe interface on the U280 allowing us to avoid PCIe bottlenecks in the microbenchmarking process. Hence, we disable the netdec interfaces.
- When you build with `-pr 1`, there will be multiple partial bitstreams in the build directory, one in each implementation run (e.g., `impl_1`, `child_0_impl_1` in `$STARRNIC_SHELL/build/au280/open_nic_shell/open_nic_shell.runs/`).
- `$STARRNIC_SHELL/scripts/setup_p4_reg.sh`. This configures updates on packet headers. In our benchmarking design, packets are forwarded from QSFP0 to QSFP1, our traffic generator expectes a UDP socket between the sender and receiver. We use a Xilinx P4 module to manupulate packet headers emulate the UDP socket (this basically involves swapping the MAC, IP and port numbers). Depending on how you use our code, what licenses you have, and what your traffic generator expects, you may want to modify this module and its configuration.
- Use the `replace_pr.sh` script to reconfigure the FPGA.
  ```
  $STARRNIC_SHELL/scripts/replace_pr.sh $STARRNIC_SHELL/build/au280/open_nic_shell/open_nic_shell.runs/impl_1/box_250mhz_inst_stream_switch_dfx_inst_partition1_rm_intf_inst_pkt_size_counter_partial.bit au280
  ```
  This script manages the configuration of the interconnect as well as the reconfigurable regions on the FPGA.
---
---

Below is a copy of the documentation provided by Xilinx AMD for OpenNIC Shell.

# OpenNIC Shell

OpenNIC shell delivers an FPGA-based NIC shell with 100Gbps Ethernet ports.  The
latest version is built with Vivado 2020.2.  Currently, the supported boards
include

- Xilinx Alveo U50, and
- Xilinx Alveo U200, and
- Xilinx Alveo U250, and
- Xilinx Alveo U280

Starting from OpenNIC 1.0, the support for Bittware SoC-250 is obsolete and no
longer maintained.

The NIC shell consists of skeleton components which implement host and Ethernet
interfaces and two user logic boxes that wraps up user RTL plugins.  Its
architecture is shown in the figure below.

    -----  -----------------------------------------------
    |   |  |            System Configuration             | 
    |   |  -----------------------------------------------
    |   |     |         |         |         |         |  AXI-lite 125MHz
    |   |     V         V         V         V         V
    |   |  -------   -------   -------   -------   -------
    |   |  |     |   |     |   |     |   |     |   |     |
    | P |  |  Q  |==>| Box |==>|  A  |==>| Box |==>|  C  |
    | C |  |  D  |   |  @  |   |  D  |   |  @  |   |  M  |
    | I |  |  M  |   | 250 |   |  A  |   | 322 |   |  A  |
    | E |  |  A  |<==| MHz |<==|  P  |<==| MHz |<==|  C  |
    |   |  |     | | |     | | |     | | |     | | |     |
    -----  ------- | ------- | ------- | ------- | -------
                   |         |         |         |
                   -----------         -----------
                 AXI-stream 250MHz   AXI-stream 322MHz

The shell skeleton has the following components.

- QDMA subsystem.  It includes the Xilinx QDMA IP and RTL logic that bridges the
  QDMA IP interface and the 250MHz user logic box.  The interfaces between QDMA
  subsystem and the 250MHz box use a variant of the AXI4-stream protocol.  Let
  us refer the variant as the 250MHz AXI-stream.
- CMAC subsystem.  It includes the Xilinx CMAC IP and some wrapper logic.
  OpenNIC shell supports either 1 or 2 CMAC ports.  In the case of 2 CMAC ports,
  there are two instances of CMAC subsystems with dedicated data and control
  interfaces.  The CMAC subsystem runs at 322MHz and connects to the 322MHz user
  logic box using a variant of the AXI4-stream protocol.  Similarly, let us
  refer the variant as the 322MHz AXI-stream.
- Packet adapter.  It is used to convert between the 250MHz AXI-stream and
  322MHz AXI-stream.  On both TX and RX paths, the packet adapter serves as a
  packet-mode FIFO, which buffers the whole packet before sending out.  On the
  RX path, it also restores the back-pressure capability which is missing from
  the CMAC subsystem interface.
- System configuration.  It implements a reset mechanism and allocates the
  register addresses for each components.  The register interface uses AXI4-lite
  protocol and runs at 125MHz, which is phase-aligned with the 25MHz clock.

There are 2 user logic boxes, one running at 250MHz and the other at 322MHz.
Each has a AXI-lite interface for register, 2 pairs of slave and master
AXI-stream interfaces for TX and RX respectively.  User RTL plugins are
responsible for implementing the handling of these interfaces.

## Repo Structure

The `open-nic-shell` repository is organized as follows.

    |-- open-nic-shell --
        |-- constr --
            |-- au50 --
            |-- au200 --
            |-- au250 --
            |-- au280 --
            |-- ... --
        |-- plugin --
            |-- p2p --
        |-- script --
            |-- board_settings --
            |-- build.tcl
            |-- ...
        |-- src --
            |-- box_250mhz --
            |-- box_322mhz --
            |-- cmac_subsystem --
            |-- packet_adapter --
            |-- qdma_subsystem --
            |-- system_config --
            |-- utility --
            |-- open_nic_shell.sv
            |-- ...
        |-- LICENSE.txt
        |-- README.md
        |-- ...

Most of the directories are self-explanatory.  The code under `src` contains the
skeleton components and the "empty" boxes.  Sample plugins are available under
the `plugin` directory.

## How to Build

OpenNIC shell is built by running the Tcl script `build.tcl` under `script` in
Vivado.  Depending on the target device, the build script generates proper files
for flash programming.

It is recommended to build the design with Internet connection, as it relies on
updated Xilinx board files, accessible through [Xilinx Board
Store](https://github.com/Xilinx/XilinxBoardStore).  The build script
automatically updates Vivado against this repository.  See the below section for
build without Internet/Github access.

### Build Script Options

To start building the shell, run the following command under `script` with a
proper `MODE` choice (i.e., `tcl`, `batch` or `gui`).

    vivado -mode MODE -source build.tcl -tclargs [-OPTION VALUE] ...

A list of options are available to configure the the build process and customize
the design parameters.

    # Build options

    -board_repo  PATH
                 path to local Xilinx board store repository for offline build.
                 This option is used when Vivado is unable to connect to github
                 and update the board repository.

    -board       BOARD_NAME
                 supported boards include:
                 - au250, and
                 - au280, and
                 - au50.

    -tag         DESIGN_TAG
                 string to identify the build.  The tag, along with the board
                 name, becomes part of the build directory name.

    -overwrite   0 (default), 1
                 indicate if the script should overwrite existing build results.

    -jobs        [1, 32] (default to 8)
                 number of jobs for synthesis and implementation.

    -synth_ip    0, 1 (default)
                 indicate if IPs are out-of-box synthesized after creation.

    -impl        0 (default), 1
                 indicate if the script runs towards bitstream generation.  If
                 set to 0, the script only creates the project and do not launch
                 any run.

    -post_impl   0 (default), 1
                 indicate if MCS file is generated after bitstream generations.

    -user_plugin PATH
                 path to the user plugin repository.

    # Design parameters

    -build_timestamp VALUE
                     VALUE should be an 8-digit hexdecimal value without prefix.
                     It serves as the timestamp to identify the build and is
                     written into the shell register 0x0.  If not specified, the
                     date and time of the build is recorded using the format
                     MMDDhhmm, where MM is for month, DD for day, hh for hour
                     and mm for minute.

    -min_pkt_len     [64, 256] (default to 64)
                     minimum packet length.

    -max_pkt_len     [256, 9600] (default to 1514)
                     maximum packet length.

    -use_phys_func   0, 1 (default)
                     indicates if the QDMA H2C and C2H AXI-stream interfaces are
                     included in the 250MHz user logic box.  A common scenario
                     for not using them is networking accelerators without DMA.
                     Regardless the value of this option, the QDMA IP is always
                     present in the shell since it also provide the AXI-lite
                     interfaces for register access.

    -num_phys_func   [1, 4] (default to 1)
                     number of QDMA physical functions.

    -num_queue       [1, 2048] (default to 512)
                     number of QDMA queues.

    -num_cmac_port   1 (default), 2
                     number of CMAC ports, subjects to the board model.

### Build Process

The build process involves four steps.

1. IP creation and optionally, out-of-box synthesis.
2. Design project setup.
3. Synthesis, implementation and bitstream generation.
4. Post-processing.

By default, the script completes the first two steps, producing a Vivado project
under the build directory.  This can be customized using the `-synth_ip`,
`-impl` and `-post_impl` options.

- If `-synth_ip` is set to 0, the IP out-of-box synthesis is deferred.
- If `-impl` is set to 1, the third step is performed.
- If `-post_impl` is set 1, the post-processing step is performed after
  bitstream generation.

The build directory is located under `build` and named as `[BOARD]_[TAG]`.
Under the build directory, there is a text file, `DESIGN_PARAMETERS`, which
contains the parameters passed to the RTL top-level.  All the IP files are
stored under `vivado_ip`.  The shell project is under `open_nic_shell`.

The following Verilog macros are defined and made available to the RTL source
code.

- The `__synthesis__` macro.
- Board name, either `__au250__`, `__au280__` or `__au50__`.

### Build without Github Access from Vivado

If Vivado does not have access to Github, we need to have a local copy of the
[Xilinx Board Store](https://github.com/Xilinx/XilinxBoardStore) repository, and
pass the path to the build script via the `-board_repo` option.

## User Plugin Integration

OpenNIC shell provides 2 user logic boxes for instantiating custom RTL logic,
one running at 250MHz and the other at 322MHz.  To build with custom plugins,
pass the path of the plugin repository to the `-user_plugin` argument of the
build script.  Default plugins are available for both boxes under
`plugin/p2p/box_250mhz` and `plugin/p2p/box_322mhz` respectively, which does
simple port-to-port connection.  If users are interested in only one box, they
should instantiate the default plugin in the other one.

Each box requires a top-level wrapper for all the user plugins instantiated in
that box.  In other words, only one module should be instantiated in each box.
There are a few rules on how to structure the `-user_plugin`.  At a minimum
level, it should look like the following.

    |-- USER_PLUGIN_DIR --
        |-- box_250mhz --
            |-- user_plugin_250mhz_inst.vh
            |-- box_250mhz_address_map_inst.vh
            |-- box_250mhz_address_map.v
            |-- box_250mhz_axi_crossbar.tcl
        |-- box_322mhz --
            |-- user_plugin_322mhz_inst.vh
            |-- box_322mhz_address_map_inst.vh
            |-- box_322mhz_address_map.v
            |-- box_322mhz_axi_crossbar.tcl
        |-- ... --
        |-- build_box_250mhz.tcl
        |-- build_box_322mhz.tcl
        |-- ...

The files under `box_250mhz` and `box_322mhz` are glue code that connects the
user plugins to OpenNIC shell.

- `user_plugin_XXXmhz_inst.vh` is a Verilog header file that instantiates the
  top-level wrapper.  It is included into `src/box_XXXmhz/box_XXXmhz.sv`.
- `box_XXXmhz_address_map_inst.vh` is a Verilog header file that instantiates
  the `box_XXXmhz_address_map` module.  It is included into
  `src/box_XXXmhz/box_XXXmhz.sv`.
- `box_XXXmhz_address_map.v` implements the register address mapping in
  `box_XXXmhz`.
- `box_XXXmhz_axi_crossbar.tcl` creates the AXI crossbar IP instantiated in
  `box_XXXmhz_address_map.v`.

Currently, these files need to be created and modified manually.  In the next
release, they will be auto-generated through a configuration file.

For each box, the build script performs the following steps.

1. Source `box_XXXmhz_axi_crossbar.tcl`.
2. Read `box_XXXmhz_address_map.v`.
3. Add `USER_PLUGIN_DIR/box_XXXmhz` to the `include_dirs` property.
4. Source `build_box_XXXmhz.tcl`.

To use the default plugin (i.e., `plugin/ptp`) in one of the boxes, remove the
corresponding `box_XXXmhz` directory and `build_box_XXXmhz.tcl`.

## Shell Interface

Shell and user logic boxes communicates through 3 types of interfaces.

- AXI-lite interface running at 125MHz for register access.
- AXI-stream interface running at either 250MHz or 322MHz for data path.
- Synchronous reset interface running at 125MHz.

The 125MHz and 250MHz clock domains are phase aligned.  Signals can be sampled
across each domain without clock domain crossing.  On the other hand, do note
that different clock frequencies can lead to double sampling or missing samples.

The AXI-lite interface follows the standard AXI4-lite protocol without `wstrb`,
`awprot` and `arprot`.  At the system level, the address ranges for the 2 boxes
are

- 0x10000 - 0x3FFFF for the 322MHz box, and
- 0x40000 - 0xFFFFF for the 250MHz box.

The 250MHz and 322MHz AXI-stream interfaces have slightly different semantics.
The 250MHz interface has the following signals.

- `tvalid`, 1 bit: same as standard AXI4-stream protocol.
- `tdata`, 512 bits: data maps from lower to upper bytes.
- `tkeep`, 64 bits: null bytes are only allowed when both `tvalid` and `tlast`
  are asserted and cannot be followed by other data bytes for the same packet.
  For example, a 96B packet has a `tkeep` value of 0xFFFFFFFFFFFFFFFF in the
  first beat, and 0x00000000FFFFFFFF in the second beat.
- `tlast`, 1 bit: same as standard AXI4-stream protocol.
- `tuser_size`, 16 bits: field to specify packet size.  It contains the number
  of bytes in the packet and must remain valid and unchanged if `tvalid` is
  asserted.
- `tuser_src`, 16 bits: source of the packet.
- `tuser_dst`, 16 bits: destination of the packet.
- `tuser_user`, N bits: side-band user data.
- `tready`, 1 bit: same as standard AXI4-stream protocol.

For the `tkeep` signal, the interface assumes its presence depending on the
direction of a packet.

- For packets exiting the shell, it is guaranteed that `tkeep` is consistent
  with `tuser_size`.  This means that `tkeep` consists of all 1s when `tvalid`
  is asserted and `tlast` is de-asserted and shows a bit-mask for the valid
  bytes in the beat when both `tvalid` and `tlast` are asserted.
- For packets entering the shell, `tkeep` can be optionally set to all 1s
  regardless of the value of `tuser_size`.  This allows user plugins to drop
  `tkeep` in their implementation.  If `tkeep` is not set to all 1s, it must be
  consistent with `tuser_size`.
  
For `tuser_src` and `tuser_dst`, they have the following format.  For packets
exiting the shell, `tuser_src` is marked accordingly and `tuser_dst` is all 0s.

    ----------------------------------------------------
    | 15                         6 |    4 |          0 |
    |------------------------------|------|------------|
    | P  P  P  P  P  P  P  P  P  P | R  R | F  F  F  F |
    |------------------------------|------|------------|
    |            MAC ports         | Rsvd |  PCIe PFs  |
    ----------------------------------------------------

The 322MHz interface is more restrictive due to requirements from CMAC IP.  It
has the following signals.

- `tvalid`, 1 bit: no de-assertion in the middle of a packet.  In other words,
  once `tvalid` is asserted to indicate the start of packet, it must remain
  asserted until `tlast`.
- `tdata`, 512 bits: same as in the 250MHz interface.
- `tkeep`, 64 bits: same as in the 250MHz interface.
- `tlast`, 1 bit: same as in the 250MHz interface.
- `tuser_err`, 1 bit: indicates if the packet contains an error.
- `tready`, 1 bit: same as in the 250MHz interface.  But packets entering the
  shell, i.e., from the RX side of CMAC IPs, the `tready` signal is not present
  and the master side assumes that `tready` is always asserted.

## Programming FPGA

After bitstream generation, FPGA can be programming in two ways.

1. Program the device directly.  The FPGA configuration will lose after reboot.
2. Program and boot from the configuration memory.

Because the shell bitstream contains a PCI-e IP core, both approaches will cause
the lost of PCI-e link.  It could be fatal depending on the model of host
motherboards.  For example, for Dell servers, losing discovered PCI-e links
could lead to a forced reboot triggered by iDRAC.

To avoid this, use the Bash script `script/setup_device.sh`, which disables the
reporting of fatal errors to PCI-e root complex before programming and triggers
a PCI-e link re-scan after programming.  The script takes the device BDF (i.e.,
`BB:DD.FF` without the domain, which usually is `0000`) as the single input, and
should be ran on the server with the FPGA card.

There are two limitations related to the script.  First, if an FPGA is not yet
programmed with a PCI-e enabled bitstream, it would not have an BDF address.  In
this case, the script does not work.  The second case is when OpenNIC driver is
already loaded, it can hang the kernel after the script issues link re-scan.
This issue is planned to be addressed in the future driver release.

For the above two cases, the safest workaround is to use a different server to
program the FPGA.  For configuration memory programming, do a cold reboot to
trigger the FPGA boot process.

## Known Issues

### Server Boot Failure after FPGA Programming

A warm reboot is needed after loading the bitstream onto the FPGA.  But this
reboot fails with the error message: 

    A PCIe link training failure is observed in Slot1 and the link is disabled.

For Dell servers, there is a temporary hack [discussed
here](https://forums.xilinx.com/t5/PCIe-and-CPM/PCIE-link-training-error-on-DELL-R730/m-p/806428).
The trick is to issue a second warm reboot command using iDRAC while the system
is rebooting and before PCIe endpoint detection.  The hypothesis is that this
gives enough time to load the configuration on the FPGA.  This seems to be
working so far.

### CMAC license

Some users have reported this error when trying to build the shell.

    ERROR: [Common 17-69] Command failed: This design contains one or more cells
    for which bitstream generation is not permitted:
    `cmac_subsystem_inst/cmac_wrapper_inst/cmac_inst/inst/i_cmac_usplus_0_top
    (<encrypted cellview>)`.  If a new IP Core license was added, in order for
    the new license to be picked up, the current netlist needs to be updated by
    resetting and re-generating the IP output products before bitstream
    generation.

Since CMAC is hardened in Ultrascale+, `cmac_usplus` has a free license.  To get
the CMAC license, go to [www.xilinx.com/getlicense](www.xilinx.com/getlicense).
After login, click "Search Now" in the "Evaluation and No Charge Cores" box on
the right side of the page.  You will see a popup with a "Search" box at top
left.  Enter "100G" in the search box.  You will see "UltraScale+ Integrated
100G Ethernet No Charge License".  Select this and click "Add".  A screenshot
could be found ![here](vivado_cmac.png).

### Alveo U50 board files

When build for an Alveo U50 board, the U50 Vivado board files are required. However,
neither the default Vivado 2020.2 installation nor the Xilinx Board Store currently
has these files. If you are building for Alveo U50, please contact Xilinx for a copy
of the U50 board files. These files should be placed under

    <Vivado_Installation>/2020.2/data/boards/board_files/au50/<board_file_version>/

---

# Copyright Notice and Disclaimer

This file contains confidential and proprietary information of Xilinx, Inc. and
is protected under U.S. and international copyright and other intellectual
property laws.

DISCLAIMER

This disclaimer is not a license and does not grant any rights to the materials
distributed herewith.  Except as otherwise provided in a valid license issued to
you by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE
MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY
DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY,
INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NONINFRINGEMENT, OR
FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether
in contract or tort, including negligence, or under any other theory of
liability) for any loss or damage of any kind or nature related to, arising
under or in connection with these materials, including for any direct, or any
indirect, special, incidental, or consequential loss or damage (including loss
of data, profits, goodwill, or any type of loss or damage suffered as a result
of any action brought by a third party) even if such damage or loss was
reasonably foreseeable or Xilinx had been advised of the possibility of the
same.

CRITICAL APPLICATIONS

Xilinx products are not designed or intended to be fail-safe, or for use in any
application requiring failsafe performance, such as life-support or safety
devices or systems, Class III medical devices, nuclear facilities, applications
related to the deployment of airbags, or any other applications that could lead
to death, personal injury, or severe property or environmental damage
(individually and collectively, "Critical Applications"). Customer assumes the
sole risk and liability of any use of Xilinx products in Critical Applications,
subject only to applicable laws and regulations governing limitations on product
liability.

THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT
ALL TIMES.
