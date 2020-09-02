/*
 * prims.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2020  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none


module lut4_n #(
	parameter [15:0] LUT_INIT = 0,
	parameter integer WIDTH  = 16,
	parameter integer RBEL_X = 0,
	parameter integer RBEL_Y = 0,
	parameter integer RBEL_Z = 0,
	parameter RBEL_GROUP = ""
)(
	input  wire [WIDTH-1:0] i0,
	input  wire [WIDTH-1:0] i1,
	input  wire [WIDTH-1:0] i2,
	input  wire [WIDTH-1:0] i3,
	output wire [WIDTH-1:0] o
);

	genvar i;
	generate
		for (i=0; i<WIDTH; i=i+1)
		begin : bit
			(* RBEL_X=RBEL_X *)
			(* RBEL_Y=RBEL_Y+(RBEL_Z+i)>>3 *)
			(* RBEL_Z=(RBEL_Z+i)&7 *)
			(* RBEL_GROUP=RBEL_GROUP *)
			SB_LUT4 #(
				.LUT_INIT(LUT_INIT)
			) lut_I (
				.I0(i0[i]),
				.I1(i1[i]),
				.I2(i2[i]),
				.I3(i3[i]),
				.O(o[i])
			);
		end
	endgenerate

endmodule // lut4_n


module lut4_carry_n #(
	parameter [15:0] LUT_INIT = 0,
	parameter integer WIDTH  = 16,
	parameter integer RBEL_X = 0,
	parameter integer RBEL_Y = 0,
	parameter integer RBEL_Z = 0,
	parameter RBEL_GROUP = ""
)(
	input  wire [WIDTH-1:0] i0,
	input  wire [WIDTH-1:0] i1,
	input  wire [WIDTH-1:0] i2,
	input  wire cin,
	output wire [WIDTH-1:0] o,
	output wire cout
);

	wire [WIDTH:0] carry;

	assign cout = carry[WIDTH];
	assign carry[0] = cin;

	genvar i;
	generate
		for (i=0; i<WIDTH; i=i+1)
		begin : bit
			(* RBEL_X=RBEL_X *)
			(* RBEL_Y=RBEL_Y+(RBEL_Z+i)>>3 *)
			(* RBEL_Z=(RBEL_Z+i)&7 *)
			(* RBEL_GROUP=RBEL_GROUP *)
			SB_LUT4 #(
				.LUT_INIT(LUT_INIT)
			) lut_I (
				.I0(i0[i]),
				.I1(i1[i]),
				.I2(i2[i]),
				.I3(carry[i]),
				.O(o[i])
			);

			SB_CARRY carry_I (
				.CO(carry[i+1]),
				.I0(i0[i]),
				.I1(i1[i]),
				.CI(carry[i])
			);
		end
	endgenerate

endmodule // lut4_carry_n


module dff_n #(
	parameter integer WIDTH  = 16,
	parameter integer RBEL_X = 0,
	parameter integer RBEL_Y = 0,
	parameter integer RBEL_Z = 0,
	parameter RBEL_GROUP = ""
)(
	input  wire [WIDTH-1:0] d,
	output wire [WIDTH-1:0] q,
	input  wire clk
);

	genvar i;
	generate
		for (i=0; i<WIDTH; i=i+1)
		begin : bit
			(* RBEL_X=RBEL_X *)
			(* RBEL_Y=RBEL_Y+(RBEL_Z+i)>>3 *)
			(* RBEL_Z=(RBEL_Z+i)&7 *)
			(* RBEL_GROUP=RBEL_GROUP *)
			(* dont_touch="true" *)
			SB_DFF dff_I (
				.D(d[i]),
				.Q(q[i]),
				.C(clk)
			);
		end
	endgenerate

endmodule // dff_n


module dffe_n #(
	parameter integer WIDTH  = 16,
	parameter integer RBEL_X = 0,
	parameter integer RBEL_Y = 0,
	parameter integer RBEL_Z = 0,
	parameter RBEL_GROUP = ""
)(
	input  wire [WIDTH-1:0] d,
	output wire [WIDTH-1:0] q,
	input  wire ce,
	input  wire clk
);

	genvar i;
	generate
		for (i=0; i<WIDTH; i=i+1)
		begin : bit
			(* RBEL_X=RBEL_X *)
			(* RBEL_Y=RBEL_Y+((RBEL_Z+i)>>3) *)
			(* RBEL_Z=(RBEL_Z+i)&7 *)
			(* RBEL_GROUP=RBEL_GROUP *)
			(* dont_touch="true" *)
			SB_DFFE dff_I (
				.D(d[i]),
				.Q(q[i]),
				.E(ce),
				.C(clk)
			);
		end
	endgenerate

endmodule // dffe_n


module dffer_n #(
	parameter RSTVAL = 16'h0000,
	parameter integer WIDTH  = 16,
	parameter integer RBEL_X = 0,
	parameter integer RBEL_Y = 0,
	parameter integer RBEL_Z = 0,
	parameter RBEL_GROUP = ""
)(
	input  wire [WIDTH-1:0] d,
	output wire [WIDTH-1:0] q,
	input  wire ce,
	input  wire clk,
	input  wire rst
);

	genvar i;
	generate
		for (i=0; i<WIDTH; i=i+1)
		begin : bit
			if (RSTVAL[i] == 1'b1)
				(* RBEL_X=RBEL_X *)
				(* RBEL_Y=RBEL_Y+((RBEL_Z+i)>>3) *)
				(* RBEL_Z=(RBEL_Z+i)&7 *)
				(* RBEL_GROUP=RBEL_GROUP *)
				(* dont_touch="true" *)
				SB_DFFES dff_I (
					.D(d[i]),
					.Q(q[i]),
					.E(ce),
					.S(rst),
					.C(clk)
				);
			else
				(* RBEL_X=RBEL_X *)
				(* RBEL_Y=RBEL_Y+((RBEL_Z+i)>>3) *)
				(* RBEL_Z=(RBEL_Z+i)&7 *)
				(* RBEL_GROUP=RBEL_GROUP *)
				(* dont_touch="true" *)
				SB_DFFER dff_I (
					.D(d[i]),
					.Q(q[i]),
					.E(ce),
					.R(rst),
					.C(clk)
				);
		end
	endgenerate

endmodule // dffer_n


module dffesr_n #(
	parameter RSTVAL = 16'h0000,
	parameter integer WIDTH  = 16,
	parameter integer RBEL_X = 0,
	parameter integer RBEL_Y = 0,
	parameter integer RBEL_Z = 0,
	parameter RBEL_GROUP = ""
)(
	input  wire [WIDTH-1:0] d,
	output wire [WIDTH-1:0] q,
	input  wire ce,
	input  wire clk,
	input  wire rst
);

	genvar i;
	generate
		for (i=0; i<WIDTH; i=i+1)
		begin : bit
			if (RSTVAL[i] == 1'b1)
				(* RBEL_X=RBEL_X *)
				(* RBEL_Y=RBEL_Y+((RBEL_Z+i)>>3) *)
				(* RBEL_Z=(RBEL_Z+i)&7 *)
				(* RBEL_GROUP=RBEL_GROUP *)
				(* dont_touch="true" *)
				SB_DFFESS dff_I (
					.D(d[i]),
					.Q(q[i]),
					.E(ce),
					.S(rst),
					.C(clk)
				);
			else
				(* RBEL_X=RBEL_X *)
				(* RBEL_Y=RBEL_Y+((RBEL_Z+i)>>3) *)
				(* RBEL_Z=(RBEL_Z+i)&7 *)
				(* RBEL_GROUP=RBEL_GROUP *)
				(* dont_touch="true" *)
				SB_DFFESR dff_I (
					.D(d[i]),
					.Q(q[i]),
					.E(ce),
					.R(rst),
					.C(clk)
				);
		end
	endgenerate

endmodule // dffesr_n
