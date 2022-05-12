module p4_hdr_update_wrapper(
  input wire axis_aclk,
  input wire axis_aresetn,
  input wire axil_aclk,
  input wire axil_aresetn,

  input wire [511:0] s_axis_tdata,
  input wire [63:0] s_axis_tkeep,
  input wire s_axis_tlast,
  input wire s_axis_tvalid,
  output wire s_axis_tready,

  output wire [511:0] m_axis_tdata,
  output wire [63:0] m_axis_tkeep,
  output wire m_axis_tlast,
  output wire m_axis_tvalid,
  input wire m_axis_tready,

  input wire s_axi_araddr,
  output wire s_axi_arready,
  input wire s_axi_arvalid,
  input wire s_axi_awaddr,
  output wire s_axi_awready,
  input wire s_axi_awvalid,
  input wire s_axi_bready,
  output wire [1:0] s_axi_bresp,
  output wire s_axi_bvalid,
  output wire [31:0] s_axi_rdata,
  input wire s_axi_rready,
  output wire [1:0] s_axi_rresp,
  output wire s_axi_rvalid,
  input wire [31:0] s_axi_wdata,
  output wire s_axi_wready,
  input wire [3:0] s_axi_wstrb,
  input wire s_axi_wvalid
);

  wire [18:0] user_metadata_out;
  wire user_metadata_out_valid;

  vitis_net_p4_0 p4_hdr_update (
    .s_axis_aclk     (axis_aclk),
    .s_axis_aresetn  (axis_aresetn),
    .s_axi_aclk      (axil_aclk),
    .s_axi_aresetn   (axil_aresetn),

    .user_metadata_in(19'b0),
    .user_metadata_in_valid(s_axis_tvalid && s_axis_tready && s_axis_tlast),
    .user_metadata_out(user_metadata_out),
    .user_metadata_out_valid(user_metadata_out_valid),

    .s_axis_tdata    (s_axis_tdata),
    .s_axis_tkeep    (s_axis_tkeep),
    .s_axis_tlast    (s_axis_tlast),
    .s_axis_tvalid   (s_axis_tvalid),
    .s_axis_tready   (s_axis_tready),

    .m_axis_tdata    (m_axis_tdata),
    .m_axis_tkeep    (m_axis_tkeep),
    .m_axis_tlast    (m_axis_tlast),
    .m_axis_tvalid   (m_axis_tvalid),
    .m_axis_tready   (m_axis_tready),

    .s_axi_araddr    (s_axi_araddr),
    .s_axi_arready   (s_axi_arready),
    .s_axi_arvalid   (s_axi_arvalid),
    .s_axi_awaddr    (s_axi_awaddr),
    .s_axi_awready   (s_axi_awready),
    .s_axi_awvalid   (s_axi_awvalid),
    .s_axi_bready    (s_axi_bready),
    .s_axi_bresp     (s_axi_bresp),
    .s_axi_bvalid    (s_axi_bvalid),
    .s_axi_rdata     (s_axi_rdata),
    .s_axi_rready    (s_axi_rready),
    .s_axi_rresp     (s_axi_rresp),
    .s_axi_rvalid    (s_axi_rvalid),
    .s_axi_wdata     (s_axi_wdata),
    .s_axi_wready    (s_axi_wready),
    .s_axi_wstrb     (s_axi_wstrb),
    .s_axi_wvalid    (s_axi_wvalid)
  );

endmodule: p4_hdr_update_wrapper