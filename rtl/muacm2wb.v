/*
 * muacm2wb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module muacm2wb #(
	parameter integer WB_N = 3,

	// auto
	parameter integer DL = (32*WB_N)-1,
	parameter integer CL = WB_N-1
)(
	// USB
	inout  wire        usb_dp,
	inout  wire        usb_dn,
	output wire        usb_pu,

	input  wire        usb_clk,
	input  wire        usb_rst,

	// Wishbone
	output reg  [31:0] wb_wdata,
	input  wire [DL:0] wb_rdata,
	output reg  [15:0] wb_addr,
	output reg         wb_we,
	output reg  [CL:0] wb_cyc,
	input  wire [CL:0] wb_ack,

	// Aux-CSR
	output reg  [31:0] aux_csr,

	// Misc
	output reg         bootloader,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	// Input (to host) - USB domain
	wire [7:0] iu_data;
	wire       iu_last;
	wire       iu_valid;
	wire       iu_ready;
	wire       iu_flush_now;
	wire       iu_flush_time;

	// Output (from host) - USB domain
	wire [7:0] ou_data;
	wire       ou_last;
	wire       ou_valid;
	wire       ou_ready;

	// Input (to host) - System domain
	wire [7:0] is_data;
	wire       is_last;
	wire       is_valid;
	wire       is_ready;

	// Output (from host) - System domain
	wire [7:0] os_data;
	wire       os_last;
	wire       os_valid;
	wire       os_ready;

	// Bootloader request
	wire       bootloader_stb;


	// muACM core
	// ----------

	muacm acm_I (
		.usb_dp        (usb_dp),
		.usb_dn        (usb_dn),
		.usb_pu        (usb_pu),
		.in_data       (iu_data),
		.in_last       (iu_last),
		.in_valid      (iu_valid),
		.in_ready      (iu_ready),
		.in_flush_now  (iu_flush_now),
		.in_flush_time (iu_flush_time),
		.out_data      (ou_data),
		.out_last      (ou_last),
		.out_valid     (ou_valid ),
		.out_ready     (ou_ready ),
		.bootloader    (bootloader_stb),
		.clk           (usb_clk),
		.rst           (usb_rst)
	);

	assign iu_flush_now  = 1'b0;
	assign iu_flush_time = 1'b1;


	// Cross to system clock domain
	// ----------------------------

	muacm_xclk xclk_out_I (
		.i_data  (ou_data),
		.i_last  (ou_last),
		.i_valid (ou_valid),
		.i_ready (ou_ready),
		.i_clk   (usb_clk),
		.o_data  (os_data),
		.o_last  (os_last),
		.o_valid (os_valid),
		.o_ready (os_ready),
		.o_clk   (clk),
		.rst     (rst)
	);

	muacm_xclk xclk_in_I (
		.i_data  (is_data),
		.i_last  (is_last),
		.i_valid (is_valid),
		.i_ready (is_ready),
		.i_clk   (clk),
		.o_data  (iu_data),
		.o_last  (iu_last),
		.o_valid (iu_valid),
		.o_ready (iu_ready),
		.o_clk   (usb_clk),
		.rst     (rst)
	);


	// Wishbone bridge
	// ---------------

	stream2wb #(
		.WB_N(WB_N)
	) wb_I (
		.rx_data  (os_data),
		.rx_valid (os_valid),
		.rx_ready (os_ready),
		.tx_data  (is_data),
		.tx_last  (is_last),	// FIXME: Check for pipelined commands
		.tx_valid (is_valid),
		.tx_ready (is_ready),
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


	// Bootloader
	// ----------

	always @(posedge usb_clk or posedge usb_rst)
		if (usb_rst)
			bootloader <= 1'b0;
		else
			bootloader <= bootloader | bootloader_stb;

endmodule // muacm2wb
