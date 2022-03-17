wire [47:0] axis_qdma_h2c_tuser;
wire [47:0] axis_qdma_c2h_tuser;
wire [47:0] axis_adap_tx_250mhz_tuser;
wire [47:0] axis_adap_rx_250mhz_tuser;

assign axis_qdma_h2c_tuser[0+:16]                       = s_axis_qdma_h2c_tuser_size[`getvec(16, intf_idx)];
assign axis_qdma_h2c_tuser[16+:16]                      = s_axis_qdma_h2c_tuser_src[`getvec(16, intf_idx)];
assign axis_qdma_h2c_tuser[32+:16]                      = s_axis_qdma_h2c_tuser_dst[`getvec(16, intf_idx)];

assign axis_adap_rx_250mhz_tuser[0+:16]                 = s_axis_adap_rx_250mhz_tuser_size[`getvec(16, intf_idx)];
assign axis_adap_rx_250mhz_tuser[16+:16]                = s_axis_adap_rx_250mhz_tuser_src[`getvec(16, intf_idx)];
assign axis_adap_rx_250mhz_tuser[32+:16]                = s_axis_adap_rx_250mhz_tuser_dst[`getvec(16, intf_idx)];

assign m_axis_adap_tx_250mhz_tuser_size[`getvec(16, intf_idx)] = axis_adap_tx_250mhz_tuser[0+:16];
assign m_axis_adap_tx_250mhz_tuser_src[`getvec(16, intf_idx)]  = axis_adap_tx_250mhz_tuser[16+:16];
assign m_axis_adap_tx_250mhz_tuser_dst[`getvec(16, intf_idx)]  = 16'h1 << (6 + intf_idx);

assign m_axis_qdma_c2h_tuser_size[`getvec(16, intf_idx)]       = axis_qdma_c2h_tuser[0+:16];
assign m_axis_qdma_c2h_tuser_src[`getvec(16, intf_idx)]        = axis_qdma_c2h_tuser[16+:16];
assign m_axis_qdma_c2h_tuser_dst[`getvec(16, intf_idx)]        = 16'h1 << intf_idx;

// For future if we want StaRR-NIC pipeline on multiple interfaces, change this localparam to create wires.
// 4 sets of wires for connecting stream switch splitter (s) and combiner (c)
// with the bypass path (p2p) and data path (dp).
localparam STARRNIC_NUM_INTF = 1;

initial begin
  if (STARRNIC_NUM_INTF > 1) begin
    $fatal("No implementation for STARRNIC_NUM_INTF (%d) > 1", STARRNIC_NUM_INTF);
  end
end

wire     [STARRNIC_NUM_INTF-1:0] axis_s2p2p_tvalid;
wire [512*STARRNIC_NUM_INTF-1:0] axis_s2p2p_tdata;
wire  [64*STARRNIC_NUM_INTF-1:0] axis_s2p2p_tkeep;
wire     [STARRNIC_NUM_INTF-1:0] axis_s2p2p_tlast;
wire  [48*STARRNIC_NUM_INTF-1:0] axis_s2p2p_tuser;
wire     [STARRNIC_NUM_INTF-1:0] axis_s2p2p_tready;

wire     [STARRNIC_NUM_INTF-1:0] axis_p2p2c_tvalid;
wire [512*STARRNIC_NUM_INTF-1:0] axis_p2p2c_tdata;
wire  [64*STARRNIC_NUM_INTF-1:0] axis_p2p2c_tkeep;
wire     [STARRNIC_NUM_INTF-1:0] axis_p2p2c_tlast;
wire  [48*STARRNIC_NUM_INTF-1:0] axis_p2p2c_tuser;
wire     [STARRNIC_NUM_INTF-1:0] axis_p2p2c_tready;

wire     [STARRNIC_NUM_INTF-1:0] axis_s2dp_tvalid;
wire [512*STARRNIC_NUM_INTF-1:0] axis_s2dp_tdata;
wire  [64*STARRNIC_NUM_INTF-1:0] axis_s2dp_tkeep;
wire     [STARRNIC_NUM_INTF-1:0] axis_s2dp_tlast;
wire  [48*STARRNIC_NUM_INTF-1:0] axis_s2dp_tuser;
wire     [STARRNIC_NUM_INTF-1:0] axis_s2dp_tready;

wire     [STARRNIC_NUM_INTF-1:0] axis_dp2c_tvalid;
wire [512*STARRNIC_NUM_INTF-1:0] axis_dp2c_tdata;
wire  [64*STARRNIC_NUM_INTF-1:0] axis_dp2c_tkeep;
wire     [STARRNIC_NUM_INTF-1:0] axis_dp2c_tlast;
wire  [48*STARRNIC_NUM_INTF-1:0] axis_dp2c_tuser;
wire     [STARRNIC_NUM_INTF-1:0] axis_dp2c_tready;

// 2 sets for wires for concat/deconcat switch interfaces.
// number of functionalities to switch between
// (0) bypass path and (1) RM
localparam SPLIT_COMBINE_PORT_COUNT = 2;

wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_splitter_tready;
wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_splitter_tvalid;
wire [512*SPLIT_COMBINE_PORT_COUNT-1:0] axis_splitter_tdata;
wire  [64*SPLIT_COMBINE_PORT_COUNT-1:0] axis_splitter_tkeep;
wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_splitter_tlast;
wire  [48*SPLIT_COMBINE_PORT_COUNT-1:0] axis_splitter_tuser;

wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tready;
wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tvalid;
wire [512*SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tdata;
wire  [64*SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tkeep;
wire     [SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tlast;
wire  [48*SPLIT_COMBINE_PORT_COUNT-1:0] axis_combiner_tuser;

reg      [SPLIT_COMBINE_PORT_COUNT-1:0] combiner_decode_error;

// Concat/Deconcat
// Splitter
assign axis_splitter_tready[0+:1]    = axis_s2p2p_tready;
assign axis_s2p2p_tvalid             = axis_splitter_tvalid[0+:1];
assign axis_s2p2p_tdata              = axis_splitter_tdata[0+:512];
assign axis_s2p2p_tkeep              = axis_splitter_tkeep[0+:64];
assign axis_s2p2p_tlast              = axis_splitter_tlast[0+:1];
assign axis_s2p2p_tuser              = axis_splitter_tuser[0+:48];

assign axis_splitter_tready[1+:1]    = axis_s2dp_tready;
assign axis_s2dp_tvalid              = axis_splitter_tvalid[1+:1];
assign axis_s2dp_tdata               = axis_splitter_tdata[512+:512];
assign axis_s2dp_tkeep               = axis_splitter_tkeep[64+:64];
assign axis_s2dp_tlast               = axis_splitter_tlast[1+:1];
assign axis_s2dp_tuser               = axis_splitter_tuser[48+:48];

// Combiner
assign axis_p2p2c_tready             = axis_combiner_tready[0+:1];
assign axis_combiner_tvalid[0+:1]    = axis_p2p2c_tvalid;
assign axis_combiner_tdata[0+:512]   = axis_p2p2c_tdata;
assign axis_combiner_tkeep[0+:64]    = axis_p2p2c_tkeep;
assign axis_combiner_tlast[0+:1]     = axis_p2p2c_tlast;
assign axis_combiner_tuser[0+:48]    = axis_p2p2c_tuser;

assign axis_dp2c_tready              = axis_combiner_tready[1+:1];
assign axis_combiner_tvalid[1+:1]    = axis_dp2c_tvalid;
assign axis_combiner_tdata[512+:512] = axis_dp2c_tdata;
assign axis_combiner_tkeep[64+:64]   = axis_dp2c_tkeep;
assign axis_combiner_tlast[1+:1]     = axis_dp2c_tlast;
assign axis_combiner_tuser[48+:48]   = axis_dp2c_tuser;

axis_switch_splitter_axilite splitter_inst (
  .aclk               (axis_aclk),
  .s_axi_ctrl_aclk    (axil_aclk),

  .aresetn            (axis_aresetn),
  .s_axi_ctrl_aresetn (axil_aresetn),

  .s_axi_ctrl_awvalid (axil_splitter_awvalid),
  .s_axi_ctrl_awaddr  (axil_splitter_awaddr[0+:7]),
  .s_axi_ctrl_wvalid  (axil_splitter_wvalid),
  .s_axi_ctrl_wdata   (axil_splitter_wdata[0+:32]),
  .s_axi_ctrl_bready  (axil_splitter_bready),
  .s_axi_ctrl_arvalid (axil_splitter_arvalid),
  .s_axi_ctrl_araddr  (axil_splitter_araddr[0+:7]),
  .s_axi_ctrl_rready  (axil_splitter_rready),
  .s_axi_ctrl_awready (axil_splitter_awready),
  .s_axi_ctrl_wready  (axil_splitter_wready),
  .s_axi_ctrl_bvalid  (axil_splitter_bvalid),
  .s_axi_ctrl_bresp   (axil_splitter_bresp[0+:2]),
  .s_axi_ctrl_arready (axil_splitter_arready),
  .s_axi_ctrl_rvalid  (axil_splitter_rvalid),
  .s_axi_ctrl_rdata   (axil_splitter_rdata[0+:32]),
  .s_axi_ctrl_rresp   (axil_splitter_rresp[0+:2]),

  .s_axis_tready      (s_axis_qdma_h2c_tready[intf_idx]),
  .s_axis_tvalid      (s_axis_qdma_h2c_tvalid[intf_idx]),
  .s_axis_tdata       (s_axis_qdma_h2c_tdata[`getvec(512, intf_idx)]),
  .s_axis_tkeep       (s_axis_qdma_h2c_tkeep[`getvec(64, intf_idx)]),
  .s_axis_tlast       (s_axis_qdma_h2c_tlast[intf_idx]),
  .s_axis_tuser       (axis_qdma_h2c_tuser),

  .m_axis_tready      (axis_splitter_tready),
  .m_axis_tvalid      (axis_splitter_tvalid),
  .m_axis_tdata       (axis_splitter_tdata),
  .m_axis_tkeep       (axis_splitter_tkeep),
  .m_axis_tlast       (axis_splitter_tlast),
  .m_axis_tuser       (axis_splitter_tuser)
);

axi_stream_pipeline tx_ppl_inst (
  .s_axis_tready (axis_s2p2p_tready),
  .s_axis_tvalid (axis_s2p2p_tvalid),
  .s_axis_tdata  (axis_s2p2p_tdata),
  .s_axis_tkeep  (axis_s2p2p_tkeep),
  .s_axis_tlast  (axis_s2p2p_tlast),
  .s_axis_tuser  (axis_s2p2p_tuser),

  .m_axis_tready (axis_p2p2c_tready),
  .m_axis_tvalid (axis_p2p2c_tvalid),
  .m_axis_tdata  (axis_p2p2c_tdata),
  .m_axis_tkeep  (axis_p2p2c_tkeep),
  .m_axis_tlast  (axis_p2p2c_tlast),
  .m_axis_tuser  (axis_p2p2c_tuser),

  .aclk          (axis_aclk),
  .aresetn       (axil_aresetn)
);

partition1_rm_intf partition1_rm_intf_inst (
  .axil_aclk      (axil_aclk),
  .axil_aresetn   (axil_aresetn),

  .axis_aclk      (axis_aclk),
  .axis_aresetn   (axis_aresetn),

  .s_axil_awvalid (axil_dp_awvalid),
  .s_axil_awaddr  (axil_dp_awaddr),
  .s_axil_awready (axil_dp_awready),
  .s_axil_wvalid  (axil_dp_wvalid),
  .s_axil_wdata   (axil_dp_wdata),
  .s_axil_wready  (axil_dp_wready),
  .s_axil_bvalid  (axil_dp_bvalid),
  .s_axil_bresp   (axil_dp_bresp),
  .s_axil_bready  (axil_dp_bready),
  .s_axil_arvalid (axil_dp_arvalid),
  .s_axil_araddr  (axil_dp_araddr),
  .s_axil_arready (axil_dp_arready),
  .s_axil_rvalid  (axil_dp_rvalid),
  .s_axil_rdata   (axil_dp_rdata),
  .s_axil_rresp   (axil_dp_rresp),
  .s_axil_rready  (axil_dp_rready),

  .s_axis_tvalid  (axis_s2dp_tvalid),
  .s_axis_tdata   (axis_s2dp_tdata),
  .s_axis_tkeep   (axis_s2dp_tkeep),
  .s_axis_tlast   (axis_s2dp_tlast),
  .s_axis_tuser   (axis_s2dp_tuser),
  .s_axis_tready  (axis_s2dp_tready),

  .m_axis_tvalid  (axis_dp2c_tvalid),
  .m_axis_tdata   (axis_dp2c_tdata),
  .m_axis_tkeep   (axis_dp2c_tkeep),
  .m_axis_tlast   (axis_dp2c_tlast),
  .m_axis_tuser   (axis_dp2c_tuser),
  .m_axis_tready  (axis_dp2c_tready)
);

// // For debugging bypass bytecounter also including the control interface.
// axi_lite_slave #(
//   .REG_ADDR_W (18),
//   .REG_PREFIX (16'hE000)
// ) dp_axilite_not_in_use (
//   .s_axil_awvalid (axil_dp_awvalid),
//   .s_axil_awaddr  (axil_dp_awaddr),
//   .s_axil_awready (axil_dp_awready),
//   .s_axil_wvalid  (axil_dp_wvalid),
//   .s_axil_wdata   (axil_dp_wdata),
//   .s_axil_wready  (axil_dp_wready),
//   .s_axil_bvalid  (axil_dp_bvalid),
//   .s_axil_bresp   (axil_dp_bresp),
//   .s_axil_bready  (axil_dp_bready),
//   .s_axil_arvalid (axil_dp_arvalid),
//   .s_axil_araddr  (axil_dp_araddr),
//   .s_axil_arready (axil_dp_arready),
//   .s_axil_rvalid  (axil_dp_rvalid),
//   .s_axil_rdata   (axil_dp_rdata),
//   .s_axil_rresp   (axil_dp_rresp),
//   .s_axil_rready  (axil_dp_rready),

//   .aclk           (axil_aclk),
//   .aresetn        (axil_aresetn)
// );

// axi_stream_pipeline tx_ppl_inst_dp (
//   .s_axis_tvalid  (axis_s2dp_tvalid),
//   .s_axis_tdata   (axis_s2dp_tdata),
//   .s_axis_tkeep   (axis_s2dp_tkeep),
//   .s_axis_tlast   (axis_s2dp_tlast),
//   .s_axis_tuser   (axis_s2dp_tuser),
//   .s_axis_tready  (axis_s2dp_tready),

//   .m_axis_tvalid  (axis_dp2c_tvalid),
//   .m_axis_tdata   (axis_dp2c_tdata),
//   .m_axis_tkeep   (axis_dp2c_tkeep),
//   .m_axis_tlast   (axis_dp2c_tlast),
//   .m_axis_tuser   (axis_dp2c_tuser),
//   .m_axis_tready  (axis_dp2c_tready),

//   .aclk          (axis_aclk),
//   .aresetn       (axil_aresetn)
// );

axis_switch_combiner_tdest combiner_inst (
  .aclk           (axis_aclk),
  .aresetn        (axis_aresetn),

  .s_axis_tready  (axis_combiner_tready),
  .s_axis_tvalid  (axis_combiner_tvalid),
  .s_axis_tdata   (axis_combiner_tdata),
  .s_axis_tkeep   (axis_combiner_tkeep),
  .s_axis_tlast   (axis_combiner_tlast),
  .s_axis_tuser   (axis_combiner_tuser),

  .m_axis_tvalid  (m_axis_adap_tx_250mhz_tvalid[intf_idx]),
  .m_axis_tdata   (m_axis_adap_tx_250mhz_tdata[`getvec(512, intf_idx)]),
  .m_axis_tkeep   (m_axis_adap_tx_250mhz_tkeep[`getvec(64, intf_idx)]),
  .m_axis_tlast   (m_axis_adap_tx_250mhz_tlast[intf_idx]),
  .m_axis_tuser   (axis_adap_tx_250mhz_tuser),
  .m_axis_tready  (m_axis_adap_tx_250mhz_tready[intf_idx]),

  .s_req_suppress (2'b0), // Onehot encoding per slave - set high if you want to ignore arbitration of a slave.
  .s_decode_err   (combiner_decode_error)
);

axi_lite_slave #(
  .REG_ADDR_W (12),
  .REG_PREFIX (16'hC000)
) combiner_axilite_not_in_use (
  .s_axil_awvalid (axil_combiner_awvalid),
  .s_axil_awaddr  (axil_combiner_awaddr),
  .s_axil_awready (axil_combiner_awready),
  .s_axil_wvalid  (axil_combiner_wvalid),
  .s_axil_wdata   (axil_combiner_wdata),
  .s_axil_wready  (axil_combiner_wready),
  .s_axil_bvalid  (axil_combiner_bvalid),
  .s_axil_bresp   (axil_combiner_bresp),
  .s_axil_bready  (axil_combiner_bready),
  .s_axil_arvalid (axil_combiner_arvalid),
  .s_axil_araddr  (axil_combiner_araddr),
  .s_axil_arready (axil_combiner_arready),
  .s_axil_rvalid  (axil_combiner_rvalid),
  .s_axil_rdata   (axil_combiner_rdata),
  .s_axil_rresp   (axil_combiner_rresp),
  .s_axil_rready  (axil_combiner_rready),

  .aclk           (axil_aclk),
  .aresetn        (axil_aresetn)
);

axi_stream_pipeline rx_ppl_inst (
  .s_axis_tvalid (s_axis_adap_rx_250mhz_tvalid[intf_idx]),
  .s_axis_tdata  (s_axis_adap_rx_250mhz_tdata[`getvec(512, intf_idx)]),
  .s_axis_tkeep  (s_axis_adap_rx_250mhz_tkeep[`getvec(64, intf_idx)]),
  .s_axis_tlast  (s_axis_adap_rx_250mhz_tlast[intf_idx]),
  .s_axis_tuser  (axis_adap_rx_250mhz_tuser),
  .s_axis_tready (s_axis_adap_rx_250mhz_tready[intf_idx]),

  .m_axis_tvalid (m_axis_qdma_c2h_tvalid[intf_idx]),
  .m_axis_tdata  (m_axis_qdma_c2h_tdata[`getvec(512, intf_idx)]),
  .m_axis_tkeep  (m_axis_qdma_c2h_tkeep[`getvec(64, intf_idx)]),
  .m_axis_tlast  (m_axis_qdma_c2h_tlast[intf_idx]),
  .m_axis_tuser  (axis_qdma_c2h_tuser),
  .m_axis_tready (m_axis_qdma_c2h_tready[intf_idx]),

  .aclk          (axis_aclk),
  .aresetn       (axil_aresetn)
);