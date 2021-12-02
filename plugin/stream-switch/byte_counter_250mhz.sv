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

  input      [NUM_INTF-1:0] s_axis_tvalid,
  input  [512*NUM_INTF-1:0] s_axis_tdata,
  input   [64*NUM_INTF-1:0] s_axis_tkeep,
  input      [NUM_INTF-1:0] s_axis_tlast,
  input   [48*NUM_INTF-1:0] s_axis_tuser,
  output     [NUM_INTF-1:0] s_axis_tready,

  output     [NUM_INTF-1:0] m_axis_tvalid,
  output [512*NUM_INTF-1:0] m_axis_tdata,
  output  [64*NUM_INTF-1:0] m_axis_tkeep,
  output     [NUM_INTF-1:0] m_axis_tlast,
  output  [48*NUM_INTF-1:0] m_axis_tuser,
  input      [NUM_INTF-1:0] m_axis_tready,

  input                     axil_aclk,
  input                     axil_aresetn,

  input                     axis_aclk,
  input                     axis_aresetn
);

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

  // Counters for each INTF
  generate for (genvar i = 0; i < NUM_INTF; i++) begin
    axi_stream_size_counter #(
      .TDATA_W (512)
    ) byte_counter_inst (
      .p_axis_tvalid    (s_axis_tvalid[i]),
      .p_axis_tkeep     (s_axis_tkeep[`getvec(64, i)]),
      .p_axis_tlast     (s_axis_tlast[i]),
      .p_axis_tuser_mty (0),
      .p_axis_tready    (s_axis_tready[i]),

      .size_valid       (size_valid[i]),
      .size             (size[`getvec(16, i)]),

      .aclk             (axis_aclk),
      .aresetn          (axil_aresetn)
    );
  end
  endgenerate

  // Per INTF Pipeline
  generate for (genvar i = 0; i < NUM_INTF; i++) begin

    axi_stream_pipeline tx_ppl_inst (
      .s_axis_tvalid (s_axis_tvalid[i]),
      .s_axis_tdata  (s_axis_tdata[`getvec(512, i)]),
      .s_axis_tkeep  (s_axis_tkeep[`getvec(64, i)]),
      .s_axis_tlast  (s_axis_tlast[i]),
      .s_axis_tuser  (s_axis_tuser[`getvec(48, i)]),
      .s_axis_tready (s_axis_tready[i]),

      .m_axis_tvalid (m_axis_tvalid[i]),
      .m_axis_tdata  (m_axis_tdata[`getvec(512, i)]),
      .m_axis_tkeep  (m_axis_tkeep[`getvec(64, i)]),
      .m_axis_tlast  (m_axis_tlast[i]),
      .m_axis_tuser  (m_axis_tuser[`getvec(48, i)]),
      .m_axis_tready (m_axis_tready[i]),

      .aclk          (axis_aclk),
      .aresetn       (axil_aresetn)
    );
  end
  endgenerate

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
