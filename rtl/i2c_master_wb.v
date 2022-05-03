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
	parameter integer DW = 3, // i2c_clk = sys_clk / (4 * ((1 << DW) + 1))
	parameter integer TW = 0, // Timeout (0 = no timeout)
	parameter integer CLOCK_STRETCH = 0,
	parameter integer FIFO_DEPTH = 0,
	parameter FIFO_TYPE = "shift"
)(
	// IOs
	output wire scl_oe,
	input  wire scl_i,
	output wire sda_oe,
	input  wire sda_i,

	// Wishbone
	input  wire [ 0:0] wb_addr,
	output reg  [31:0] wb_rdata,
	input  wire [31:0] wb_wdata,
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
	wire       stb;
	wire [7:0] data_out;
	wire       ack_out;
	wire       err_out;
	wire       ready;


	// Core
	// ----

	i2c_master #(
		.DW(DW),
		.TW(TW),
		.CLOCK_STRETCH(CLOCK_STRETCH)
	) core_I (
		.scl_oe   (scl_oe),
		.scl_i    (scl_i),
		.sda_oe   (sda_oe),
		.sda_i    (sda_i),
		.data_in  (data_in),
		.ack_in   (ack_in),
		.cmd      (cmd),
		.stb      (stb),
		.data_out (data_out),
		.ack_out  (ack_out),
		.err_out  (err_out),
		.ready    (ready),
		.clk      (clk),
		.rst      (rst)
	);


	// Bus interface (no buffer)
	// -------------

	if (FIFO_DEPTH == 0) begin

		// Signals
		wire       bus_clr;

		// Ack
		always @(posedge clk)
			wb_ack <= wb_cyc & ~wb_ack & (ready | ~wb_we);

		// Data read
		assign bus_clr = ~wb_cyc | wb_ack;

		always @(posedge clk)
			if (bus_clr)
				wb_rdata <= 32'h00000000;
			else
				wb_rdata <= { ready, ready, 20'd0, err_out, ack_out, data_out };

		// Data write
		assign cmd      = wb_wdata[13:12];
		assign ack_in   = wb_wdata[8];
		assign data_in  = wb_wdata[7:0];
		assign stb      = wb_ack & wb_we;

	end


	// Bus interface (FIFO)
	// -------------

	if (FIFO_DEPTH > 0) begin

		// Signals
		wire [11:0] cf_wdata;
		wire        cf_we;
		wire        cf_full;
		wire [11:0] cf_rdata;
		wire        cf_re;
		wire        cf_empty;

		wire  [9:0] rf_wdata;
		wire        rf_we;
		wire        rf_full;
		wire  [9:0] rf_rdata;
		wire        rf_re;
		wire        rf_empty;

		wire        bus_clr;
		reg         ready_r;
		reg         get_resp;

		// Ack
		always @(posedge clk)
			wb_ack <= wb_cyc & ~wb_ack & (~cf_full | ~wb_we);

		// Data read
		assign bus_clr = ~wb_cyc | wb_ack;

		always @(posedge clk)
			if (bus_clr)
				wb_rdata <= 32'h00000000;
			else
				wb_rdata <= { ~rf_empty, ~cf_full, 20'd0, rf_rdata };

		assign rf_re = wb_ack & ~wb_we & wb_rdata[31] & ~wb_addr[0];

		// Data write
		assign cf_wdata = {
			wb_wdata[13:12],	// [11:10] cmd
			wb_wdata[15],		//     [9] get-resp
			wb_wdata[8],		//     [8] ack-in
			wb_wdata[7:0]		//   [7:0] data
		};
		assign cf_we = wb_ack & wb_we;

		// Commands
		assign cmd      = cf_rdata[11:10];
		assign ack_in   = cf_rdata[8];
		assign data_in  = cf_rdata[7:0];
		assign stb      = ~cf_empty & ~rf_full & ready & ready_r;

		assign cf_re = stb;

		always @(posedge clk)
			if (cf_re)
				get_resp <= cf_rdata[9];

		// Responses
		assign rf_wdata = {
			err_out,
			ack_out,
			data_out
		};
		assign rf_we = ready & ~ready_r & get_resp;

		// Misc
		always @(posedge clk)
			ready_r <= ready;

		// FIFO
		if (FIFO_TYPE == "shift") begin

			// Command FIFO
			fifo_sync_shift #(
				.DEPTH(FIFO_DEPTH),
				.WIDTH(12)
			) fifo_cmd_I (
				.wr_data  (cf_wdata),
				.wr_ena   (cf_we),
				.wr_full  (cf_full),
				.rd_data  (cf_rdata),
				.rd_ena   (cf_re),
				.rd_empty (cf_empty),
				.clk      (clk),
				.rst      (rst)
			);

			// Response FIFO
			fifo_sync_shift #(
				.DEPTH(FIFO_DEPTH),
				.WIDTH(10)
			) fifo_rsp_I (
				.wr_data  (rf_wdata),
				.wr_ena   (rf_we),
				.wr_full  (rf_full),
				.rd_data  (rf_rdata),
				.rd_ena   (rf_re),
				.rd_empty (rf_empty),
				.clk      (clk),
				.rst      (rst)
			);

		end

		if (FIFO_TYPE == "ram") begin

			// Command FIFO
			fifo_sync_ram #(
				.DEPTH(FIFO_DEPTH),
				.WIDTH(12)
			) fifo_cmd_I (
				.wr_data  (cf_wdata),
				.wr_ena   (cf_we),
				.wr_full  (cf_full),
				.rd_data  (cf_rdata),
				.rd_ena   (cf_re),
				.rd_empty (cf_empty),
				.clk      (clk),
				.rst      (rst)
			);

			// Response FIFO
			fifo_sync_ram #(
				.DEPTH(FIFO_DEPTH),
				.WIDTH(10)
			) fifo_rsp_I (
				.wr_data  (rf_wdata),
				.wr_ena   (rf_we),
				.wr_full  (rf_full),
				.rd_data  (rf_rdata),
				.rd_ena   (rf_re),
				.rd_empty (rf_empty),
				.clk      (clk),
				.rst      (rst)
			);

		end

	end

endmodule // i2c_master_wb
