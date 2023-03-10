`include "open_nic_shell_macros.vh"
`timescale 1ns/1ps
module p4_hdr_register (
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

  output reg [47:0] smac,
  output reg [47:0] dmac,
  output reg [31:0] sip,
  output reg [31:0] dip,
  output reg [15:0] sport,
  output reg [15:0] dport,
  output reg [15:0] ipsum
);

  localparam REG_SMAC_LOW  = 12'h000;
  localparam REG_SMAC_HIGH = 12'h004;
  localparam REG_DMAC_LOW  = 12'h008;
  localparam REG_DMAC_HIGH = 12'h00C;
  localparam REG_SIP       = 12'h010;
  localparam REG_DIP       = 12'h014;
  localparam REG_SPORT     = 12'h018;
  localparam REG_DPORT     = 12'h01C;
  localparam REG_IPSUM     = 12'h020;

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

  always @(posedge axil_aclk) begin
    if(~axil_aresetn) begin
      // set default values
      smac <= 48'b0;
      dmac <= 48'b0;
      sip <= 32'b0;
      dip <= 32'b0;
      sport <= 16'b0;
      dport <= 16'b0;
      ipsum <= 16'b0;
    end

    else if (reg_en && reg_we) begin
      // write to registers using reg_din
      case (reg_addr)
        REG_SMAC_LOW: begin
          smac[31:0] <= reg_din[31:0];
        end
        REG_SMAC_HIGH: begin
          smac[47:32] <= reg_din[15:0];
        end
        REG_DMAC_LOW: begin
          dmac[31:0] <= reg_din[31:0];
        end
        REG_DMAC_HIGH: begin
          dmac[47:32] <= reg_din[15:0];
        end
        REG_SIP: begin
          sip <= reg_din[31:0];
        end
        REG_DIP: begin
          dip <= reg_din[31:0];
        end
        REG_SPORT: begin
          sport <= reg_din[15:0];
        end
        REG_DPORT: begin
          dport <= reg_din[15:0];
        end
        REG_IPSUM: begin
          ipsum <= reg_din[15:0];
        end
      endcase
    end

    else if (reg_en && ~reg_we) begin
      // read into reg_dout
      case (reg_addr)
        REG_SMAC_LOW: begin
          reg_dout[31:0] <= smac[31:0];
        end
        REG_SMAC_HIGH: begin
          reg_dout[15:0] <= smac[47:32];
          reg_dout[31:16] <= 16'b0;
        end
        REG_DMAC_LOW: begin
          reg_dout[31:0] <= dmac[31:0];
        end
        REG_DMAC_HIGH: begin
          reg_dout[15:0] <= dmac[47:32];
          reg_dout[31:16] <= 16'b0;
        end
        REG_SIP: begin
          reg_dout[31:0] <= sip;
        end
        REG_DIP: begin
          reg_dout[31:0] <= dip;
        end
        REG_SPORT: begin
          reg_dout[15:0] <= sport;
          reg_dout[31:16] <= 16'b0;
        end
        REG_DPORT: begin
          reg_dout[15:0] <= dport;
          reg_dout[31:16] <= 16'b0;
        end
        REG_IPSUM: begin
          reg_dout[15:0] <= ipsum;
          reg_dout[31:16] <= 16'b0;
        end
      endcase
    end
  end

endmodule: p4_hdr_register