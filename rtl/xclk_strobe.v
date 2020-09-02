/*
 * xclk_strobe.v
 *
 * vim: ts=4 sw=4
 *
 * Cross-clock domain helper for strobes.
 *
 * Strobe interval _has_ to be much longer than several of the slowest
 * clock !
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module xclk_strobe (
	input  wire in_stb,
	input  wire in_clk,
	output reg  out_stb,
	input  wire out_clk,
	input  wire rst
);

	reg src;
	reg [1:0] dst;

	always @(posedge in_clk or posedge rst)
		if (rst)
			src <= 1'b0;
		else
			src <= src ^ in_stb;

	always @(posedge out_clk or posedge rst)
		if (rst)
			dst <= 2'b00;
		else
			dst <= { dst[0], src };

	always @(posedge out_clk or posedge rst)
		if (rst)
			out_stb <= 1'b0;
		else
			out_stb <= ^dst[1:0];

endmodule
