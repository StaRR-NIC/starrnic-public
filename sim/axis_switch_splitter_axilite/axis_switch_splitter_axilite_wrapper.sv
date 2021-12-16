module axis_switch_splitter_axilite_wrapper #(
  parameter int TDATA_WIDTH = 512,
  parameter int TUSER_WIDTH = 48
) (
  input                            aclk,
  input                            aresetn,

  input                            s_axis_tvalid,
  output                           s_axis_tready,
  input          [TDATA_WIDTH-1:0] s_axis_tdata,
  input        [TDATA_WIDTH/8-1:0] s_axis_tkeep,
  input                            s_axis_tlast,
  input          [TUSER_WIDTH-1:0] s_axis_tuser,

  output                           m_axis1_tvalid,
  input                            m_axis1_tready,
  output         [TDATA_WIDTH-1:0] m_axis1_tdata,
  output       [TDATA_WIDTH/8-1:0] m_axis1_tkeep,
  output                           m_axis1_tlast,
  output         [TUSER_WIDTH-1:0] m_axis1_tuser,

  output                           m_axis2_tvalid,
  input                            m_axis2_tready,
  output         [TDATA_WIDTH-1:0] m_axis2_tdata,
  output       [TDATA_WIDTH/8-1:0] m_axis2_tkeep,
  output                           m_axis2_tlast,
  output         [TUSER_WIDTH-1:0] m_axis2_tuser,

  input                            s_axi_ctrl_aclk,
  input                            s_axi_ctrl_aresetn,
  input                            s_axi_ctrl_awvalid,
  input                      [6:0] s_axi_ctrl_awaddr,
  output                           s_axi_ctrl_awready,
  input                            s_axi_ctrl_wvalid,
  input                     [31:0] s_axi_ctrl_wdata,
  input                      [3:0] s_axi_ctrl_wstrb, // Dummy, only used for sim.
  output                           s_axi_ctrl_wready,
  output                           s_axi_ctrl_bvalid,
  output                     [1:0] s_axi_ctrl_bresp,
  input                            s_axi_ctrl_bready,
  input                            s_axi_ctrl_arvalid,
  input                      [6:0] s_axi_ctrl_araddr,
  output                           s_axi_ctrl_arready,
  output                           s_axi_ctrl_rvalid,
  output                    [31:0] s_axi_ctrl_rdata,
  output                     [1:0] s_axi_ctrl_rresp,
  input                            s_axi_ctrl_rready
);

  localparam PORT_COUNT = 2;
  wire                [PORT_COUNT-1:0] axis_splitter_tready;
  wire                [PORT_COUNT-1:0] axis_splitter_tvalid;
  wire    [TDATA_WIDTH*PORT_COUNT-1:0] axis_splitter_tdata;
  wire  [TDATA_WIDTH*PORT_COUNT/8-1:0] axis_splitter_tkeep;
  wire                [PORT_COUNT-1:0] axis_splitter_tlast;
  wire    [TUSER_WIDTH*PORT_COUNT-1:0] axis_splitter_tuser;

  assign axis_splitter_tready[0+:1] = m_axis1_tready;
  assign m_axis1_tvalid             = axis_splitter_tvalid[0+:1];
  assign m_axis1_tdata              = axis_splitter_tdata[0+:TDATA_WIDTH];
  assign m_axis1_tkeep              = axis_splitter_tkeep[0+:TDATA_WIDTH/8];
  assign m_axis1_tlast              = axis_splitter_tlast[0+:1];
  assign m_axis1_tuser              = axis_splitter_tuser[0+:TUSER_WIDTH];

  assign axis_splitter_tready[1+:1] = m_axis2_tready;
  assign m_axis2_tvalid             = axis_splitter_tvalid[1+:1];
  assign m_axis2_tdata              = axis_splitter_tdata[TDATA_WIDTH+:TDATA_WIDTH];
  assign m_axis2_tkeep              = axis_splitter_tkeep[TDATA_WIDTH/8+:TDATA_WIDTH/8];
  assign m_axis2_tlast              = axis_splitter_tlast[1+:1];
  assign m_axis2_tuser              = axis_splitter_tuser[TUSER_WIDTH+:TUSER_WIDTH];

axis_switch_splitter_axilite splitter_inst (
  .aclk               (aclk),
  .aresetn            (aresetn),

  .s_axi_ctrl_aclk    (s_axi_ctrl_aclk),
  .s_axi_ctrl_aresetn (s_axi_aresetn),
  .s_axi_ctrl_awvalid (s_axi_ctrl_awvalid),
  .s_axi_ctrl_awaddr  (s_axi_ctrl_awaddr[0+:7]),
  .s_axi_ctrl_wvalid  (s_axi_ctrl_wvalid),
  .s_axi_ctrl_wdata   (s_axi_ctrl_wdata[0+:32]),
  .s_axi_ctrl_bready  (s_axi_ctrl_bready),
  .s_axi_ctrl_arvalid (s_axi_ctrl_arvalid),
  .s_axi_ctrl_araddr  (s_axi_ctrl_araddr[0+:7]),
  .s_axi_ctrl_rready  (s_axi_ctrl_rready),
  .s_axi_ctrl_awready (s_axi_ctrl_awready),
  .s_axi_ctrl_wready  (s_axi_ctrl_wready),
  .s_axi_ctrl_bvalid  (s_axi_ctrl_bvalid),
  .s_axi_ctrl_bresp   (s_axi_ctrl_bresp[0+:2]),
  .s_axi_ctrl_arready (s_axi_ctrl_arready),
  .s_axi_ctrl_rvalid  (s_axi_ctrl_rvalid),
  .s_axi_ctrl_rdata   (s_axi_ctrl_rdata[0+:32]),
  .s_axi_ctrl_rresp   (s_axi_ctrl_rresp[0+:2]),

  .s_axis_tready      (s_axis_tready),
  .s_axis_tvalid      (s_axis_tvalid),
  .s_axis_tdata       (s_axis_tdata),
  .s_axis_tkeep       (s_axis_tkeep),
  .s_axis_tlast       (s_axis_tlast),
  .s_axis_tuser       (s_axis_tuser),

  .m_axis_tready      (axis_splitter_tready),
  .m_axis_tvalid      (axis_splitter_tvalid),
  .m_axis_tdata       (axis_splitter_tdata),
  .m_axis_tkeep       (axis_splitter_tkeep),
  .m_axis_tlast       (axis_splitter_tlast),
  .m_axis_tuser       (axis_splitter_tuser)
);

endmodule: axis_switch_splitter_axilite_wrapper
