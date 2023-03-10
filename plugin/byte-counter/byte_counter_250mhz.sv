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
module byte_counter_250mhz #(
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
  wire axis_aresetn;
  wire axil_aresetn;
  wire [2:0] clk_bundle;
  wire [2:0] rst_bundle;

  // Wires connecting counter registers
  wire [NUM_INTF*16-1:0] size;
  wire    [NUM_INTF-1:0] size_valid;

  // AXI-Lite register params
  localparam C_REG_ADDR_W = 12;

  // Register address
  localparam REG_BYTE_COUNT_IF1 = 12'h000;
  localparam REG_BYTE_COUNT_IF2 = 12'h004;

  wire                    reg_en;
  wire                    reg_we;
  wire [C_REG_ADDR_W-1:0] reg_addr;
  wire             [31:0] reg_din;
  reg              [31:0] reg_dout;

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

  // Counters for each INTF
  generate for (genvar i = 0; i < NUM_INTF; i++) begin
    axi_stream_size_counter #(
      .TDATA_W (512)
    ) byte_counter_inst (
      .p_axis_tvalid    (s_axis_qdma_h2c_tvalid[i]),
      .p_axis_tkeep     (s_axis_qdma_h2c_tkeep[`getvec(64, i)]),
      .p_axis_tlast     (s_axis_qdma_h2c_tlast[i]),
      .p_axis_tuser_mty (0),
      .p_axis_tready    (s_axis_qdma_h2c_tready[i]),

      .size_valid       (size_valid[i]),
      .size             (size[`getvec(16, i)]),

      .aclk             (axis_aclk),
      .aresetn          (axis_aresetn)
    );
  end
  endgenerate

  // Per INTF Pipeline
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
  endgenerate

  // Control plane access to registers
  // axi_lite_slave #(
  //   .REG_ADDR_W (12),
  //   .REG_PREFIX (16'hB000)
  // ) reg_inst (
  //   .s_axil_awvalid (s_axil_awvalid),
  //   .s_axil_awaddr  (s_axil_awaddr),
  //   .s_axil_awready (s_axil_awready),
  //   .s_axil_wvalid  (s_axil_wvalid),
  //   .s_axil_wdata   (s_axil_wdata),
  //   .s_axil_wready  (s_axil_wready),
  //   .s_axil_bvalid  (s_axil_bvalid),
  //   .s_axil_bresp   (s_axil_bresp),
  //   .s_axil_bready  (s_axil_bready),
  //   .s_axil_arvalid (s_axil_arvalid),
  //   .s_axil_araddr  (s_axil_araddr),
  //   .s_axil_arready (s_axil_arready),
  //   .s_axil_rvalid  (s_axil_rvalid),
  //   .s_axil_rdata   (s_axil_rdata),
  //   .s_axil_rresp   (s_axil_rresp),
  //   .s_axil_rready  (s_axil_rready),

  //   .aclk           (axil_aclk),
  //   .aresetn        (axil_aresetn)
  // );

  axi_lite_register #(
    .CLOCKING_MODE ("independent_clock"),
    .ADDR_W        (C_REG_ADDR_W),
    .DATA_W        (32)
  ) axil_reg_inst (
    .s_axil_awvalid (s_axil_awvalid),
    .s_axil_awaddr  (s_axil_awaddr),
    .s_axil_awready (s_axil_awready),
    .s_axil_wvalid  (s_axil_wvalid),
    .s_axil_wdata   (s_axil_wdata),
    .s_axil_wready  (s_axil_wready),
    .s_axil_bvalid  (s_axil_bvalid),
    .s_axil_bresp   (s_axil_bresp),
    .s_axil_bready  (s_axil_bready),
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_araddr  (s_axil_araddr),
    .s_axil_arready (s_axil_arready),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rdata   (s_axil_rdata),
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rready  (s_axil_rready),

    .reg_en         (reg_en),
    .reg_we         (reg_we),
    .reg_addr       (reg_addr),
    .reg_din        (reg_din),
    .reg_dout       (reg_dout),

    .axil_aclk      (axil_aclk),
    .axil_aresetn   (axil_aresetn),
    .reg_clk        (axis_aclk),
    .reg_rstn       (axis_aresetn)
  );

  initial begin
    if (NUM_INTF > 2) begin
      $fatal("No implementation for NUM_INTF (%d) > 2", NUM_INTF);
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_aresetn) begin
      reg_dout <= 0;
    end
    else if (reg_en && ~reg_we) begin
      case (reg_addr)
        REG_BYTE_COUNT_IF1: begin
          reg_dout[15:0] <= size[15:0];
          reg_dout[31:16] <= 0;
        end
        REG_BYTE_COUNT_IF2: begin
          reg_dout[15:0] <= size[NUM_INTF*16-16+:16];
          reg_dout[31:16] <= 0;
        end
        default: begin
          reg_dout <= 32'hDEADBEEF;
        end
      endcase
    end
  end

endmodule: byte_counter_250mhz
