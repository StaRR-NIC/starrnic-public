`resetall
`timescale 1ns / 1ps
`default_nettype none

module demux_control # (
  parameter M_COUNT = 2,
  parameter CL_M_COUNT = $clog2(M_COUNT)
) (
  input  wire        s_axil_awvalid,
  input  wire [7:0] s_axil_awaddr,
  output wire        s_axil_awready,
  input  wire        s_axil_wvalid,
  input  wire [31:0] s_axil_wdata,
  output wire        s_axil_wready,
  output wire        s_axil_bvalid,
  output wire  [1:0] s_axil_bresp,
  input  wire        s_axil_bready,
  input  wire        s_axil_arvalid,
  input  wire [7:0] s_axil_araddr,
  output wire        s_axil_arready,
  output wire        s_axil_rvalid,
  output wire [31:0] s_axil_rdata,
  output wire  [1:0] s_axil_rresp,
  input  wire        s_axil_rready,

  input  wire        axil_aclk,
  input  wire        axil_aresetn,

  output reg [CL_M_COUNT-1:0] select_committed,
  output reg disable_rm_committed
);

  reg commit_reg;
  reg [CL_M_COUNT-1:0] select_reg;
  reg disable_rm_reg;

  localparam REG_COMMIT = 8'h00;
  localparam REG_SELECT = 8'h04;
  localparam REG_DISABLE_RM = 8'h08;

  localparam C_ADDR_W = 8;
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
      commit_reg <= 1'b0;

      select_reg <= {CL_M_COUNT{1'b0}};
      disable_rm_reg <= 1'b0;

      select_committed <= {CL_M_COUNT{1'b0}};
      disable_rm_committed <= 1'b0;
    end

    else if (commit_reg) begin
      // else if => no commit during reset
      commit_reg <= 1'b0;
      select_committed <= select_reg;
      disable_rm_committed <= disable_rm_reg;
    end

    else if (reg_en && reg_we) begin
      // else if => no reg write during commit or reset
      // write to registers using reg_din
      case (reg_addr)
        REG_COMMIT: begin
          commit_reg <= reg_din[0];
        end
        REG_SELECT: begin
          select_reg <= reg_din[CL_M_COUNT-1:0];
        end
        REG_DISABLE_RM: begin
          disable_rm_reg <= reg_din[0];
        end
      endcase
    end

    if (reg_en && ~reg_we) begin
      // reg reads can occur always (independent of commit/reset/write)
      // read into reg_dout
      case (reg_addr)
        REG_COMMIT: begin
          reg_dout[0] <= commit_reg;
          reg_dout[31:1] <= 31'b0;
        end
        REG_SELECT: begin
          reg_dout[CL_M_COUNT-1:0] <= select_reg;
          reg_dout[31:CL_M_COUNT] <= {(31-CL_M_COUNT+1){1'b0}};
        end
        REG_DISABLE_RM: begin
          reg_dout[0] <= disable_rm_reg;
          reg_dout[31:1] <= 31'b0;
        end
      endcase
    end
  end

endmodule

`resetall