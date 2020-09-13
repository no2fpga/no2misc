/*
 * xclk_wb.v
 *
 * vim: ts=4 sw=4
 *
 * Cross-clock domain helper for wishbone requests.
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module xclk_wb #(
	parameter integer DW = 16,
	parameter integer AW = 16
)(
	// Slave bus interface
	input  wire [AW-1:0] s_addr,
	output reg  [DW-1:0] s_rdata,
	input  wire [DW-1:0] s_wdata,
	input  wire          s_we,
	input  wire          s_cyc,
	output wire          s_ack,
	input  wire          s_clk,

	// Master bus interface
	output wire [AW-1:0] m_addr,
	input  wire [DW-1:0] m_rdata,
	output wire [DW-1:0] m_wdata,
	output wire          m_we,
	output wire          m_cyc,
	input  wire          m_ack,
	input  wire          m_clk,

	// Reset
	input  wire rst
);

	// Signals
	// -------

	reg  s_cyc_d;
	reg  m_cyc_i;

	wire s_req_i;
	wire m_req_i;

	wire s_ack_i;
	reg  s_ack_d;
	reg  m_ack_i;

	reg [DW-1:0] m_rdata_i;


	// Data and address
	// ----------------

		// These will have settled down for some time while we pass around
		// the handshake signals, so we can just connect them
		// Ideally we'd still need a maxdelay constraint between clock domains

	assign m_addr = s_addr;
	assign m_wdata  = s_wdata;
	assign m_we   = s_we;

		// Still need to capture data during ack
	always @(posedge m_clk)
		if (m_ack)
			m_rdata_i <= m_rdata;

		// ... and ensure its zero cycle-accurately
	always @(posedge s_clk)
		if (s_ack_i || ~s_cyc)
			s_rdata <= 0;
		else
			s_rdata <= m_rdata_i;


	// Handshake
	// ---------

	always @(posedge s_clk)
	begin
		s_cyc_d <= s_cyc;
		s_ack_d <= s_ack_i;
	end

	assign s_req_i = s_cyc & (~s_cyc_d | s_ack_d);

	xclk_strobe xclk_req (
		.in_stb(s_req_i),
		.in_clk(s_clk),
		.out_stb(m_req_i),
		.out_clk(m_clk),
		.rst(rst)
	);

	always @(posedge m_clk or posedge rst)
		if (rst)
			m_cyc_i <= 1'b0;
		else
			m_cyc_i <= (m_cyc_i | m_req_i) & ~m_ack;

	assign m_cyc = m_cyc_i;

	xclk_strobe xclk_ack (
		.in_stb(m_ack),
		.in_clk(m_clk),
		.out_stb(s_ack_i),
		.out_clk(s_clk),
		.rst(rst)
	);

	assign s_ack = s_ack_i;

endmodule
