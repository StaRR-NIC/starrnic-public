// *************************************************************************
// Address map for the box running at 250MHz (through PCI-e BAR2 4MB)
//
// System-level address range: 0x100000 - 0x17FFFF
// Box relative address range: 0x00000  - 0x7FFFF
// 19 bits address
//
// --------------------------------------------------
//   BaseAddr  |  HighAddr  |  Module
// --------------------------------------------------
//   0x00000   |  0x00FFF   |  Switch splitter (12 bits)
// --------------------------------------------------
//   0x01000   |  0x01FFF   |  Switch combiner (12 bits)
// --------------------------------------------------
//   0x40000   |  0x7FFFF   |  Control path (connected to p2p or dp) (18 bits)
// --------------------------------------------------

// TODO(108anup): Each address range needs to be power of 2.
//  To get other sizes, use multiple address ranges.

`timescale 1ns/1ps
module stream_switch_address_map (
  input         s_axil_awvalid,
  input  [31:0] s_axil_awaddr,
  output        s_axil_awready,
  input         s_axil_wvalid,
  input  [31:0] s_axil_wdata,
  output        s_axil_wready,
  output        s_axil_bvalid,
  output  [1:0] s_axil_bresp,
  input         s_axil_bready,
  input         s_axil_arvalid,
  input  [31:0] s_axil_araddr,
  output        s_axil_arready,
  output        s_axil_rvalid,
  output [31:0] s_axil_rdata,
  output  [1:0] s_axil_rresp,
  input         s_axil_rready,
  
  output        m_axil_splitter_awvalid,
  output [31:0] m_axil_splitter_awaddr,
  input         m_axil_splitter_awready,
  output        m_axil_splitter_wvalid,
  output [31:0] m_axil_splitter_wdata,
  input         m_axil_splitter_wready,
  input         m_axil_splitter_bvalid,
  input   [1:0] m_axil_splitter_bresp,
  output        m_axil_splitter_bready,
  output        m_axil_splitter_arvalid,
  output [31:0] m_axil_splitter_araddr,
  input         m_axil_splitter_arready,
  input         m_axil_splitter_rvalid,
  input  [31:0] m_axil_splitter_rdata,
  input   [1:0] m_axil_splitter_rresp,
  output        m_axil_splitter_rready,

  output        m_axil_combiner_awvalid,
  output [31:0] m_axil_combiner_awaddr,
  input         m_axil_combiner_awready,
  output        m_axil_combiner_wvalid,
  output [31:0] m_axil_combiner_wdata,
  input         m_axil_combiner_wready,
  input         m_axil_combiner_bvalid,
  input   [1:0] m_axil_combiner_bresp,
  output        m_axil_combiner_bready,
  output        m_axil_combiner_arvalid,
  output [31:0] m_axil_combiner_araddr,
  input         m_axil_combiner_arready,
  input         m_axil_combiner_rvalid,
  input  [31:0] m_axil_combiner_rdata,
  input   [1:0] m_axil_combiner_rresp,
  output        m_axil_combiner_rready,

  output        m_axil_dp_awvalid,
  output [31:0] m_axil_dp_awaddr,
  input         m_axil_dp_awready,
  output        m_axil_dp_wvalid,
  output [31:0] m_axil_dp_wdata,
  input         m_axil_dp_wready,
  input         m_axil_dp_bvalid,
  input   [1:0] m_axil_dp_bresp,
  output        m_axil_dp_bready,
  output        m_axil_dp_arvalid,
  output [31:0] m_axil_dp_araddr,
  input         m_axil_dp_arready,
  input         m_axil_dp_rvalid,
  input  [31:0] m_axil_dp_rdata,
  input   [1:0] m_axil_dp_rresp,
  output        m_axil_dp_rready,


  input         aclk,
  input         aresetn
);

  localparam C_NUM_SLAVES  = 3;

  localparam C_SPLITTER_INDEX   = 0;
  localparam C_COMBINER_INDEX = 1;
  localparam C_DP_INDEX = 2;

  localparam C_SPLITTER_BASE_ADDR   = 32'h0;
  localparam C_COMBINER_BASE_ADDR = 32'h1000;
  localparam C_DP_BASE_ADDR = 32'h40000;

  wire                  [31:0] axil_splitter_awaddr;
  wire                  [31:0] axil_splitter_araddr;
  wire                  [31:0] axil_combiner_awaddr;
  wire                  [31:0] axil_combiner_araddr;
  wire                  [31:0] axil_dp_awaddr;
  wire                  [31:0] axil_dp_araddr;

  wire  [(1*C_NUM_SLAVES)-1:0] axil_awvalid;
  wire [(32*C_NUM_SLAVES)-1:0] axil_awaddr;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_awready;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_wvalid;
  wire [(32*C_NUM_SLAVES)-1:0] axil_wdata;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_wready;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_bvalid;
  wire  [(2*C_NUM_SLAVES)-1:0] axil_bresp;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_bready;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_arvalid;
  wire [(32*C_NUM_SLAVES)-1:0] axil_araddr;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_arready;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_rvalid;
  wire [(32*C_NUM_SLAVES)-1:0] axil_rdata;
  wire  [(2*C_NUM_SLAVES)-1:0] axil_rresp;
  wire  [(1*C_NUM_SLAVES)-1:0] axil_rready;

  // Adjust AXI-Lite address so that each slave can assume a base address of 0x0
  assign axil_splitter_awaddr                    = axil_awaddr[C_SPLITTER_INDEX*32 +: 32] - C_SPLITTER_BASE_ADDR;
  assign axil_splitter_araddr                    = axil_araddr[C_SPLITTER_INDEX*32 +: 32] - C_SPLITTER_BASE_ADDR;
  assign axil_combiner_awaddr                    = axil_awaddr[C_COMBINER_INDEX*32 +: 32] - C_COMBINER_BASE_ADDR;
  assign axil_combiner_araddr                    = axil_araddr[C_COMBINER_INDEX*32 +: 32] - C_COMBINER_BASE_ADDR;
  assign axil_dp_awaddr                          = axil_awaddr[C_DP_INDEX*32 +: 32] - C_DP_BASE_ADDR;
  assign axil_dp_araddr                          = axil_araddr[C_DP_INDEX*32 +: 32] - C_DP_BASE_ADDR;

  assign m_axil_splitter_awvalid                 = axil_awvalid[C_SPLITTER_INDEX];
  assign m_axil_splitter_awaddr                  = axil_splitter_awaddr;
  assign axil_awready[C_SPLITTER_INDEX]          = m_axil_splitter_awready;
  assign m_axil_splitter_wvalid                  = axil_wvalid[C_SPLITTER_INDEX];
  assign m_axil_splitter_wdata                   = axil_wdata[C_SPLITTER_INDEX*32 +: 32];
  assign axil_wready[C_SPLITTER_INDEX]           = m_axil_splitter_wready;
  assign axil_bvalid[C_SPLITTER_INDEX]           = m_axil_splitter_bvalid;
  assign axil_bresp[C_SPLITTER_INDEX*2 +: 2]     = m_axil_splitter_bresp;
  assign m_axil_splitter_bready                  = axil_bready[C_SPLITTER_INDEX];
  assign m_axil_splitter_arvalid                 = axil_arvalid[C_SPLITTER_INDEX];
  assign m_axil_splitter_araddr                  = axil_splitter_araddr;
  assign axil_arready[C_SPLITTER_INDEX]          = m_axil_splitter_arready;
  assign axil_rvalid[C_SPLITTER_INDEX]           = m_axil_splitter_rvalid;
  assign axil_rdata[C_SPLITTER_INDEX*32 +: 32]   = m_axil_splitter_rdata;
  assign axil_rresp[C_SPLITTER_INDEX*2 +: 2]     = m_axil_splitter_rresp;
  assign m_axil_splitter_rready                  = axil_rready[C_SPLITTER_INDEX];

  assign m_axil_combiner_awvalid               = axil_awvalid[C_COMBINER_INDEX];
  assign m_axil_combiner_awaddr                = axil_combiner_awaddr;
  assign axil_awready[C_COMBINER_INDEX]        = m_axil_combiner_awready;
  assign m_axil_combiner_wvalid                = axil_wvalid[C_COMBINER_INDEX];
  assign m_axil_combiner_wdata                 = axil_wdata[C_COMBINER_INDEX*32 +: 32];
  assign axil_wready[C_COMBINER_INDEX]         = m_axil_combiner_wready;
  assign axil_bvalid[C_COMBINER_INDEX]         = m_axil_combiner_bvalid;
  assign axil_bresp[C_COMBINER_INDEX*2 +: 2]   = m_axil_combiner_bresp;
  assign m_axil_combiner_bready                = axil_bready[C_COMBINER_INDEX];
  assign m_axil_combiner_arvalid               = axil_arvalid[C_COMBINER_INDEX];
  assign m_axil_combiner_araddr                = axil_combiner_araddr;
  assign axil_arready[C_COMBINER_INDEX]        = m_axil_combiner_arready;
  assign axil_rvalid[C_COMBINER_INDEX]         = m_axil_combiner_rvalid;
  assign axil_rdata[C_COMBINER_INDEX*32 +: 32] = m_axil_combiner_rdata;
  assign axil_rresp[C_COMBINER_INDEX* 2 +: 2]  = m_axil_combiner_rresp;
  assign m_axil_combiner_rready                = axil_rready[C_COMBINER_INDEX];

  assign m_axil_dp_awvalid               = axil_awvalid[C_DP_INDEX];
  assign m_axil_dp_awaddr                = axil_dp_awaddr;
  assign axil_awready[C_DP_INDEX]        = m_axil_dp_awready;
  assign m_axil_dp_wvalid                = axil_wvalid[C_DP_INDEX];
  assign m_axil_dp_wdata                 = axil_wdata[C_DP_INDEX*32 +: 32];
  assign axil_wready[C_DP_INDEX]         = m_axil_dp_wready;
  assign axil_bvalid[C_DP_INDEX]         = m_axil_dp_bvalid;
  assign axil_bresp[C_DP_INDEX*2 +: 2]   = m_axil_dp_bresp;
  assign m_axil_dp_bready                = axil_bready[C_DP_INDEX];
  assign m_axil_dp_arvalid               = axil_arvalid[C_DP_INDEX];
  assign m_axil_dp_araddr                = axil_dp_araddr;
  assign axil_arready[C_DP_INDEX]        = m_axil_dp_arready;
  assign axil_rvalid[C_DP_INDEX]         = m_axil_dp_rvalid;
  assign axil_rdata[C_DP_INDEX*32 +: 32] = m_axil_dp_rdata;
  assign axil_rresp[C_DP_INDEX* 2 +: 2]  = m_axil_dp_rresp;
  assign m_axil_dp_rready                = axil_rready[C_DP_INDEX];

  stream_switch_axi_crossbar xbar_inst (
    .s_axi_awaddr  (s_axil_awaddr),
    .s_axi_awprot  (0),
    .s_axi_awvalid (s_axil_awvalid),
    .s_axi_awready (s_axil_awready),
    .s_axi_wdata   (s_axil_wdata),
    .s_axi_wstrb   (4'hF),
    .s_axi_wvalid  (s_axil_wvalid),
    .s_axi_wready  (s_axil_wready),
    .s_axi_bresp   (s_axil_bresp),
    .s_axi_bvalid  (s_axil_bvalid),
    .s_axi_bready  (s_axil_bready),
    .s_axi_araddr  (s_axil_araddr),
    .s_axi_arprot  (0),
    .s_axi_arvalid (s_axil_arvalid),
    .s_axi_arready (s_axil_arready),
    .s_axi_rdata   (s_axil_rdata),
    .s_axi_rresp   (s_axil_rresp),
    .s_axi_rvalid  (s_axil_rvalid),
    .s_axi_rready  (s_axil_rready),

    .m_axi_awaddr  (axil_awaddr),
    .m_axi_awprot  (),
    .m_axi_awvalid (axil_awvalid),
    .m_axi_awready (axil_awready),
    .m_axi_wdata   (axil_wdata),
    .m_axi_wstrb   (),
    .m_axi_wvalid  (axil_wvalid),
    .m_axi_wready  (axil_wready),
    .m_axi_bresp   (axil_bresp),
    .m_axi_bvalid  (axil_bvalid),
    .m_axi_bready  (axil_bready),
    .m_axi_araddr  (axil_araddr),
    .m_axi_arprot  (),
    .m_axi_arvalid (axil_arvalid),
    .m_axi_arready (axil_arready),
    .m_axi_rdata   (axil_rdata),
    .m_axi_rresp   (axil_rresp),
    .m_axi_rvalid  (axil_rvalid),
    .m_axi_rready  (axil_rready),

    .aclk          (aclk),
    .aresetn       (aresetn)
  );

endmodule: stream_switch_address_map
