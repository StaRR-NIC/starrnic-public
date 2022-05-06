// Dummy module to check design that contains P4 module
module vitis_net_p4_0(
    input wire s_axis_aclk,
    input wire s_axis_aresetn,
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    input wire [47:0] user_metadata_in,
    input wire user_metadata_in_valid,
    output wire [47:0] user_metadata_out,
    output wire user_metadata_out_valid,

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

    input wire [12:0] s_axi_araddr,
    output wire s_axi_arready,
    input wire s_axi_arvalid,
    input wire [12:0] s_axi_awaddr,
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

  axi_stream_pipeline tx_ppl_inst (
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tkeep  (s_axis_tkeep),
    .s_axis_tlast  (s_axis_tlast),
    .s_axis_tuser  (user_metadata_in),
    .s_axis_tready (s_axis_tready),

    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tkeep  (m_axis_tkeep),
    .m_axis_tlast  (m_axis_tlast),
    .m_axis_tuser  (user_metadata_out),
    .m_axis_tready (m_axis_tready),

    .aclk          (s_axis_aclk),
    .aresetn       (s_axis_aresetn)
  );

  axi_lite_slave #(
    .REG_ADDR_W (12),
    .REG_PREFIX (16'hB000)
  ) reg_inst (
    .s_axil_awvalid (s_axi_awvalid),
    .s_axil_awaddr  (s_axi_awaddr),
    .s_axil_awready (s_axi_awready),
    .s_axil_wvalid  (s_axi_wvalid),
    .s_axil_wdata   (s_axi_wdata),
    .s_axil_wready  (s_axi_wready),
    .s_axil_bvalid  (s_axi_bvalid),
    .s_axil_bresp   (s_axi_bresp),
    .s_axil_bready  (s_axi_bready),
    .s_axil_arvalid (s_axi_arvalid),
    .s_axil_araddr  (s_axi_araddr),
    .s_axil_arready (s_axi_arready),
    .s_axil_rvalid  (s_axi_rvalid),
    .s_axil_rdata   (s_axi_rdata),
    .s_axil_rresp   (s_axi_rresp),
    .s_axil_rready  (s_axi_rready),

    .aclk           (s_axi_aclk),
    .aresetn        (s_axi_aresetn)
  );

  assign user_metadata_out_valid = m_axis_tvalid && m_axis_tready && m_axis_tlast;

endmodule: vitis_net_p4_0