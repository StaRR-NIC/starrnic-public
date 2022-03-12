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

  generate for (genvar i = 1; i < NUM_INTF; i++) begin
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

    axi_stream_pipeline rx_ppl_inst (
      .s_axis_tvalid (s_axis_adap_rx_250mhz_tvalid[i]),
      .s_axis_tdata  (s_axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
      .s_axis_tkeep  (s_axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
      .s_axis_tlast  (s_axis_adap_rx_250mhz_tlast[i]),
      .s_axis_tuser  (axis_adap_rx_250mhz_tuser),
      .s_axis_tready (s_axis_adap_rx_250mhz_tready[i]),

      .m_axis_tvalid (m_axis_qdma_c2h_tvalid[i]),
      .m_axis_tdata  (m_axis_qdma_c2h_tdata[`getvec(512, i)]),
      .m_axis_tkeep  (m_axis_qdma_c2h_tkeep[`getvec(64, i)]),
      .m_axis_tlast  (m_axis_qdma_c2h_tlast[i]),
      .m_axis_tuser  (axis_qdma_c2h_tuser),
      .m_axis_tready (m_axis_qdma_c2h_tready[i]),

      .aclk          (axis_aclk),
      .aresetn       (axil_aresetn)
    );
  end

endmodule: stream_switch_dfx
