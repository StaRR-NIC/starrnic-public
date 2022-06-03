wire        axil_splitter_awvalid;
wire [31:0] axil_splitter_awaddr;
wire        axil_splitter_awready;
wire        axil_splitter_wvalid;
wire [31:0] axil_splitter_wdata;
wire        axil_splitter_wready;
wire        axil_splitter_bvalid;
wire  [1:0] axil_splitter_bresp;
wire        axil_splitter_bready;
wire        axil_splitter_arvalid;
wire [31:0] axil_splitter_araddr;
wire        axil_splitter_arready;
wire        axil_splitter_rvalid;
wire [31:0] axil_splitter_rdata;
wire  [1:0] axil_splitter_rresp;
wire        axil_splitter_rready;

wire        axil_combiner_awvalid;
wire [31:0] axil_combiner_awaddr;
wire        axil_combiner_awready;
wire        axil_combiner_wvalid;
wire [31:0] axil_combiner_wdata;
wire        axil_combiner_wready;
wire        axil_combiner_bvalid;
wire  [1:0] axil_combiner_bresp;
wire        axil_combiner_bready;
wire        axil_combiner_arvalid;
wire [31:0] axil_combiner_araddr;
wire        axil_combiner_arready;
wire        axil_combiner_rvalid;
wire [31:0] axil_combiner_rdata;
wire  [1:0] axil_combiner_rresp;
wire        axil_combiner_rready;

wire        axil_p4hdr_awvalid;
wire [31:0] axil_p4hdr_awaddr;
wire        axil_p4hdr_awready;
wire        axil_p4hdr_wvalid;
wire [31:0] axil_p4hdr_wdata;
wire        axil_p4hdr_wready;
wire        axil_p4hdr_bvalid;
wire  [1:0] axil_p4hdr_bresp;
wire        axil_p4hdr_bready;
wire        axil_p4hdr_arvalid;
wire [31:0] axil_p4hdr_araddr;
wire        axil_p4hdr_arready;
wire        axil_p4hdr_rvalid;
wire [31:0] axil_p4hdr_rdata;
wire  [1:0] axil_p4hdr_rresp;
wire        axil_p4hdr_rready;

wire        axil_p4reg_awvalid;
wire [31:0] axil_p4reg_awaddr;
wire        axil_p4reg_awready;
wire        axil_p4reg_wvalid;
wire [31:0] axil_p4reg_wdata;
wire        axil_p4reg_wready;
wire        axil_p4reg_bvalid;
wire  [1:0] axil_p4reg_bresp;
wire        axil_p4reg_bready;
wire        axil_p4reg_arvalid;
wire [31:0] axil_p4reg_araddr;
wire        axil_p4reg_arready;
wire        axil_p4reg_rvalid;
wire [31:0] axil_p4reg_rdata;
wire  [1:0] axil_p4reg_rresp;
wire        axil_p4reg_rready;

wire        axil_dp_awvalid;
wire [31:0] axil_dp_awaddr;
wire        axil_dp_awready;
wire        axil_dp_wvalid;
wire [31:0] axil_dp_wdata;
wire        axil_dp_wready;
wire        axil_dp_bvalid;
wire  [1:0] axil_dp_bresp;
wire        axil_dp_bready;
wire        axil_dp_arvalid;
wire [31:0] axil_dp_araddr;
wire        axil_dp_arready;
wire        axil_dp_rvalid;
wire [31:0] axil_dp_rdata;
wire  [1:0] axil_dp_rresp;
wire        axil_dp_rready;

stream_switch_address_map address_map_inst (
  .s_axil_awvalid       (s_axil_awvalid),
  .s_axil_awaddr        (s_axil_awaddr),
  .s_axil_awready       (s_axil_awready),
  .s_axil_wvalid        (s_axil_wvalid),
  .s_axil_wdata         (s_axil_wdata),
  .s_axil_wready        (s_axil_wready),
  .s_axil_bvalid        (s_axil_bvalid),
  .s_axil_bresp         (s_axil_bresp),
  .s_axil_bready        (s_axil_bready),
  .s_axil_arvalid       (s_axil_arvalid),
  .s_axil_araddr        (s_axil_araddr),
  .s_axil_arready       (s_axil_arready),
  .s_axil_rvalid        (s_axil_rvalid),
  .s_axil_rdata         (s_axil_rdata),
  .s_axil_rresp         (s_axil_rresp),
  .s_axil_rready        (s_axil_rready),

  .m_axil_splitter_awvalid (axil_splitter_awvalid),
  .m_axil_splitter_awaddr  (axil_splitter_awaddr),
  .m_axil_splitter_awready (axil_splitter_awready),
  .m_axil_splitter_wvalid  (axil_splitter_wvalid),
  .m_axil_splitter_wdata   (axil_splitter_wdata),
  .m_axil_splitter_wready  (axil_splitter_wready),
  .m_axil_splitter_bvalid  (axil_splitter_bvalid),
  .m_axil_splitter_bresp   (axil_splitter_bresp),
  .m_axil_splitter_bready  (axil_splitter_bready),
  .m_axil_splitter_arvalid (axil_splitter_arvalid),
  .m_axil_splitter_araddr  (axil_splitter_araddr),
  .m_axil_splitter_arready (axil_splitter_arready),
  .m_axil_splitter_rvalid  (axil_splitter_rvalid),
  .m_axil_splitter_rdata   (axil_splitter_rdata),
  .m_axil_splitter_rresp   (axil_splitter_rresp),
  .m_axil_splitter_rready  (axil_splitter_rready),

  .m_axil_combiner_awvalid (axil_combiner_awvalid),
  .m_axil_combiner_awaddr  (axil_combiner_awaddr),
  .m_axil_combiner_awready (axil_combiner_awready),
  .m_axil_combiner_wvalid  (axil_combiner_wvalid),
  .m_axil_combiner_wdata   (axil_combiner_wdata),
  .m_axil_combiner_wready  (axil_combiner_wready),
  .m_axil_combiner_bvalid  (axil_combiner_bvalid),
  .m_axil_combiner_bresp   (axil_combiner_bresp),
  .m_axil_combiner_bready  (axil_combiner_bready),
  .m_axil_combiner_arvalid (axil_combiner_arvalid),
  .m_axil_combiner_araddr  (axil_combiner_araddr),
  .m_axil_combiner_arready (axil_combiner_arready),
  .m_axil_combiner_rvalid  (axil_combiner_rvalid),
  .m_axil_combiner_rdata   (axil_combiner_rdata),
  .m_axil_combiner_rresp   (axil_combiner_rresp),
  .m_axil_combiner_rready  (axil_combiner_rready),

  .m_axil_p4hdr_awvalid   (axil_p4hdr_awvalid),
  .m_axil_p4hdr_awaddr    (axil_p4hdr_awaddr),
  .m_axil_p4hdr_awready   (axil_p4hdr_awready),
  .m_axil_p4hdr_wvalid    (axil_p4hdr_wvalid),
  .m_axil_p4hdr_wdata     (axil_p4hdr_wdata),
  .m_axil_p4hdr_wready    (axil_p4hdr_wready),
  .m_axil_p4hdr_bvalid    (axil_p4hdr_bvalid),
  .m_axil_p4hdr_bresp     (axil_p4hdr_bresp),
  .m_axil_p4hdr_bready    (axil_p4hdr_bready),
  .m_axil_p4hdr_arvalid   (axil_p4hdr_arvalid),
  .m_axil_p4hdr_araddr    (axil_p4hdr_araddr),
  .m_axil_p4hdr_arready   (axil_p4hdr_arready),
  .m_axil_p4hdr_rvalid    (axil_p4hdr_rvalid),
  .m_axil_p4hdr_rdata     (axil_p4hdr_rdata),
  .m_axil_p4hdr_rresp     (axil_p4hdr_rresp),
  .m_axil_p4hdr_rready    (axil_p4hdr_rready),

  .m_axil_p4reg_awvalid   (axil_p4reg_awvalid),
  .m_axil_p4reg_awaddr    (axil_p4reg_awaddr),
  .m_axil_p4reg_awready   (axil_p4reg_awready),
  .m_axil_p4reg_wvalid    (axil_p4reg_wvalid),
  .m_axil_p4reg_wdata     (axil_p4reg_wdata),
  .m_axil_p4reg_wready    (axil_p4reg_wready),
  .m_axil_p4reg_bvalid    (axil_p4reg_bvalid),
  .m_axil_p4reg_bresp     (axil_p4reg_bresp),
  .m_axil_p4reg_bready    (axil_p4reg_bready),
  .m_axil_p4reg_arvalid   (axil_p4reg_arvalid),
  .m_axil_p4reg_araddr    (axil_p4reg_araddr),
  .m_axil_p4reg_arready   (axil_p4reg_arready),
  .m_axil_p4reg_rvalid    (axil_p4reg_rvalid),
  .m_axil_p4reg_rdata     (axil_p4reg_rdata),
  .m_axil_p4reg_rresp     (axil_p4reg_rresp),
  .m_axil_p4reg_rready    (axil_p4reg_rready),

  .m_axil_dp_awvalid   (axil_dp_awvalid),
  .m_axil_dp_awaddr    (axil_dp_awaddr),
  .m_axil_dp_awready   (axil_dp_awready),
  .m_axil_dp_wvalid    (axil_dp_wvalid),
  .m_axil_dp_wdata     (axil_dp_wdata),
  .m_axil_dp_wready    (axil_dp_wready),
  .m_axil_dp_bvalid    (axil_dp_bvalid),
  .m_axil_dp_bresp     (axil_dp_bresp),
  .m_axil_dp_bready    (axil_dp_bready),
  .m_axil_dp_arvalid   (axil_dp_arvalid),
  .m_axil_dp_araddr    (axil_dp_araddr),
  .m_axil_dp_arready   (axil_dp_arready),
  .m_axil_dp_rvalid    (axil_dp_rvalid),
  .m_axil_dp_rdata     (axil_dp_rdata),
  .m_axil_dp_rresp     (axil_dp_rresp),
  .m_axil_dp_rready    (axil_dp_rready),

  .aclk                 (axil_aclk),
  .aresetn              (axil_aresetn)
);