module axi_lite_slave_wrapper (
    input                     s_axil_awvalid,
    input              [31:0] s_axil_awaddr,
    output                    s_axil_awready,
    input                     s_axil_wvalid,
    input              [31:0] s_axil_wdata,
    input               [3:0] s_axil_wstrb, // Dummy, only used for sim.
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

    input                     axil_aresetn,
    input                     axil_aclk
);

axi_lite_slave #(
    .REG_ADDR_W (12),
    .REG_PREFIX (16'h0000)
) inst (
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

    .aclk           (axil_aclk),
    .aresetn        (axil_aresetn)
);

endmodule: axi_lite_slave_wrapper