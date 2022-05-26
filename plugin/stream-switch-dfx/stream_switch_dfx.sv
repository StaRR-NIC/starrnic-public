// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
`include "open_nic_shell_macros.vh"
// `default_nettype none
`timescale 1ns/1ps
module stream_switch_dfx #(
  parameter int NUM_INTF = 1
) (
  input wire                     s_axil_awvalid,
  input wire              [31:0] s_axil_awaddr,
  output wire                    s_axil_awready,
  input wire                     s_axil_wvalid,
  input wire              [31:0] s_axil_wdata,
  input wire               [3:0] s_axil_wstrb, // Dummy, only used for sim.
  output wire                    s_axil_wready,
  output wire                    s_axil_bvalid,
  output wire              [1:0] s_axil_bresp,
  input wire                     s_axil_bready,
  input wire                     s_axil_arvalid,
  input wire              [31:0] s_axil_araddr,
  output wire                    s_axil_arready,
  output wire                    s_axil_rvalid,
  output wire             [31:0] s_axil_rdata,
  output wire              [1:0] s_axil_rresp,
  input wire                     s_axil_rready,

  input wire      [NUM_INTF-1:0] s_axis_qdma_h2c_tvalid,
  input wire  [512*NUM_INTF-1:0] s_axis_qdma_h2c_tdata,
  input wire   [64*NUM_INTF-1:0] s_axis_qdma_h2c_tkeep,
  input wire      [NUM_INTF-1:0] s_axis_qdma_h2c_tlast,
  input wire   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_size,
  input wire   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_src,
  input wire   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_dst,
  output wire     [NUM_INTF-1:0] s_axis_qdma_h2c_tready,

  output wire     [NUM_INTF-1:0] m_axis_qdma_c2h_tvalid,
  output wire [512*NUM_INTF-1:0] m_axis_qdma_c2h_tdata,
  output wire  [64*NUM_INTF-1:0] m_axis_qdma_c2h_tkeep,
  output wire     [NUM_INTF-1:0] m_axis_qdma_c2h_tlast,
  output wire  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_size,
  output wire  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_src,
  output wire  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_dst,
  input wire      [NUM_INTF-1:0] m_axis_qdma_c2h_tready,

  output wire     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tvalid,
  output wire [512*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tdata,
  output wire  [64*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tkeep,
  output wire     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tlast,
  output wire  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_size,
  output wire  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_src,
  output wire  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_dst,
  input wire      [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tready,

  input wire      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tvalid,
  input wire  [512*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tdata,
  input wire   [64*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tkeep,
  input wire      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tlast,
  input wire   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_size,
  input wire   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_src,
  input wire   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_dst,
  output wire     [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tready,

  input wire                     mod_rstn,
  output wire                    mod_rst_done,

  input wire                     axil_aclk,
  input wire                     axis_aclk
);

  // Reset signals in two clock domains
  wire       axis_aresetn;
  wire       axil_aresetn;
  wire [1:0] clk_bundle;
  wire [1:0] rst_bundle;

  // Two reset signals for the 2 clocks (0: AXI-Lite 125MHz and 1: AXI-Stream 250MHz)
  generic_reset #(
    .NUM_INPUT_CLK  (2),
    .RESET_DURATION (100)
  ) reset_inst (
    .mod_rstn     (mod_rstn),
    .mod_rst_done (mod_rst_done),
    .clk          (clk_bundle),
    .rstn         (rst_bundle)
  );

  assign clk_bundle[0] = axil_aclk;
  assign clk_bundle[1] = axis_aclk;
  assign axil_aresetn  = rst_bundle[0];
  assign axis_aresetn  = rst_bundle[1];

  // Wire for carrying TX on port 0
  wire     [1-1:0] axis_qdma_h2c_p0_tvalid;
  wire [512*1-1:0] axis_qdma_h2c_p0_tdata;
  wire  [64*1-1:0] axis_qdma_h2c_p0_tkeep;
  wire     [1-1:0] axis_qdma_h2c_p0_tlast;
  wire  [48*1-1:0] axis_qdma_h2c_p0_tuser;
  wire     [1-1:0] axis_qdma_h2c_p0_tready;

  `include "stream_switch_address_map_inst.vh"

  // The PR Project Flow did not automatically support generate blocks in Vivado 2020.1.
  // So we need to instantiate all partition definitions outside of generate blocks.
  // For ease of development, we only instantiate StaRR-NIC pipeline on interface 0.
  // Interface 1 if present uses default p2p pipeline.

  //////////////////////////////////////////////////////////////////////////////
  // Interface 0
  //////////////////////////////////////////////////////////////////////////////
  // Interface on which to instantiate starrnic
  localparam intf_idx=0;
  `include "starrnic_bypass.vh"

  ////////////////////////////////////////////////////////////////////////////////
  // Remaining, interfaces 1 to NUM_INTF-1
  ////////////////////////////////////////////////////////////////////////////////

  initial begin
  if (NUM_INTF > 2) begin
    $fatal("No implementation for NUM_INTF (%d) > 2", NUM_INTF);
  end
  end

  generate if (NUM_INTF == 2) begin // for (genvar i = 1; i < NUM_INTF; i++) begin
    localparam i = 1;
    wire [47:0] axis_qdma_h2c_tuser;
    wire [47:0] axis_qdma_c2h_tuser;
    wire [47:0] axis_adap_tx_250mhz_tuser;
    wire [47:0] axis_adap_rx_250mhz_tuser;

    assign axis_qdma_h2c_tuser[0+:16]                       = s_axis_qdma_h2c_tuser_size[`getvec(16, i)];
    assign axis_qdma_h2c_tuser[16+:16]                      = s_axis_qdma_h2c_tuser_src[`getvec(16, i)];
    assign axis_qdma_h2c_tuser[32+:16]                      = s_axis_qdma_h2c_tuser_dst[`getvec(16, i)];

    assign axis_adap_rx_250mhz_tuser[0+:16]                 = s_axis_adap_rx_250mhz_tuser_size[`getvec(16, i)];
    assign axis_adap_rx_250mhz_tuser[16+:16]                = s_axis_adap_rx_250mhz_tuser_src[`getvec(16, i)];
    assign axis_adap_rx_250mhz_tuser[32+:16]                = s_axis_adap_rx_250mhz_tuser_dst[`getvec(16, i)];

    assign m_axis_adap_tx_250mhz_tuser_size[`getvec(16, i)] = axis_adap_tx_250mhz_tuser[0+:16];
    assign m_axis_adap_tx_250mhz_tuser_src[`getvec(16, i)]  = axis_adap_tx_250mhz_tuser[16+:16];
    assign m_axis_adap_tx_250mhz_tuser_dst[`getvec(16, i)]  = 16'h1 << (6 + i);

    assign m_axis_qdma_c2h_tuser_size[`getvec(16, i)]       = axis_qdma_c2h_tuser[0+:16];
    assign m_axis_qdma_c2h_tuser_src[`getvec(16, i)]        = axis_qdma_c2h_tuser[16+:16];
    assign m_axis_qdma_c2h_tuser_dst[`getvec(16, i)]        = 16'h1 << i;

    axi_stream_pipeline tx_ppl_inst (
      .s_axis_tvalid (s_axis_qdma_h2c_tvalid[i]),
      .s_axis_tdata  (s_axis_qdma_h2c_tdata[`getvec(512, i)]),
      .s_axis_tkeep  (s_axis_qdma_h2c_tkeep[`getvec(64, i)]),
      .s_axis_tlast  (s_axis_qdma_h2c_tlast[i]),
      .s_axis_tuser  (axis_qdma_h2c_tuser),
      .s_axis_tready (s_axis_qdma_h2c_tready[i]),

      .m_axis_tvalid (m_axis_adap_tx_250mhz_tvalid[i]),
      .m_axis_tdata  (m_axis_adap_tx_250mhz_tdata[`getvec(512, i)]),
      .m_axis_tkeep  (m_axis_adap_tx_250mhz_tkeep[`getvec(64, i)]),
      .m_axis_tlast  (m_axis_adap_tx_250mhz_tlast[i]),
      .m_axis_tuser  (axis_adap_tx_250mhz_tuser),
      .m_axis_tready (m_axis_adap_tx_250mhz_tready[i]),

      .aclk          (axis_aclk),
      .aresetn       (axil_aresetn)
    );

    // Terminate C2H (don't send anything on RX to QDMA)
    assign m_axis_qdma_c2h_tvalid[i]              = 1'b0;
    assign m_axis_qdma_c2h_tdata[`getvec(512, i)] = 0;
    assign m_axis_qdma_c2h_tkeep[`getvec(64, i)]  = 0;
    assign m_axis_qdma_c2h_tlast[i]               = 1'b0;
    assign axis_qdma_c2h_tuser                    = 0;

    // axi_stream_pipeline rx_ppl_inst (
    //   .s_axis_tvalid (s_axis_adap_rx_250mhz_tvalid[i]),
    //   .s_axis_tdata  (s_axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
    //   .s_axis_tkeep  (s_axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
    //   .s_axis_tlast  (s_axis_adap_rx_250mhz_tlast[i]),
    //   .s_axis_tuser  (axis_adap_rx_250mhz_tuser),
    //   .s_axis_tready (s_axis_adap_rx_250mhz_tready[i]),

    //   .m_axis_tvalid (m_axis_qdma_c2h_tvalid[i]),
    //   .m_axis_tdata  (m_axis_qdma_c2h_tdata[`getvec(512, i)]),
    //   .m_axis_tkeep  (m_axis_qdma_c2h_tkeep[`getvec(64, i)]),
    //   .m_axis_tlast  (m_axis_qdma_c2h_tlast[i]),
    //   .m_axis_tuser  (axis_qdma_c2h_tuser),
    //   .m_axis_tready (m_axis_qdma_c2h_tready[i]),

    //   .aclk          (axis_aclk),
    //   .aresetn       (axil_aresetn)
    // );

    // Update headers of pkts on CMAC1 RX
    wire     [1-1:0] axis_p4hdrout_tready;
    wire     [1-1:0] axis_p4hdrout_tvalid;
    wire [512*1-1:0] axis_p4hdrout_tdata;
    wire  [64*1-1:0] axis_p4hdrout_tkeep;
    wire     [1-1:0] axis_p4hdrout_tlast;
    wire  [48*1-1:0] axis_p4hdrout_tuser;

    wire              user_metadata_out_valid;
    wire       [18:0] user_metadata_out;
    // wire       [15:0] parsed_port;
    // wire        [1:0] is_udp;
    // wire              drop_pkt;

    vitis_net_p4_0 p4_hdr_update (
      .s_axis_aclk     (axis_aclk),                                        // input wire s_axis_aclk
      .s_axis_aresetn  (axis_aresetn),                                     // input wire s_axis_aresetn
      .s_axi_aclk      (axil_aclk),                                        // input wire s_axi_aclk
      .s_axi_aresetn   (axil_aresetn),                                     // input wire s_axi_aresetn

      .user_metadata_in({s_axis_adap_rx_250mhz_tuser_size[`getvec(16, i)], // can refer to the "vitis_net_p4_0_pkg.sv" to find the field indices
        s_axis_adap_rx_250mhz_tuser_src[`getvec(16, i)],                   // and the order of each field within the metadata struct as used by the
        s_axis_adap_rx_250mhz_tuser_dst[`getvec(16, i)],                   // generated RTL implementation
        19'b0
      }),                                                                  // input wire [19+47 : 0] user_metadata_in
      .user_metadata_in_valid(s_axis_adap_rx_250mhz_tvalid[i] &&
                        s_axis_adap_rx_250mhz_tready[i] &&
                        s_axis_adap_rx_250mhz_tlast[i]
      ),                                                                   // input wire user_metadata_in_valid

      .user_metadata_out({axis_p4hdrout_tuser[15:0],                       // can refer to the "vitis_net_p4_0_pkg.sv" to find the field indices
        axis_p4hdrout_tuser[31:16],                                        // and the order of each field within the metadata struct as used
        axis_p4hdrout_tuser[47:32],                                        // by the generated RTL implementation
        user_metadata_out
      }),                                                                  // output wire [19 + 47 : 0] user_metadata_out
      .user_metadata_out_valid(user_metadata_out_valid),                   // output wire user_metadata_out_valid

      .s_axis_tdata    (s_axis_adap_rx_250mhz_tdata[`getvec(512, i)]),     // input wire [511 : 0] s_axis_tdata
      .s_axis_tkeep    (s_axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),      // input wire [63 : 0] s_axis_tkeep
      .s_axis_tlast    (s_axis_adap_rx_250mhz_tlast[i]),                   // input wire s_axis_tlast
      .s_axis_tvalid   (s_axis_adap_rx_250mhz_tvalid[i]),                  // input wire s_axis_tvalid
      .s_axis_tready   (s_axis_adap_rx_250mhz_tready[i]),                  // output wire s_axis_tready

      .m_axis_tdata    (axis_p4hdrout_tdata),                              // output wire [511 : 0] m_axis_tdata
      .m_axis_tkeep    (axis_p4hdrout_tkeep),                              // output wire [63 : 0] m_axis_tkeep
      .m_axis_tlast    (axis_p4hdrout_tlast),                              // output wire m_axis_tlast
      .m_axis_tvalid   (axis_p4hdrout_tvalid),                             // output wire m_axis_tvalid
      .m_axis_tready   (axis_p4hdrout_tready),                             // input wire m_axis_tready

      .s_axi_araddr    (axil_p4hdr_araddr),                                // input wire [12 : 0] s_axi_araddr
      .s_axi_arready   (axil_p4hdr_arready),                               // output wire s_axi_arready
      .s_axi_arvalid   (axil_p4hdr_arvalid),                               // input wire s_axi_arvalid
      .s_axi_awaddr    (axil_p4hdr_awaddr),                                // input wire [12 : 0] s_axi_awaddr
      .s_axi_awready   (axil_p4hdr_awready),                               // output wire s_axi_awready
      .s_axi_awvalid   (axil_p4hdr_awvalid),                               // input wire s_axi_awvalid
      .s_axi_bready    (axil_p4hdr_bready),                                // input wire s_axi_bready
      .s_axi_bresp     (axil_p4hdr_bresp),                                 // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid    (axil_p4hdr_bvalid),                                // output wire s_axi_bvalid
      .s_axi_rdata     (axil_p4hdr_rdata),                                 // output wire [31 : 0] s_axi_rdata
      .s_axi_rready    (axil_p4hdr_rready),                                // input wire s_axi_rready
      .s_axi_rresp     (axil_p4hdr_rresp),                                 // output wire [1 : 0] s_axi_rresp
      .s_axi_rvalid    (axil_p4hdr_rvalid),                                // output wire s_axi_rvalid
      .s_axi_wdata     (axil_p4hdr_wdata),                                 // input wire [31 : 0] s_axi_wdata
      .s_axi_wready    (axil_p4hdr_wready),                                // output wire s_axi_wready
      .s_axi_wstrb     (4'b1111),                                          // input wire [3 : 0] s_axi_wstrb
      .s_axi_wvalid    (axil_p4hdr_wvalid)                                 // input wire s_axi_wvalid
    );

    ila_0_p4 ila_inst (
      .clk(axis_aclk),
      .probe0(axis_aclk),
      .probe1(axis_aresetn),
      .probe2(axil_aclk),
      .probe3(axil_aresetn),

      .probe4({s_axis_adap_rx_250mhz_tuser_size[`getvec(16, i)],
        s_axis_adap_rx_250mhz_tuser_src[`getvec(16, i)],
        s_axis_adap_rx_250mhz_tuser_dst[`getvec(16, i)]
      }),
      .probe5(19'b0),
      .probe6(s_axis_adap_rx_250mhz_tvalid[i] &&
        s_axis_adap_rx_250mhz_tready[i] &&
        s_axis_adap_rx_250mhz_tlast[i]
      ),

      .probe7({axis_p4hdrout_tuser[15:0],
        axis_p4hdrout_tuser[31:16],
        axis_p4hdrout_tuser[47:32]
      }),
      .probe8(user_metadata_out),
      .probe9(user_metadata_out_valid),

      .probe10(s_axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
      .probe11(s_axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
      .probe12(s_axis_adap_rx_250mhz_tlast[i]),
      .probe13(s_axis_adap_rx_250mhz_tvalid[i]),
      .probe14(s_axis_adap_rx_250mhz_tready[i]),

      .probe15(axis_p4hdrout_tdata),
      .probe16(axis_p4hdrout_tkeep),
      .probe17(axis_p4hdrout_tlast),
      .probe18(axis_p4hdrout_tvalid),
      .probe19(axis_p4hdrout_tready)
    );

    wire     [1-1:0] axis_ppl_tready;
    wire     [1-1:0] axis_ppl_tvalid;
    wire [512*1-1:0] axis_ppl_tdata;
    wire  [64*1-1:0] axis_ppl_tkeep;
    wire     [1-1:0] axis_ppl_tlast;
    wire  [48*1-1:0] axis_ppl_tuser;

    axi_stream_pipeline p4_ppl_combiner (
      .s_axis_tvalid (axis_p4hdrout_tvalid),
      .s_axis_tdata  (axis_p4hdrout_tdata),
      .s_axis_tkeep  (axis_p4hdrout_tkeep),
      .s_axis_tlast  (axis_p4hdrout_tlast),
      .s_axis_tuser  (axis_p4hdrout_tuser),
      .s_axis_tready (axis_p4hdrout_tready),

      .m_axis_tvalid (axis_ppl_tvalid),
      .m_axis_tdata  (axis_ppl_tdata),
      .m_axis_tkeep  (axis_ppl_tkeep),
      .m_axis_tlast  (axis_ppl_tlast),
      .m_axis_tuser  (axis_ppl_tuser),
      .m_axis_tready (axis_ppl_tready),

      .aclk          (axis_aclk),
      .aresetn       (axis_aresetn)
    );

    // // Debug signals for P4 module
    // assign parsed_port = user_metadata_out[18:3];
    // assign is_udp      = user_metadata_out[2:1];
    // assign drop_pkt    = user_metadata_out[0];

    // // Disconnect PCIe in for port 0
    // assign axis_p4hdrout_tready[0]        = axis_qdma_h2c_p0_tready[0+:1];
    // assign axis_qdma_h2c_p0_tvalid[0+:1]  = axis_p4hdrout_tvalid[0];
    // assign axis_qdma_h2c_p0_tdata[0+:512] = axis_p4hdrout_tdata[511:0];
    // assign axis_qdma_h2c_p0_tkeep[0+:64]  = axis_p4hdrout_tkeep[63:0];
    // assign axis_qdma_h2c_p0_tlast[0+:1]   = axis_p4hdrout_tlast[0];
    // assign axis_qdma_h2c_p0_tuser         = axis_p4hdrout_tuser;
    // assign s_axis_qdma_h2c_tready[0] = 0;

    // Combine traffic from PCIe in for port 0 and RX on port 1
    // Any traffic on CMAC1 RX should be diverted to CMAC0 TX.
    localparam SPLIT_COMBINE_PORT_COUNT = 2;
    wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tready;
    wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tvalid;
    wire [512*SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tdata;
    wire  [64*SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tkeep;
    wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tlast;
    wire  [48*SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tuser;
    reg      [SPLIT_COMBINE_PORT_COUNT-1:0] combiner_decode_error;

    // Combiner
    assign s_axis_qdma_h2c_tready[0]       = axis_combiner_tready[0];
    assign axis_combiner_tvalid[0+:1]      = s_axis_qdma_h2c_tvalid[0];
    assign axis_combiner_tdata[0+:512]     = s_axis_qdma_h2c_tdata[511:0];
    assign axis_combiner_tkeep[0+:64]      = s_axis_qdma_h2c_tkeep[63:0];
    assign axis_combiner_tlast[0+:1]       = s_axis_qdma_h2c_tlast[0];
    assign axis_combiner_tuser[0+:48]      = axis_qdma_h2c_tuser;

    assign axis_ppl_tready                 = axis_combiner_tready[1];
    assign axis_combiner_tvalid[1+:1]      = axis_ppl_tvalid;
    assign axis_combiner_tdata[512+:512]   = axis_ppl_tdata;
    assign axis_combiner_tkeep[64+:64]     = axis_ppl_tkeep;
    assign axis_combiner_tlast[1+:1]       = axis_ppl_tlast;
    assign axis_combiner_tuser[48+:48]     = axis_ppl_tuser;

    axis_switch_combiner_tdest combiner_inst (
      .aclk           (axis_aclk),
      .aresetn        (axis_aresetn),

      .s_axis_tready  (axis_combiner_tready),
      .s_axis_tvalid  (axis_combiner_tvalid),
      .s_axis_tdata   (axis_combiner_tdata),
      .s_axis_tkeep   (axis_combiner_tkeep),
      .s_axis_tlast   (axis_combiner_tlast),
      .s_axis_tuser   (axis_combiner_tuser),

      .m_axis_tvalid  (axis_qdma_h2c_p0_tvalid),
      .m_axis_tdata   (axis_qdma_h2c_p0_tdata),
      .m_axis_tkeep   (axis_qdma_h2c_p0_tkeep),
      .m_axis_tlast   (axis_qdma_h2c_p0_tlast),
      .m_axis_tuser   (axis_qdma_h2c_p0_tuser),
      .m_axis_tready  (axis_qdma_h2c_p0_tready),

      .s_req_suppress (2'b0), // Onehot encoding per slave - set high if you want to ignore arbitration of a slave.
      .s_decode_err   (combiner_decode_error)
    );

  end
  else begin
    assign s_axis_qdma_h2c_tready[0]      = axis_qdma_h2c_p0_tready[0+:1];
    assign axis_qdma_h2c_p0_tvalid[0+:1]  = s_axis_qdma_h2c_tvalid[0];
    assign axis_qdma_h2c_p0_tdata[0+:512] = s_axis_qdma_h2c_tdata[511:0];
    assign axis_qdma_h2c_p0_tkeep[0+:64]  = s_axis_qdma_h2c_tkeep[63:0];
    assign axis_qdma_h2c_p0_tlast[0+:1]   = s_axis_qdma_h2c_tlast[0];
    assign axis_qdma_h2c_p0_tuser[0+:16]  = s_axis_qdma_h2c_tuser_size[15:0];
    assign axis_qdma_h2c_p0_tuser[16+:16] = s_axis_qdma_h2c_tuser_src[15:0];
    assign axis_qdma_h2c_p0_tuser[32+:16] = s_axis_qdma_h2c_tuser_dst[15:0];
  end
  endgenerate

endmodule: stream_switch_dfx
