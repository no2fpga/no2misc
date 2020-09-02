/*
 * uart_tb.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none
`timescale 1ns / 100ps

module uart_tb;

	// Signals
	reg rst = 1'b1;
	reg clk_rx = 1'b0;
	reg clk_tx = 1'b0;

	wire serial;

	reg  [7:0] tx_data;
	wire tx_valid;
	wire tx_ack;

	wire [7:0] rx_data;
	wire rx_stb;

	// Setup recording
	initial begin
		$dumpfile("uart_tb.vcd");
		$dumpvars(0,uart_tb);
	end

	// Reset pulse
	initial begin
		# 200 rst = 0;
		# 1000000 $finish;
	end

	// Clocks
	always #10.4 clk_rx = !clk_rx;
	always #10.0 clk_tx = !clk_tx;

	// DUT
	uart_tx #(
		.DIV_WIDTH(4)
	) dut_tx_I (
		.tx(serial),
		.data(tx_data),
		.valid(tx_valid),
		.ack(tx_ack),
		.div(4'h3),
		.clk(clk_tx),
		.rst(rst)
	);

	uart_rx #(
		.DIV_WIDTH(4),
		.GLITCH_FILTER(2)
	) dut_rx_I (
		.rx(serial),
		.data(rx_data),
		.stb(rx_stb),
		.div(4'h3),
		.clk(clk_rx),
		.rst(rst)
	);

	always @(posedge clk_tx)
		if (rst)
			tx_data <= 8'h00;
		else if (tx_ack)
			tx_data <= tx_data + 1;

	assign tx_valid = ~rst;

endmodule // uart_tb
