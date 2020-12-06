/*
 * fifo_tb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none
`timescale 1ns / 100ps

module fifo_tb;

	// Signals
	reg rst = 1'b1;
	reg clk = 1'b0;

	wire [7:0] wr_data;
	wire wr_ena;
	wire wr_full;

	wire [7:0] rd_data;
	wire rd_ena;
	wire rd_empty;

	// Setup recording
	initial begin
		$dumpfile("fifo_tb.vcd");
		$dumpvars(0,fifo_tb);
	end

	// Reset pulse
	initial begin
		# 200 rst = 0;
		# 1000000 $finish;
	end

	// Clocks
	always #10 clk = !clk;

	// DUT
//	fifo_sync_shift #(
	fifo_sync_ram #(
		.DEPTH(4),
		.WIDTH(8)
	) dut_I (
		.wr_data(wr_data),
		.wr_ena(wr_ena),
		.wr_full(wr_full),
		.rd_data(rd_data),
		.rd_ena(rd_ena),
		.rd_empty(rd_empty),
		.clk(clk),
		.rst(rst)
	);

	// Data generateion
	reg [7:0] cnt;
	reg rnd_rd;
	reg rnd_wr;

	always @(posedge clk)
		if (rst) begin
			cnt <= 8'h00;
			rnd_rd <= 1'b0;
			rnd_wr <= 1'b0;
		end else begin
			cnt <= cnt + wr_ena;
			rnd_rd <= $random;
			rnd_wr <= $random;
		end

	assign wr_data = wr_ena ? cnt : 8'hxx;
	assign wr_ena = rnd_wr & ~wr_full;
	assign rd_ena = rnd_rd & ~rd_empty;

	// Verify
	reg [7:0] cmp_val;

	always @(posedge clk)
		if (rst) begin
			cmp_val <= 8'h00;
		end else begin
			cmp_val <= cmp_val + rd_ena;

			if (~rd_empty & (rd_data != cmp_val))
				$display("Errori @ %t", $time);
		end

endmodule // fifo_tb
