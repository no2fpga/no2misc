/*
 * pwm.v
 *
 * vim: ts=4 sw=4
 *
 * Pulse Width Modulation core
 * This maps val=0            to OFF /   0%
 *           val=(1<<WIDTH)-1 to  ON / 100%
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module pwm #(
	parameter integer WIDTH = 10,
	parameter PHY = "GENERIC"
)(
	// PWM out
	output wire pwm,

	// Config
	input  wire [WIDTH-1:0] cfg_val,
	input  wire cfg_oe,

	// Clock / Reset
	input  wire  clk,
	input  wire  rst
);
	// Signals
	wire [WIDTH:0] cnt_cycle_rst;
	reg  [WIDTH:0] cnt_cycle;
	reg  [WIDTH:0] cnt_on;
	wire pwm_i;

	// Cycle counter (counts 2^WIDTH - 1 cycles)
	assign cnt_cycle_rst = { { (WIDTH-1){1'b0} }, 2'b10 };

	always @(posedge clk or posedge rst)
		if (rst)
			cnt_cycle <= cnt_cycle_rst;
		else
			cnt_cycle <= cnt_cycle[WIDTH] ? cnt_cycle_rst : (cnt_cycle + 1);

	// ON counter (counts cycles with output high)
	always @(posedge clk or posedge rst)
		if (rst)
			cnt_on <= 0;
		else
			cnt_on <= cnt_cycle[WIDTH] ? { 1'b1, cfg_val } : (cnt_on - 1);

	assign pwm_i = cnt_on[WIDTH];

	// PHY (Basically just IO register)
	generate
		if (PHY == "NONE") begin
			// No PHY (and no OE support)
			assign pwm = pwm_i;
		end else if (PHY == "GENERIC") begin
			// Generic IO register, let tool figure it out
			reg pwm_d_r;
			reg pwm_oe_r;
			always @(posedge clk)
			begin
				pwm_d_r  <= pwm_i;
				pwm_oe_r <= cfg_oe;
			end
			assign pwm = pwm_oe_r ? pwm_d_r : 1'bz;
		end else if (PHY == "ICE40") begin
			// iCE40 specific IOB
			SB_IO #(
				.PIN_TYPE(6'b110100),
				.PULLUP(1'b0),
				.NEG_TRIGGER(1'b0),
				.IO_STANDARD("SB_LVCMOS")
			) io_reg_I (
				.PACKAGE_PIN(pwm),
				.CLOCK_ENABLE(1'b1),
				.INPUT_CLK(1'b0),
				.OUTPUT_CLK(clk),
				.OUTPUT_ENABLE(cfg_oe),
				.D_OUT_0(pwm_i),
				.D_OUT_1(1'b0),
				.D_IN_0(),
				.D_IN_1()
			);
		end
	endgenerate

endmodule // pwm
