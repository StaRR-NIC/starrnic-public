`resetall
`timescale 1ns / 1ps
`default_nettype none

module demux_control # (
  parameter M_COUNT = 2,
  parameter CL_M_COUNT = $clog2(M_COUNT)
) (
  input         s_axil_awvalid,
  input  [31:0] s_axil_awaddr,
  output        s_axil_awready,
  input         s_axil_wvalid,
  input  [31:0] s_axil_wdata,
  input   [3:0] s_axil_wstrb, // Dummy, only used for sim.
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

  input         axil_aclk,
  input         axil_aresetn,

  output reg [CL_M_COUNT-1:0] select_committed
);

  reg commit_reg;
  reg [CL_M_COUNT-1:0] select_reg;

  localparam REG_COMMIT = 12'h000;
  localparam REG_SELECT = 12'h004;

  localparam C_ADDR_W = 12;
  wire                reg_en;
  wire                reg_we;
  wire [C_ADDR_W-1:0] reg_addr;
  wire         [31:0] reg_din;
  reg          [31:0] reg_dout;

  axi_lite_register #(
    .CLOCKING_MODE ("common_clock"),
    .ADDR_W        (C_ADDR_W),
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
    .reg_clk        (axil_aclk),
    .reg_rstn       (axil_aresetn)
  );

  // Committing logic
  always @(posedge axil_aclk) begin
    if(commit_reg) begin
      commit_reg <= 1'b0;
      select_committed <= select_reg;
    end
  end

  // Register read/write
  always @(posedge axil_aclk) begin
    if(~axil_aresetn) begin
      // set default values
      select_reg <= {CL_M_COUNT{1'b0}};
      commit_reg <= 1'b0;
    end

    else if (reg_en && reg_we) begin
      // write to registers using reg_din
      case (reg_addr)
        REG_COMMIT: begin
          commit_reg <= reg_din[0];
        end
        REG_SELECT: begin
          select_reg <= reg_din[CL_M_COUNT-1:0];
        end
      endcase
    end

    else if (reg_en && ~reg_we) begin
      // read into reg_dout
      case (reg_addr)
        REG_COMMIT: begin
          reg_dout[0] <= commit_reg;
        end
        REG_SELECT: begin
          reg_dout[CL_M_COUNT-1:0] <= select_reg;
        end
      endcase
    end
  end

endmodule

`resetall