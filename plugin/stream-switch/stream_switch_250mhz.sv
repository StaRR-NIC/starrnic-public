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
`timescale 1ns/1ps
module stream_switch_250mhz #(
  parameter int NUM_INTF = 1
) (
  input                     s_axil_awvalid,
  input              [31:0] s_axil_awaddr,
  output                    s_axil_awready,
  input                     s_axil_wvalid,
  input              [31:0] s_axil_wdata,
  output                    s_axil_wready,
  output                    s_axil_bvalid,
  output              [1:0] s_axil_bresp,
  input                     s_axil_bready,
  input                     s_axil_arvalid,
  input              [31:0] s_axil_araddr,
  output                    s_axil_arready,
  output                    s_axil_rvalid,
  output             [31:0] s_axil_rdata,
  output              [1:0] s_axil_rresp,
  input                     s_axil_rready,

  input      [NUM_INTF-1:0] s_axis_qdma_h2c_tvalid,
  input  [512*NUM_INTF-1:0] s_axis_qdma_h2c_tdata,
  input   [64*NUM_INTF-1:0] s_axis_qdma_h2c_tkeep,
  input      [NUM_INTF-1:0] s_axis_qdma_h2c_tlast,
  input   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_size,
  input   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_src,
  input   [16*NUM_INTF-1:0] s_axis_qdma_h2c_tuser_dst,
  output     [NUM_INTF-1:0] s_axis_qdma_h2c_tready,

  output     [NUM_INTF-1:0] m_axis_qdma_c2h_tvalid,
  output [512*NUM_INTF-1:0] m_axis_qdma_c2h_tdata,
  output  [64*NUM_INTF-1:0] m_axis_qdma_c2h_tkeep,
  output     [NUM_INTF-1:0] m_axis_qdma_c2h_tlast,
  output  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_size,
  output  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_src,
  output  [16*NUM_INTF-1:0] m_axis_qdma_c2h_tuser_dst,
  input      [NUM_INTF-1:0] m_axis_qdma_c2h_tready,

  output     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tvalid,
  output [512*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tdata,
  output  [64*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tkeep,
  output     [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tlast,
  output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_size,
  output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_src,
  output  [16*NUM_INTF-1:0] m_axis_adap_tx_250mhz_tuser_dst,
  input      [NUM_INTF-1:0] m_axis_adap_tx_250mhz_tready,

  input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tvalid,
  input  [512*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tdata,
  input   [64*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tkeep,
  input      [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tlast,
  input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_size,
  input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_src,
  input   [16*NUM_INTF-1:0] s_axis_adap_rx_250mhz_tuser_dst,
  output     [NUM_INTF-1:0] s_axis_adap_rx_250mhz_tready,

  input                     mod_rstn,
  output                    mod_rst_done,

  input                     axil_aclk,
  input                     axis_aclk
);

  // Reset signals in two clock domains
  wire       axis_aresetn;
  wire       axil_aresetn;
  wire [2:0] clk_bundle;
  wire [2:0] rst_bundle;

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
  assign axil_aresetn = rst_bundle[0];
  assign axis_aresetn = rst_bundle[1];

  `include "stream_switch_address_map_inst.vh"

  generate for (genvar i = 0; i < NUM_INTF; i++) begin
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


    // NOTE: Currently only instantiating switching in INTF0. Need to create addressmaps and axilite interfaces for INTF1.
    generate if (i == 0) begin
      // 4 sets of wires for connecting stream switch splitter (s) and combiner (c)
      // with the bypass path (p2p) and data path (dp).
      localparam NUM_INF_PLACEHOLDER = 1;

      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tvalid;
      wire [512*NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tdata;
      wire  [64*NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tkeep;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tlast;
      wire  [48*NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tuser;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tready;

      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tvalid;
      wire [512*NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tdata;
      wire  [64*NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tkeep;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tlast;
      wire  [48*NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tuser;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2p2p_tready;

      wire     [NUM_INF_PLACEHOLDER-1:0] axis_p2p2c_tvalid;
      wire [512*NUM_INF_PLACEHOLDER-1:0] axis_p2p2c_tdata;
      wire  [64*NUM_INF_PLACEHOLDER-1:0] axis_p2p2c_tkeep;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_p2p2c_tlast;
      wire  [48*NUM_INF_PLACEHOLDER-1:0] axis_p2p2c_tuser;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_p2p2c_tready;

      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2dp_tvalid;
      wire [512*NUM_INF_PLACEHOLDER-1:0] axis_s2dp_tdata;
      wire  [64*NUM_INF_PLACEHOLDER-1:0] axis_s2dp_tkeep;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2dp_tlast;
      wire  [48*NUM_INF_PLACEHOLDER-1:0] axis_s2dp_tuser;
      wire     [NUM_INF_PLACEHOLDER-1:0] axis_s2dp_tready;

      // 2 sets for wires for merging/demerging switch interfaces.
      localparam PORT_COUNT = 2; // number of functionalities to switch between

      wire     [PORT_COUNT-1:0] axis_splitter_tvalid;
      wire [512*PORT_COUNT-1:0] axis_splitter_tdata;
      wire  [64*PORT_COUNT-1:0] axis_splitter_tkeep;
      wire     [PORT_COUNT-1:0] axis_splitter_tlast;
      wire  [48*PORT_COUNT-1:0] axis_splitter_tuser;
      wire     [PORT_COUNT-1:0] axis_splitter_tready;

      wire     [PORT_COUNT-1:0] axis_combiner_tvalid;
      wire [512*PORT_COUNT-1:0] axis_combiner_tdata;
      wire  [64*PORT_COUNT-1:0] axis_combiner_tkeep;
      wire     [PORT_COUNT-1:0] axis_combiner_tlast;
      wire  [48*PORT_COUNT-1:0] axis_combiner_tuser;
      wire     [PORT_COUNT-1:0] axis_combiner_tready;

      reg      [PORT_COUNT-1:0] combiner_decode_error;

      // Merging/Demerging
      // Splitter
      assign axis_s2p2p_tvalid             = axis_splitter_tvalid[0+:1];
      assign axis_s2p2p_tdata              = axis_splitter_tdata[0+:512];
      assign axis_s2p2p_tkeep              = axis_splitter_tkeep[0+:64];
      assign axis_s2p2p_tlast              = axis_splitter_tlast[0+:1];
      assign axis_s2p2p_tuser              = axis_splitter_tuser[0+:48];
      assign axis_s2p2p_tready             = axis_splitter_tready[0+:1];

      assign axis_s2p2p_tvalid             = axis_splitter_tvalid[1+:1];
      assign axis_s2p2p_tdata              = axis_splitter_tdata[512+:512];
      assign axis_s2p2p_tkeep              = axis_splitter_tkeep[64+:64];
      assign axis_s2p2p_tlast              = axis_splitter_tlast[1+:1];
      assign axis_s2p2p_tuser              = axis_splitter_tuser[48+:48];
      assign axis_s2p2p_tready             = axis_splitter_tready[1+:1];

      // Combiner
      assign axis_combiner_ready[0+:1]     = axis_p2p2c_tready;
      assign axis_combiner_tvalid[0+:1]    = axis_p2p2c_tvalid;
      assign axis_combiner_tdata[0+:512]   = axis_p2p2c_tdata;
      assign axis_combiner_tkeep[0+:64]    = axis_p2p2c_tkeep;
      assign axis_combiner_tlast[0+:1]     = axis_p2p2c_tlast;
      assign axis_combiner_tuser[0+:48]    = axis_p2p2c_tuser;

      assign axis_combiner_tready[1+:1]    = axis_dp2c_tready;
      assign axis_combiner_tvalid[1+:1]    = axis_dp2c_tvalid;
      assign axis_combiner_tdata[512+:512] = axis_dp2c_tdata;
      assign axis_combiner_tkeep[64+:64]   = axis_dp2c_tkeep;
      assign axis_combiner_tlast[1+:1]     = axis_dp2c_tlast;
      assign axis_combiner_tuser[48+:48]   = axis_dp2c_tuser;

      stream_switch_axis_switch_splitter_axilite splitter_inst (
        .aclk (axis_aclk),
        .s_axi_ctrl_aclk (axil_aclk),

        .aresetn (axis_aresetn),
        .s_axi_ctrl_aresetn (axil_aresetn),

        .s_axi_ctrl_awvalid (axil_splitter_awvalid),
        .s_axi_ctrl_awaddr (axil_splitter_awaddr[0+:7]),
        .s_axi_ctrl_wvalid (axil_splitter_wvalid),
        .s_axi_ctrl_wdata (axil_splitter_wdata[0+:32]),
        .s_axi_ctrl_bready (axil_splitter_bready),
        .s_axi_ctrl_arvalid (axil_splitter_arvalid),
        .s_axi_ctrl_araddr (axil_splitter_araddr[0+:7]),
        .s_axi_ctrl_rready (axil_splitter_rready),
        .s_axi_ctrl_awready (axil_splitter_awready),
        .s_axi_ctrl_wready (axil_splitter_wready),
        .s_axi_ctrl_bvalid (axil_splitter_bvalid),
        .s_axi_ctrl_bresp (axil_splitter_bresp[0+:2]),
        .s_axi_ctrl_arready (axil_splitter_arready),
        .s_axi_ctrl_rvalid (axil_splitter_rvalid),
        .s_axi_ctrl_rdata (axil_splitter_rdata[0+:32]),
        .s_axi_ctrl_rresp (axil_splitter_rresp[0+:2]),

        .s_axis_tvalid (s_axis_qdma_h2c_tvalid[i]),
        .s_axis_tdata  (s_axis_qdma_h2c_tdata[`getvec(512, i)]),
        .s_axis_tkeep  (s_axis_qdma_h2c_tkeep[`getvec(64, i)]),
        .s_axis_tlast  (s_axis_qdma_h2c_tlast[i]),
        .s_axis_tuser  (axis_qdma_h2c_tuser),
        .s_axis_tready (s_axis_qdma_h2c_tready[i]),

        .m_axis_tready (axis_splitter_tready),
        .m_axis_tvalid (axis_splitter_tvalid),
        .m_axis_tdata (axis_splitter_tdata),
        .m_axis_tkeep (axis_splitter_tkeep),
        .m_axis_tlast (axis_splitter_tlast),
        .m_axis_tuser (axis_splitter_tuser)
      );

      axi_stream_pipeline tx_ppl_inst (
        .s_axis_tready (axis_s2p2p_tready),
        .s_axis_tvalid (axis_s2p2p_tvalid),
        .s_axis_tdata (axis_s2p2p_tdata),
        .s_axis_tkeep (axis_s2p2p_tkeep),
        .s_axis_tlast (axis_s2p2p_tlast),
        .s_axis_tuser (axis_s2p2p_tuser),

        .m_axis_tready (axis_p2p2c_tready),
        .m_axis_tvalid (axis_p2p2c_tvalid),
        .m_axis_tdata (axis_p2p2c_tdata),
        .m_axis_tkeep (axis_p2p2c_tkeep),
        .m_axis_tlast (axis_p2p2c_tlast),
        .m_axis_tuser (axis_p2p2c_tuser),

        .aclk          (axis_aclk),
        .aresetn       (axil_aresetn)
      );

      axi_stream_pipeline tx_ppl_inst_placeholder_for_byte_counter (
        .s_axis_tready (axis_s2dp_tready),
        .s_axis_tvalid (axis_s2dp_tvalid),
        .s_axis_tdata (axis_s2dp_tdata),
        .s_axis_tkeep (axis_s2dp_tkeep),
        .s_axis_tlast (axis_s2dp_tlast),
        .s_axis_tuser (axis_s2dp_tuser),

        .m_axis_tready (axis_dp2c_tready),
        .m_axis_tvalid (axis_dp2c_tvalid),
        .m_axis_tdata (axis_dp2c_tdata),
        .m_axis_tkeep (axis_dp2c_tkeep),
        .m_axis_tlast (axis_dp2c_tlast),
        .m_axis_tuser (axis_dp2c_tuser),

        .aclk          (axis_aclk),
        .aresetn       (axil_aresetn)
      );

      stream_switch_axis_switch_combiner_tdest combiner_inst (
        .aclk (axis_aclk),
        .aresetn (axis_aresetn),

        .s_axis_tready (axis_combiner_tready),
        .s_axis_tvalid (axis_combiner_tvalid),
        .s_axis_tdata (axis_combiner_tdata),
        .s_axis_tkeep (axis_combiner_tkeep),
        .s_axis_tlast (axis_combiner_tlast),
        .s_axis_tuser (axis_combiner_tuser),

        .m_axis_tvalid (m_axis_adap_tx_250mhz_tvalid[i]),
        .m_axis_tdata  (m_axis_adap_tx_250mhz_tdata[`getvec(512, i)]),
        .m_axis_tkeep  (m_axis_adap_tx_250mhz_tkeep[`getvec(64, i)]),
        .m_axis_tlast  (m_axis_adap_tx_250mhz_tlast[i]),
        .m_axis_tuser  (axis_adap_tx_250mhz_tuser),
        .m_axis_tready (m_axis_adap_tx_250mhz_tready[i]),

        .s_req_suppress (2'b0), // Onehot encoding per slave - set high if you want to ignore arbitration of a slave.
        .s_decode_err (combiner_decode_error)
      );

    end
    else begin
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
    end
    endgenerate

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
  endgenerate

endmodule: stream_switch_250mhz
