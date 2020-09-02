/*
 * pdm_tb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none
`timescale 1ns / 100ps

module pdm_tb;

	// Signals
	reg rst = 1;
	reg clk = 1;

	reg [7:0] data;
	wire pdm;

	// Setup recording
	initial begin
		$dumpfile("pdm_tb.vcd");
		$dumpvars(0,pdm_tb);
	end

	// Reset pulse
	initial begin
		# 31 rst = 0;
		# 20000 $finish;
	end

	// Clocks
	always #5 clk = !clk;

	// DUT
	pdm #(
		.WIDTH(12),
		.DITHER("ON"),
		.PHY("ICE40")
	) dut_I (
		.pdm(pdm),
		.cfg_val({data[7:4],data}),
		.cfg_oe(1'b1),
		.clk(clk),
		.rst(rst)
	);

	initial begin
		#0		data <= 8'hc1;
		#5000	data <= 8'h10;
		#5000	data <= 8'hf0;
		#5000	data <= 8'h80;
	end

endmodule // pdm_tb
