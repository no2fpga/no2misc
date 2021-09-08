/*
 * i2c_master_wb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module i2c_master_wb #(
	parameter integer DW = 3
)(
	// IOs
	output wire scl_oe,
	output wire sda_oe,
	input  wire sda_i,

	// Wishbone
	input  wire [31:0] wb_wdata,
	output reg  [31:0] wb_rdata,
	input  wire        wb_we,
	input  wire        wb_cyc,
	output reg         wb_ack,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	wire [7:0] data_in;
	wire       ack_in;
	wire [1:0] cmd;
	reg        stb;
	wire [7:0] data_out;
	wire       ack_out;
	wire       ready;

	wire       bus_clr;


	// Core
	// ----

	i2c_master #(
		.DW(DW)
	) core_I (
		.scl_oe   (scl_oe),
		.sda_oe   (sda_oe),
		.sda_i    (sda_i),
		.data_in  (data_in),
		.ack_in   (ack_in),
		.cmd      (cmd),
		.stb      (stb),
		.data_out (data_out),
		.ack_out  (ack_out),
		.ready    (ready),
		.clk      (clk),
		.rst      (rst)
	);


	// Bus interface
	// -------------

	// Ack
	always @(posedge clk)
		wb_ack <= wb_cyc & ~wb_ack;

	// Data read
	assign bus_clr = ~wb_cyc | wb_ack;

	always @(posedge clk)
		if (bus_clr)
			wb_rdata <= 32'h00000000;
		else
			wb_rdata <= { ready, 22'd0, ack_out, data_out };

	// Data write
	assign cmd      = wb_wdata[13:12];
	assign ack_in   = wb_wdata[8];
	assign data_in  = wb_wdata[7:0];

	always @(posedge clk)
		stb <= wb_cyc & wb_we & ~wb_ack;

endmodule // i2c_master_wb
