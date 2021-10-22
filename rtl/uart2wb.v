/*
 * uart2wb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module uart2wb #(
	parameter integer WB_N = 3,
	parameter integer UART_DIV = 24, /* round(sys_clk / baud_rate) */

	// auto
	parameter integer DL = (32*WB_N)-1,
	parameter integer CL = WB_N-1
)(
	// UART
	input  wire        uart_rx,
	output wire        uart_tx,

	// Wishbone
	output reg  [31:0] wb_wdata,
	input  wire [DL:0] wb_rdata,
	output reg  [15:0] wb_addr,
	output reg         wb_we,
	output reg  [CL:0] wb_cyc,
	input  wire	[CL:0] wb_ack,

	// Aux-CSR
	output reg  [31:0] aux_csr,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	localparam integer DIV_WIDTH = $clog2(UART_DIV - 1);
	localparam [DIV_WIDTH-1:0] DIV_VALUE = UART_DIV - 2;

	// Signals
	// -------

	// UART serdes
	wire [7:0] rx_data;
	wire       rx_stb;

	wire [7:0] tx_data;
	wire       tx_ack;
	wire       tx_valid;


	// UART module
	// -----------

	uart_rx #(
		.DIV_WIDTH(DIV_WIDTH),
		.GLITCH_FILTER(0)
	) rx_I (
		.rx   (uart_rx),
		.data (rx_data),
		.stb  (rx_stb),
		.div  (DIV_VALUE),
		.clk  (clk),
		.rst  (rst)
	);

	uart_tx #(
		.DIV_WIDTH(DIV_WIDTH)
	) tx_I (
		.tx    (uart_tx),
		.data  (tx_data),
		.valid (tx_valid),
		.ack   (tx_ack),
		.div   (DIV_VALUE),
		.clk   (clk),
		.rst   (rst)
	);


	// Wishbone bridge
	// ---------------

	stream2wb #(
		.WB_N(WB_N)
	) wb_I (
		.rx_data  (rx_data),
		.rx_valid (rx_stb),
		.rx_ready (),
		.tx_data  (tx_data),
		.tx_last  (),
		.tx_valid (tx_valid),
		.tx_ready (tx_ack),
		.wb_wdata (wb_wdata),
		.wb_rdata (wb_rdata),
		.wb_addr  (wb_addr),
		.wb_we    (wb_we),
		.wb_cyc   (wb_cyc),
		.wb_ack   (wb_ack),
		.aux_csr  (aux_csr),
		.clk      (clk),
		.rst      (rst)
	);

endmodule
