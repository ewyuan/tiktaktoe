module tiktaktoe
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		HEX0,
		HEX1,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input CLOCK_50;						//	50 MHz
	input [3:0] KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output VGA_CLK;   					//	VGA Clock
	output VGA_HS;						//	VGA H_SYNC
	output VGA_VS;						//	VGA V_SYNC
	output VGA_BLANK_N;					//	VGA BLANK
	output VGA_SYNC_N;					//	VGA SYNC
	output [9:0] VGA_R;   				//	VGA Red[9:0]
	output [9:0] VGA_G;	 				//	VGA Green[9:0]
	output [9:0] VGA_B;   				//	VGA Blue[9:0]
	output [6:0] HEX0;
	output [6:0] HEX1;

	wire resetn;
	wire left;
	wire right;
	wire select;

	assign resetn = KEY[0];
	assign select = ~KEY[2];

	// Create the colour, cursor_x, cursor_y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [6:0] cursor_x;
	wire [6:0] cursor_y;
	wire [1:0] player;
	wire [6:0] draw_x;
	wire [6:0] draw_y;
	wire writeEn;
	wire enable;

	wire [1:0] winner;

	wire [3:0] grid_x;
	wire [3:0] grid_y;
	wire [3:0] hex_digit;
	wire [3:0] hex_p;
	wire [97:0] full_grid;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(draw_x),
			.y(draw_y),
			.plot(enable),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK)
		);
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "grid.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	pulse pulse_left(left, ~KEY[3], CLOCK_50);
	pulse pulse_right(right, ~KEY[1], CLOCK_50);

// Instansiate datapath
	datapath d0(left, right, cursor_x, cursor_y, grid_x, grid_y, winner, colour, select, CLOCK_50, resetn, enable, draw_x, draw_y, player, hex_p, hex_digit);

	hex_decoder hex_0(hex_digit, HEX0);
	hex_decoder hex_1(hex_p, HEX1);
    // Instansiate FSM control
	control c0(select, resetn, CLOCK_50, enable, player);
endmodule

module pulse(output reg pulse_out, input switch_in, input clock);
	reg delay;
	always @ (posedge clock)
	begin
		if (switch_in && !delay)
			pulse_out <= 1'b1;
		else pulse_out <= 1'b0;
			delay <= switch_in;
	end
endmodule

module datapath(left, right, cursor_x, cursor_y, grid_x, grid_y, winner, colour, draw, clock, reset_n, enable, draw_x, draw_y, player, hex_p, hex_digit);
	input [1:0] player;
	input left, right, reset_n, enable, clock, draw;
	output [3:0] hex_p;
	output [3:0] hex_digit;
	output reg [3:0] grid_x;
	output reg [3:0] grid_y;
	output reg [6:0] cursor_x;
	output reg [6:0] cursor_y;
	output [6:0] draw_x;
	output [6:0] draw_y;
	output [2:0] colour;

	reg [6:0] co1;
	reg [1:0] grid [6:0][6:0];

	reg [3:0] hex_out0;
	reg [3:0] hex_out1;
	wire [1:0] c1, c2, c3;

	reg [9:0] CRD [59:0]; // [59:39]Column, [38:18]Row, [17:0]Diagonal;
	reg [5:0] CRD_index;

	output reg [1:0] winner;

		always @ (posedge clock)
		begin
			if (!reset_n)
			begin
				//split columns
				//first sub-column [59] in the first column [59:57]
				CRD[59][9:8] = 2'b0;
				CRD[59][7:6] = 2'b0;
				CRD[59][5:4] = 2'b0;
				CRD[59][3:2] = 2'b0;
				CRD[59][1:0] = 2'b0;

				//second sub-column [58] in the first column [59:57]
				CRD[58][9:8] = 2'b0;
				CRD[58][7:6] = 2'b0;
				CRD[58][5:4] = 2'b0;
				CRD[58][3:2] = 2'b0;
				CRD[58][1:0] = 2'b0;

				//third sub-column [57] in the first column [59:57]
				CRD[57][9:8] = 2'b0;
				CRD[57][7:6] = 2'b0;
				CRD[57][5:4] = 2'b0;
				CRD[57][3:2] = 2'b0;
				CRD[57][1:0] = 2'b0;

				//first sub-column [56] in the second column [56:54]
				CRD[56][9:8] = 2'b0;
				CRD[56][7:6] = 2'b0;
				CRD[56][5:4] = 2'b0;
				CRD[56][3:2] = 2'b0;
				CRD[56][1:0] = 2'b0;

				//second sub-column [55] in the second column [56:54]
				CRD[55][9:8] = 2'b0;
				CRD[55][7:6] = 2'b0;
				CRD[55][5:4] = 2'b0;
				CRD[55][3:2] = 2'b0;
				CRD[55][1:0] = 2'b0;

				//third sub-column [54] in the second column [56:54]
				CRD[54][9:8] = 2'b0;
				CRD[54][7:6] = 2'b0;
				CRD[54][5:4] = 2'b0;
				CRD[54][3:2] = 2'b0;
				CRD[54][1:0] = 2'b0;

				//first sub-column [53] in the third column [53:51]
				CRD[53][9:8] = 2'b0;
				CRD[53][7:6] = 2'b0;
				CRD[53][5:4] = 2'b0;
				CRD[53][3:2] = 2'b0;
				CRD[53][1:0] = 2'b0;

				//second sub-column [52] in the third column [53:51]
				CRD[52][9:8] = 2'b0;
				CRD[52][7:6] = 2'b0;
				CRD[52][5:4] = 2'b0;
				CRD[52][3:2] = 2'b0;
				CRD[52][1:0] = 2'b0;

				//third sub-column [51] in the third column [53:51]
				CRD[51][9:8] = 2'b0;
				CRD[51][7:6] = 2'b0;
				CRD[51][5:4] = 2'b0;
				CRD[51][3:2] = 2'b0;
				CRD[51][1:0] = 2'b0;

				//first sub-column [50] in the fourth column [50:48]
				CRD[50][9:8] = 2'b0;
				CRD[50][7:6] = 2'b0;
				CRD[50][5:4] = 2'b0;
				CRD[50][3:2] = 2'b0;
				CRD[50][1:0] = 2'b0;

				//second sub-column [49] in the fourth column [50:48]
				CRD[49][9:8] = 2'b0;
				CRD[49][7:6] = 2'b0;
				CRD[49][5:4] = 2'b0;
				CRD[49][3:2] = 2'b0;
				CRD[49][1:0] = 2'b0;

				//third sub-column [48] in the fourth column [50:48]
				CRD[48][9:8] = 2'b0;
				CRD[48][7:6] = 2'b0;
				CRD[48][5:4] = 2'b0;
				CRD[48][3:2] = 2'b0;
				CRD[48][1:0] = 2'b0;

				//first sub-column [47] in the fifth column [47:45]
				CRD[47][9:8] = 2'b0;
				CRD[47][7:6] = 2'b0;
				CRD[47][5:4] = 2'b0;
				CRD[47][3:2] = 2'b0;
				CRD[47][1:0] = 2'b0;

				//second sub-column [46] in the fifth column [47:45]
				CRD[46][9:8] = 2'b0;
				CRD[46][7:6] = 2'b0;
				CRD[46][5:4] = 2'b0;
				CRD[46][3:2] = 2'b0;
				CRD[46][1:0] = 2'b0;

				//third sub-column [45] in the fifth column [47:45]
				CRD[45][9:8] = 2'b0;
				CRD[45][7:6] = 2'b0;
				CRD[45][5:4] = 2'b0;
				CRD[45][3:2] = 2'b0;
				CRD[45][1:0] = 2'b0;

				//first sub-column [44] in the sixth column [44:42]
				CRD[44][9:8] = 2'b0;
				CRD[44][7:6] = 2'b0;
				CRD[44][5:4] = 2'b0;
				CRD[44][3:2] = 2'b0;
				CRD[44][1:0] = 2'b0;

				//second sub-column [43] in the sixth column [44:42]
				CRD[43][9:8] = 2'b0;
				CRD[43][7:6] = 2'b0;
				CRD[43][5:4] = 2'b0;
				CRD[43][3:2] = 2'b0;
				CRD[43][1:0] = 2'b0;

				//third sub-column [42] in the sixth column [44:42]
				CRD[42][9:8] = 2'b0;
				CRD[42][7:6] = 2'b0;
				CRD[42][5:4] = 2'b0;
				CRD[42][3:2] = 2'b0;
				CRD[42][1:0] = 2'b0;

				//first sub-column [41] in the seventh column [41:39]
				CRD[41][9:8] = 2'b0;
				CRD[41][7:6] = 2'b0;
				CRD[41][5:4] = 2'b0;
				CRD[41][3:2] = 2'b0;
				CRD[41][1:0] = 2'b0;

				//second sub-column [40] in the seventh column [41:39]
				CRD[40][9:8] = 2'b0;
				CRD[40][7:6] = 2'b0;
				CRD[40][5:4] = 2'b0;
				CRD[40][3:2] = 2'b0;
				CRD[40][1:0] = 2'b0;

				//third sub-column [39] in the seventh column [41:39]
				CRD[39][9:8] = 2'b0;
				CRD[39][7:6] = 2'b0;
				CRD[39][5:4] = 2'b0;
				CRD[39][3:2] = 2'b0;
				CRD[39][1:0] = 2'b0;

				//split rows
				//first sub-row [38] in the first row [38:36]
				CRD[38][9:8] = 2'b0;
				CRD[38][7:6] = 2'b0;
				CRD[38][5:4] = 2'b0;
				CRD[38][3:2] = 2'b0;
				CRD[38][1:0] = 2'b0;

				//second sub-row [37] in the first row [38:36]
				CRD[37][9:8] = 2'b0;
				CRD[37][7:6] = 2'b0;
				CRD[37][5:4] = 2'b0;
				CRD[37][3:2] = 2'b0;
				CRD[37][1:0] = 2'b0;

				//third sub-row [36] in the first row [38:36]
				CRD[36][9:8] = 2'b0;
				CRD[36][7:6] = 2'b0;
				CRD[36][5:4] = 2'b0;
				CRD[36][3:2] = 2'b0;
				CRD[36][1:0] = 2'b0;

				//first sub-row [35] in the second row [35:33]
				CRD[35][9:8] = 2'b0;
				CRD[35][7:6] = 2'b0;
				CRD[35][5:4] = 2'b0;
				CRD[35][3:2] = 2'b0;
				CRD[35][1:0] = 2'b0;

				//second sub-row [34] in the second row [35:33]
				CRD[34][9:8] = 2'b0;
				CRD[34][7:6] = 2'b0;
				CRD[34][5:4] = 2'b0;
				CRD[34][3:2] = 2'b0;
				CRD[34][1:0] = 2'b0;

				//third sub-row [33] in the second row [35:33]
				CRD[33][9:8] = 2'b0;
				CRD[33][7:6] = 2'b0;
				CRD[33][5:4] = 2'b0;
				CRD[33][3:2] = 2'b0;
				CRD[33][1:0] = 2'b0;

				//first sub-row [32] in the third row [32:30]
				CRD[32][9:8] = 2'b0;
				CRD[32][7:6] = 2'b0;
				CRD[32][5:4] = 2'b0;
				CRD[32][3:2] = 2'b0;
				CRD[32][1:0] = 2'b0;

				//second sub-row [31] in the third row [32:30]
				CRD[31][9:8] = 2'b0;
				CRD[31][7:6] = 2'b0;
				CRD[31][5:4] = 2'b0;
				CRD[31][3:2] = 2'b0;
				CRD[31][1:0] = 2'b0;

				//third sub-row [30] in the third row [32:30]
				CRD[30][9:8] = 2'b0;
				CRD[30][7:6] = 2'b0;
				CRD[30][5:4] = 2'b0;
				CRD[30][3:2] = 2'b0;
				CRD[30][1:0] = 2'b0;

				//first sub-row [29] in the fourth row [29:27]
				CRD[29][9:8] = 2'b0;
				CRD[29][7:6] = 2'b0;
				CRD[29][5:4] = 2'b0;
				CRD[29][3:2] = 2'b0;
				CRD[29][1:0] = 2'b0;

				//second sub-row [28] in the fourth row [29:27]
				CRD[28][9:8] = 2'b0;
				CRD[28][7:6] = 2'b0;
				CRD[28][5:4] = 2'b0;
				CRD[28][3:2] = 2'b0;
				CRD[28][1:0] = 2'b0;

				//third sub-row [27] in the fourth row [29:27]
				CRD[27][9:8] = 2'b0;
				CRD[27][7:6] = 2'b0;
				CRD[27][5:4] = 2'b0;
				CRD[27][3:2] = 2'b0;
				CRD[27][1:0] = 2'b0;

				//first sub-row [26] in the fifth row [26:24]
				CRD[26][9:8] = 2'b0;
				CRD[26][7:6] = 2'b0;
				CRD[26][5:4] = 2'b0;
				CRD[26][3:2] = 2'b0;
				CRD[26][1:0] = 2'b0;

				//second sub-row [25] in the fifth row [26:24]
				CRD[25][9:8] = 2'b0;
				CRD[25][7:6] = 2'b0;
				CRD[25][5:4] = 2'b0;
				CRD[25][3:2] = 2'b0;
				CRD[25][1:0] = 2'b0;

				//third sub-row [24] in the fifth row [26:24]
				CRD[24][9:8] = 2'b0;
				CRD[24][7:6] = 2'b0;
				CRD[24][5:4] = 2'b0;
				CRD[24][3:2] = 2'b0;
				CRD[24][1:0] = 2'b0;

				//first sub-row [23] in the sixth row [23:21]
				CRD[23][9:8] = 2'b0;
				CRD[23][7:6] = 2'b0;
				CRD[23][5:4] = 2'b0;
				CRD[23][3:2] = 2'b0;
				CRD[23][1:0] = 2'b0;

				//second sub-row [22] in the sixth row [23:21]
				CRD[22][9:8] = 2'b0;
				CRD[22][7:6] = 2'b0;
				CRD[22][5:4] = 2'b0;
				CRD[22][3:2] = 2'b0;
				CRD[22][1:0] = 2'b0;

				//third sub-row [21] in the sixth row [23:21]
				CRD[21][9:8] = 2'b0;
				CRD[21][7:6] = 2'b0;
				CRD[21][5:4] = 2'b0;
				CRD[21][3:2] = 2'b0;
				CRD[21][1:0] = 2'b0;

				//first sub-row [20] in the seventh row [20:18]
				CRD[20][9:8] = 2'b0;
				CRD[20][7:6] = 2'b0;
				CRD[20][5:4] = 2'b0;
				CRD[20][3:2] = 2'b0;
				CRD[20][1:0] = 2'b0;

				//second sub-row [19] in the seventh row [20:18]
				CRD[19][9:8] = 2'b0;
				CRD[19][7:6] = 2'b0;
				CRD[19][5:4] = 2'b0;
				CRD[19][3:2] = 2'b0;
				CRD[19][1:0] = 2'b0;

				//third sub-row [18] in the seventh row [20:18]
				CRD[18][9:8] = 2'b0;
				CRD[18][7:6] = 2'b0;
				CRD[18][5:4] = 2'b0;
				CRD[18][3:2] = 2'b0;
				CRD[18][1:0] = 2'b0;

				//split diagonal
				//first forward diagonal [17]
				CRD[17][9:8] = 2'b0;
				CRD[17][7:6] = 2'b0;
				CRD[17][5:4] = 2'b0;
				CRD[17][3:2] = 2'b0;
				CRD[17][1:0] = 2'b0;

				//first forward sub-diagonal [16] in second diagonal [16:15]
				CRD[16][9:8] = 2'b0;
				CRD[16][7:6] = 2'b0;
				CRD[16][5:4] = 2'b0;
				CRD[16][3:2] = 2'b0;
				CRD[16][1:0] = 2'b0;

				//second forward sub-diagonal [15] in second diagonal [16:15]
				CRD[15][9:8] = 2'b0;
				CRD[15][7:6] = 2'b0;
				CRD[15][5:4] = 2'b0;
				CRD[15][3:2] = 2'b0;
				CRD[15][1:0] = 2'b0;

				//first forward sub-diagonal [14] in third diagonal [14:12]
				CRD[14][9:8] = 2'b0;
				CRD[14][7:6] = 2'b0;
				CRD[14][5:4] = 2'b0;
				CRD[14][3:2] = 2'b0;
				CRD[14][1:0] = 2'b0;

				//second forward sub-diagonal [13] in third diagonal [14:12]
				CRD[13][9:8] = 2'b0;
				CRD[13][7:6] = 2'b0;
				CRD[13][5:4] = 2'b0;
				CRD[13][3:2] = 2'b0;
				CRD[13][1:0] = 2'b0;

				//third forward sub-diagonal [12] in third diagonal [14:12]
				CRD[12][9:8] = 2'b0;
				CRD[12][7:6] = 2'b0;
				CRD[12][5:4] = 2'b0;
				CRD[12][3:2] = 2'b0;
				CRD[12][1:0] = 2'b0;

				//first forward sub-diagonal [11] in fourth diagonal [11:10]
				CRD[11][9:8] = 2'b0;
				CRD[11][7:6] = 2'b0;
				CRD[11][5:4] = 2'b0;
				CRD[11][3:2] = 2'b0;
				CRD[11][1:0] = 2'b0;

				//second forward sub-diagonal [10] in fourth diagonal [11:10]
				CRD[10][9:8] = 2'b0;
				CRD[10][7:6] = 2'b0;
				CRD[10][5:4] = 2'b0;
				CRD[10][3:2] = 2'b0;
				CRD[10][1:0] = 2'b0;

				//fifth forward diagonal [9]
				CRD[9][9:8] = 2'b0;
				CRD[9][7:6] = 2'b0;
				CRD[9][5:4] = 2'b0;
				CRD[9][3:2] = 2'b0;
				CRD[9][1:0] = 2'b0;

				//sixth backward diagonal [8]
				CRD[8][9:8] = 2'b0;
				CRD[8][7:6] = 2'b0;
				CRD[8][5:4] = 2'b0;
				CRD[8][3:2] = 2'b0;
				CRD[8][1:0] = 2'b0;

				//first backward sub-diagonal [7] in seventh diagonal [7:6]
				CRD[7][9:8] = 2'b0;
				CRD[7][7:6] = 2'b0;
				CRD[7][5:4] = 2'b0;
				CRD[7][3:2] = 2'b0;
				CRD[7][1:0] = 2'b0;

				//second backward sub-diagonal [6] in seventh diagonal [7:6]
				CRD[6][9:8] = 2'b0;
				CRD[6][7:6] = 2'b0;
				CRD[6][5:4] = 2'b0;
				CRD[6][3:2] = 2'b0;
				CRD[6][1:0] = 2'b0;

				//first backward sub-diagonal [5] in eighth diagonal [5:3]
				CRD[5][9:8] = 2'b0;
				CRD[5][7:6] = 2'b0;
				CRD[5][5:4] = 2'b0;
				CRD[5][3:2] = 2'b0;
				CRD[5][1:0] = 2'b0;

				//second backward sub-diagonal [4] in eighth diagonal [5:3]
				CRD[4][9:8] = 2'b0;
				CRD[4][7:6] = 2'b0;
				CRD[4][5:4] = 2'b0;
				CRD[4][3:2] = 2'b0;
				CRD[4][1:0] = 2'b0;

				//third backward sub-diagonal [3] in eighth diagonal [5:3]
				CRD[3][9:8] = 2'b0;
				CRD[3][7:6] = 2'b0;
				CRD[3][5:4] = 2'b0;
				CRD[3][3:2] = 2'b0;
				CRD[3][1:0] = 2'b0;

				//first backward sub-diagonal [2] in ninth diagonal [2:1]
				CRD[2][9:8] = 2'b0;
				CRD[2][7:6] = 2'b0;
				CRD[2][5:4] = 2'b0;
				CRD[2][3:2] = 2'b0;
				CRD[2][1:0] = 2'b0;

				//second backward sub-diagonal [1] in ninth diagonal [2:1]
				CRD[1][9:8] = 2'b0;
				CRD[1][7:6] = 2'b0;
				CRD[1][5:4] = 2'b0;
				CRD[1][3:2] = 2'b0;
				CRD[1][1:0] = 2'b0;

				//tenth backward diagonal [0]
				CRD[0][9:8] = 2'b0;
				CRD[0][7:6] = 2'b0;
				CRD[0][5:4] = 2'b0;
				CRD[0][3:2] = 2'b0;
				CRD[0][1:0] = 2'b0;
			end

			else
			begin
				//split columns
				//first sub-column [59] in the first column [59:57]
				CRD[59][9:8] = grid[0][0];
				CRD[59][7:6] = grid[1][0];
				CRD[59][5:4] = grid[2][0];
				CRD[59][3:2] = grid[3][0];
				CRD[59][1:0] = grid[4][0];

				//second sub-column [58] in the first column [59:57]
				CRD[58][9:8] = grid[1][0];
				CRD[58][7:6] = grid[2][0];
				CRD[58][5:4] = grid[3][0];
				CRD[58][3:2] = grid[4][0];
				CRD[58][1:0] = grid[5][0];

				//third sub-column [57] in the first column [59:57]
				CRD[57][9:8] = grid[2][0];
				CRD[57][7:6] = grid[3][0];
				CRD[57][5:4] = grid[4][0];
				CRD[57][3:2] = grid[5][0];
				CRD[57][1:0] = grid[6][0];

				//first sub-column [56] in the second column [56:54]
				CRD[56][9:8] = grid[0][1];
				CRD[56][7:6] = grid[1][1];
				CRD[56][5:4] = grid[2][1];
				CRD[56][3:2] = grid[3][1];
				CRD[56][1:0] = grid[4][1];

				//second sub-column [55] in the second column [56:54]
				CRD[55][9:8] = grid[1][1];
				CRD[55][7:6] = grid[2][1];
				CRD[55][5:4] = grid[3][1];
				CRD[55][3:2] = grid[4][1];
				CRD[55][1:0] = grid[5][1];

				//third sub-column [54] in the second column [56:54]
				CRD[54][9:8] = grid[2][1];
				CRD[54][7:6] = grid[3][1];
				CRD[54][5:4] = grid[4][1];
				CRD[54][3:2] = grid[5][1];
				CRD[54][1:0] = grid[6][1];

				//first sub-column [53] in the third column [53:51]
				CRD[53][9:8] = grid[0][2];
				CRD[53][7:6] = grid[1][2];
				CRD[53][5:4] = grid[2][2];
				CRD[53][3:2] = grid[3][2];
				CRD[53][1:0] = grid[4][2];

				//second sub-column [52] in the third column [53:51]
				CRD[52][9:8] = grid[1][2];
				CRD[52][7:6] = grid[2][2];
				CRD[52][5:4] = grid[3][2];
				CRD[52][3:2] = grid[4][2];
				CRD[52][1:0] = grid[5][2];

				//third sub-column [51] in the third column [53:51]
				CRD[51][9:8] = grid[2][2];
				CRD[51][7:6] = grid[3][2];
				CRD[51][5:4] = grid[4][2];
				CRD[51][3:2] = grid[5][2];
				CRD[51][1:0] = grid[6][2];

				//first sub-column [50] in the fourth column [50:48]
				CRD[50][9:8] = grid[0][3];
				CRD[50][7:6] = grid[1][3];
				CRD[50][5:4] = grid[2][3];
				CRD[50][3:2] = grid[3][3];
				CRD[50][1:0] = grid[4][3];

				//second sub-column [49] in the fourth column [50:48]
				CRD[49][9:8] = grid[1][3];
				CRD[49][7:6] = grid[2][3];
				CRD[49][5:4] = grid[3][3];
				CRD[49][3:2] = grid[4][3];
				CRD[49][1:0] = grid[5][3];

				//third sub-column [48] in the fourth column [50:48]
				CRD[48][9:8] = grid[2][3];
				CRD[48][7:6] = grid[3][3];
				CRD[48][5:4] = grid[4][3];
				CRD[48][3:2] = grid[5][3];
				CRD[48][1:0] = grid[6][3];

				//first sub-column [47] in the fifth column [47:45]
				CRD[47][9:8] = grid[0][4];
				CRD[47][7:6] = grid[1][4];
				CRD[47][5:4] = grid[2][4];
				CRD[47][3:2] = grid[3][4];
				CRD[47][1:0] = grid[4][4];

				//second sub-column [46] in the fifth column [47:45]
				CRD[46][9:8] = grid[1][4];
				CRD[46][7:6] = grid[2][4];
				CRD[46][5:4] = grid[3][4];
				CRD[46][3:2] = grid[4][4];
				CRD[46][1:0] = grid[5][4];

				//third sub-column [45] in the fifth column [47:45]
				CRD[45][9:8] = grid[2][4];
				CRD[45][7:6] = grid[3][4];
				CRD[45][5:4] = grid[4][4];
				CRD[45][3:2] = grid[5][4];
				CRD[45][1:0] = grid[6][4];

				//first sub-column [44] in the sixth column [44:42]
				CRD[44][9:8] = grid[0][5];
				CRD[44][7:6] = grid[1][5];
				CRD[44][5:4] = grid[2][5];
				CRD[44][3:2] = grid[3][5];
				CRD[44][1:0] = grid[4][5];

				//second sub-column [43] in the sixth column [44:42]
				CRD[43][9:8] = grid[1][5];
				CRD[43][7:6] = grid[2][5];
				CRD[43][5:4] = grid[3][5];
				CRD[43][3:2] = grid[4][5];
				CRD[43][1:0] = grid[5][5];

				//third sub-column [42] in the sixth column [44:42]
				CRD[42][9:8] = grid[2][5];
				CRD[42][7:6] = grid[3][5];
				CRD[42][5:4] = grid[4][5];
				CRD[42][3:2] = grid[5][5];
				CRD[42][1:0] = grid[6][5];

				//first sub-column [41] in the seventh column [41:39]
				CRD[41][9:8] = grid[0][6];
				CRD[41][7:6] = grid[1][6];
				CRD[41][5:4] = grid[2][6];
				CRD[41][3:2] = grid[3][6];
				CRD[41][1:0] = grid[4][6];

				//second sub-column [40] in the seventh column [41:39]
				CRD[40][9:8] = grid[1][6];
				CRD[40][7:6] = grid[2][6];
				CRD[40][5:4] = grid[3][6];
				CRD[40][3:2] = grid[4][6];
				CRD[40][1:0] = grid[5][6];

				//third sub-column [39] in the seventh column [41:39]
				CRD[39][9:8] = grid[2][6];
				CRD[39][7:6] = grid[3][6];
				CRD[39][5:4] = grid[4][6];
				CRD[39][3:2] = grid[5][6];
				CRD[39][1:0] = grid[6][6];

				//split rows
				//first sub-row [38] in the first row [38:36]
				CRD[38][9:8] = grid[0][0];
				CRD[38][7:6] = grid[0][1];
				CRD[38][5:4] = grid[0][2];
				CRD[38][3:2] = grid[0][3];
				CRD[38][1:0] = grid[0][4];

				//second sub-row [37] in the first row [38:36]
				CRD[37][9:8] = grid[0][1];
				CRD[37][7:6] = grid[0][2];
				CRD[37][5:4] = grid[0][3];
				CRD[37][3:2] = grid[0][4];
				CRD[37][1:0] = grid[0][5];

				//third sub-row [36] in the first row [38:36]
				CRD[36][9:8] = grid[0][2];
				CRD[36][7:6] = grid[0][3];
				CRD[36][5:4] = grid[0][4];
				CRD[36][3:2] = grid[0][5];
				CRD[36][1:0] = grid[0][6];

				//first sub-row [35] in the second row [35:33]
				CRD[35][9:8] = grid[1][0];
				CRD[35][7:6] = grid[1][1];
				CRD[35][5:4] = grid[1][2];
				CRD[35][3:2] = grid[1][3];
				CRD[35][1:0] = grid[1][4];

				//second sub-row [34] in the second row [35:33]
				CRD[34][9:8] = grid[1][1];
				CRD[34][7:6] = grid[1][2];
				CRD[34][5:4] = grid[1][3];
				CRD[34][3:2] = grid[1][4];
				CRD[34][1:0] = grid[1][5];

				//third sub-row [33] in the second row [35:33]
				CRD[33][9:8] = grid[1][2];
				CRD[33][7:6] = grid[1][3];
				CRD[33][5:4] = grid[1][4];
				CRD[33][3:2] = grid[1][5];
				CRD[33][1:0] = grid[1][6];

				//first sub-row [32] in the third row [32:30]
				CRD[32][9:8] = grid[2][0];
				CRD[32][7:6] = grid[2][1];
				CRD[32][5:4] = grid[2][2];
				CRD[32][3:2] = grid[2][3];
				CRD[32][1:0] = grid[2][4];

				//second sub-row [31] in the third row [32:30]
				CRD[31][9:8] = grid[2][1];
				CRD[31][7:6] = grid[2][2];
				CRD[31][5:4] = grid[2][3];
				CRD[31][3:2] = grid[2][4];
				CRD[31][1:0] = grid[2][5];

				//third sub-row [30] in the third row [32:30]
				CRD[30][9:8] = grid[2][2];
				CRD[30][7:6] = grid[2][3];
				CRD[30][5:4] = grid[2][4];
				CRD[30][3:2] = grid[2][5];
				CRD[30][1:0] = grid[2][6];

				//first sub-row [29] in the fourth row [29:27]
				CRD[29][9:8] = grid[3][0];
				CRD[29][7:6] = grid[3][1];
				CRD[29][5:4] = grid[3][2];
				CRD[29][3:2] = grid[3][3];
				CRD[29][1:0] = grid[3][4];

				//second sub-row [28] in the fourth row [29:27]
				CRD[28][9:8] = grid[3][1];
				CRD[28][7:6] = grid[3][2];
				CRD[28][5:4] = grid[3][3];
				CRD[28][3:2] = grid[3][4];
				CRD[28][1:0] = grid[3][5];

				//third sub-row [27] in the fourth row [29:27]
				CRD[27][9:8] = grid[3][2];
				CRD[27][7:6] = grid[3][3];
				CRD[27][5:4] = grid[3][4];
				CRD[27][3:2] = grid[3][5];
				CRD[27][1:0] = grid[3][6];

				//first sub-row [26] in the fifth row [26:24]
				CRD[26][9:8] = grid[4][0];
				CRD[26][7:6] = grid[4][1];
				CRD[26][5:4] = grid[4][2];
				CRD[26][3:2] = grid[4][3];
				CRD[26][1:0] = grid[4][4];

				//second sub-row [25] in the fifth row [26:24]
				CRD[25][9:8] = grid[4][1];
				CRD[25][7:6] = grid[4][2];
				CRD[25][5:4] = grid[4][3];
				CRD[25][3:2] = grid[4][4];
				CRD[25][1:0] = grid[4][5];

				//third sub-row [24] in the fifth row [26:24]
				CRD[24][9:8] = grid[4][2];
				CRD[24][7:6] = grid[4][3];
				CRD[24][5:4] = grid[4][4];
				CRD[24][3:2] = grid[4][5];
				CRD[24][1:0] = grid[4][6];

				//first sub-row [23] in the sixth row [23:21]
				CRD[23][9:8] = grid[5][0];
				CRD[23][7:6] = grid[5][1];
				CRD[23][5:4] = grid[5][2];
				CRD[23][3:2] = grid[5][3];
				CRD[23][1:0] = grid[5][4];

				//second sub-row [22] in the sixth row [23:21]
				CRD[22][9:8] = grid[5][1];
				CRD[22][7:6] = grid[5][2];
				CRD[22][5:4] = grid[5][3];
				CRD[22][3:2] = grid[5][4];
				CRD[22][1:0] = grid[5][5];

				//third sub-row [21] in the sixth row [23:21]
				CRD[21][9:8] = grid[5][2];
				CRD[21][7:6] = grid[5][3];
				CRD[21][5:4] = grid[5][4];
				CRD[21][3:2] = grid[5][5];
				CRD[21][1:0] = grid[5][6];

				//first sub-row [20] in the seventh row [20:18]
				CRD[20][9:8] = grid[6][0];
				CRD[20][7:6] = grid[6][1];
				CRD[20][5:4] = grid[6][2];
				CRD[20][3:2] = grid[6][3];
				CRD[20][1:0] = grid[6][4];

				//second sub-row [19] in the seventh row [20:18]
				CRD[19][9:8] = grid[6][1];
				CRD[19][7:6] = grid[6][2];
				CRD[19][5:4] = grid[6][3];
				CRD[19][3:2] = grid[6][4];
				CRD[19][1:0] = grid[6][5];

				//third sub-row [18] in the seventh row [20:18]
				CRD[18][9:8] = grid[6][2];
				CRD[18][7:6] = grid[6][3];
				CRD[18][5:4] = grid[6][4];
				CRD[18][3:2] = grid[6][5];
				CRD[18][1:0] = grid[6][6];

				//split diagonal
				//first forward diagonal [17]
				CRD[17][9:8] = grid[4][0];
				CRD[17][7:6] = grid[3][1];
				CRD[17][5:4] = grid[2][2];
				CRD[17][3:2] = grid[1][3];
				CRD[17][1:0] = grid[0][4];

				//first forward sub-diagonal [16] in second diagonal [16:15]
				CRD[16][9:8] = grid[5][0];
				CRD[16][7:6] = grid[4][1];
				CRD[16][5:4] = grid[3][2];
				CRD[16][3:2] = grid[2][3];
				CRD[16][1:0] = grid[1][4];

				//second forward sub-diagonal [15] in second diagonal [16:15]
				CRD[15][9:8] = grid[4][1];
				CRD[15][7:6] = grid[3][2];
				CRD[15][5:4] = grid[2][3];
				CRD[15][3:2] = grid[1][4];
				CRD[15][1:0] = grid[0][5];

				//first forward sub-diagonal [14] in third diagonal [14:12]
				CRD[14][9:8] = grid[6][0];
				CRD[14][7:6] = grid[5][1];
				CRD[14][5:4] = grid[4][2];
				CRD[14][3:2] = grid[3][3];
				CRD[14][1:0] = grid[2][4];

				//second forward sub-diagonal [13] in third diagonal [14:12]
				CRD[13][9:8] = grid[5][1];
				CRD[13][7:6] = grid[4][2];
				CRD[13][5:4] = grid[3][3];
				CRD[13][3:2] = grid[2][4];
				CRD[13][1:0] = grid[1][5];

				//third forward sub-diagonal [12] in third diagonal [14:12]
				CRD[12][9:8] = grid[4][2];
				CRD[12][7:6] = grid[3][3];
				CRD[12][5:4] = grid[2][4];
				CRD[12][3:2] = grid[1][5];
				CRD[12][1:0] = grid[0][6];

				//first forward sub-diagonal [11] in fourth diagonal [11:10]
				CRD[11][9:8] = grid[6][1];
				CRD[11][7:6] = grid[5][2];
				CRD[11][5:4] = grid[4][3];
				CRD[11][3:2] = grid[3][4];
				CRD[11][1:0] = grid[2][5];

				//second forward sub-diagonal [10] in fourth diagonal [11:10]
				CRD[10][9:8] = grid[5][2];
				CRD[10][7:6] = grid[4][3];
				CRD[10][5:4] = grid[3][4];
				CRD[10][3:2] = grid[2][5];
				CRD[10][1:0] = grid[1][6];

				//fifth forward diagonal [9]
				CRD[9][9:8] = grid[6][2];
				CRD[9][7:6] = grid[5][3];
				CRD[9][5:4] = grid[4][4];
				CRD[9][3:2] = grid[3][5];
				CRD[9][1:0] = grid[2][6];

				//sixth backward diagonal [8]
				CRD[8][9:8] = grid[0][2];
				CRD[8][7:6] = grid[1][3];
				CRD[8][5:4] = grid[2][4];
				CRD[8][3:2] = grid[3][5];
				CRD[8][1:0] = grid[4][6];

				//first backward sub-diagonal [7] in seventh diagonal [7:6]
				CRD[7][9:8] = grid[1][2];
				CRD[7][7:6] = grid[2][3];
				CRD[7][5:4] = grid[3][4];
				CRD[7][3:2] = grid[4][5];
				CRD[7][1:0] = grid[5][6];

				//second backward sub-diagonal [6] in seventh diagonal [7:6]
				CRD[6][9:8] = grid[0][1];
				CRD[6][7:6] = grid[1][2];
				CRD[6][5:4] = grid[2][3];
				CRD[6][3:2] = grid[3][4];
				CRD[6][1:0] = grid[4][5];

				//first backward sub-diagonal [5] in eighth diagonal [5:3]
				CRD[5][9:8] = grid[2][2];
				CRD[5][7:6] = grid[3][3];
				CRD[5][5:4] = grid[4][4];
				CRD[5][3:2] = grid[5][5];
				CRD[5][1:0] = grid[6][6];

				//second backward sub-diagonal [4] in eighth diagonal [5:3]
				CRD[4][9:8] = grid[1][1];
				CRD[4][7:6] = grid[2][2];
				CRD[4][5:4] = grid[3][3];
				CRD[4][3:2] = grid[4][4];
				CRD[4][1:0] = grid[5][5];

				//third backward sub-diagonal [3] in eighth diagonal [5:3]
				CRD[3][9:8] = grid[0][0];
				CRD[3][7:6] = grid[1][1];
				CRD[3][5:4] = grid[2][2];
				CRD[3][3:2] = grid[3][3];
				CRD[3][1:0] = grid[4][4];

				//first backward sub-diagonal [2] in ninth diagonal [2:1]
				CRD[2][9:8] = grid[2][1];
				CRD[2][7:6] = grid[3][2];
				CRD[2][5:4] = grid[4][3];
				CRD[2][3:2] = grid[5][4];
				CRD[2][1:0] = grid[6][5];

				//second backward sub-diagonal [1] in ninth diagonal [2:1]
				CRD[1][9:8] = grid[1][0];
				CRD[1][7:6] = grid[2][1];
				CRD[1][5:4] = grid[3][2];
				CRD[1][3:2] = grid[4][3];
				CRD[1][1:0] = grid[5][4];

				//tenth backward diagonal [0]
				CRD[0][9:8] = grid[2][0];
				CRD[0][7:6] = grid[3][1];
				CRD[0][5:4] = grid[4][2];
				CRD[0][3:2] = grid[5][3];
				CRD[0][1:0] = grid[6][4];
			end

			//win detection
			if (player == 2'b01)
			begin
				for (CRD_index = 0; CRD_index < 60; CRD_index = CRD_index + 1)
					if (CRD[CRD_index] == 10'b0101010101)
						winner <= 2'b01;
			end

			else if (player == 2'b10)
			begin
				for (CRD_index = 0; CRD_index < 60; CRD_index = CRD_index + 1)
					if (CRD[CRD_index] == 10'b1010101010)
						 winner <= 2'b10;
			end
		end

	always @ (posedge clock) begin
        if (!reset_n) begin
			cursor_x <= 10;
			cursor_y <= 10;
			grid_x <= 0;
			grid_y <= 0;
      		co1 <= 3'b000;
			hex_out1 = 4'b0000;
			hex_out0 = 4'b0000;
        end

        else
			// detects which player the winner is and displays to HEX
			if (winner == 2'b01)
			begin
				hex_out1 = 4'b0011;
				hex_out0 = 4'b0001;
			end

			else if (winner == 2'b10)
			begin
				hex_out1 = 4'b0011;
				hex_out0 = 4'b0010;
			end

			// draws current player on square
			if (draw && player == 2'b01 && grid[grid_y][grid_x] == 2'b00)
			begin
				co1 <= 3'b011;
				grid[grid_y][grid_x] <= 2'b01;
			end

			else if (draw && player == 2'b10 && grid[grid_y][grid_x] == 2'b00)
				begin
					co1 <= 3'b101;
					grid[grid_y][grid_x] <= 2'b10;
				end

			// handle left and right clicks
			if (left == 1'b1 && cursor_x >= 26 && cursor_x <= 106)
			begin
				cursor_x <= cursor_x - 16;
				cursor_y <= cursor_y;
				grid_x <= grid_x - 1;
				grid_y <= grid_y;
			end

			else if (left == 1'b1 && cursor_x < 26 && cursor_y >= 26)
			begin
				cursor_x <= 106;
		 		cursor_y <= cursor_y - 16;
				grid_x <= 6;
				grid_y <= grid_y - 1;
			end

			else if (left == 1'b1 && cursor_x < 26 && cursor_y < 26)
			begin
				cursor_x <= 106;
			 	cursor_y <= 106;
				grid_x <= 6;
				grid_y <= 6;
			end

			else if (right == 1'b1 && cursor_x >= 10 && cursor_x <= 90)
			begin
				cursor_x <= cursor_x + 16;
				cursor_y <= cursor_y;
				grid_x <= grid_x + 1;
				grid_y <= grid_y;
			end

			else if (right == 1'b1 && cursor_x > 90 && cursor_y <= 90)
			begin
				cursor_x <= 10;
				cursor_y <= cursor_y + 16;
				grid_x <= 0;
				grid_y <= grid_y + 1;
			end

			else if (right == 1'b1 && cursor_x > 90 && cursor_y > 90)
			begin
				cursor_x <= 10;
				cursor_y <= 10;
				grid_x <= 0;
				grid_y <= 0;
        	end
    	end

	counter m1(clock, reset_n, enable, c1);
	rate_counter m2(clock, reset_n, enable, c2);
	assign enable_1 = (c2 ==  2'b00) ? 1 : 0;
	counter m3(clock,reset_n,enable_1,c3);
	assign colour = co1;
	assign draw_x = cursor_x + c1;
	assign draw_y = cursor_y + c3;
	assign hex_digit = hex_out0;
	assign hex_p = hex_out1;
endmodule

module counter(clock, reset_n, enable, q);
	input 				clock, reset_n, enable;
	output reg 	[1:0] 	q;
	always @(posedge clock) begin
		if(reset_n == 1'b0)
			q <= 2'b00;
		else if (enable == 1'b1)
		begin
		  if (q == 2'b11)
			  q <= 2'b00;
		  else
			  q <= q + 1'b1;
		end
   end
endmodule

module rate_counter(clock, reset_n, enable, q);
		input clock;
		input reset_n;
		input enable;
		output reg [1:0] q;

		always @(posedge clock)
		begin
			if(reset_n == 1'b0)
				q <= 2'b11;
			else if(enable ==1'b1)
			begin
			   if ( q == 2'b00 )
					q <= 2'b11;
				else
					q <= q - 1'b1;
			end
		end
endmodule

/*
 * This code was adapted from https://github.com/Dxyk/CSC258/blob/master/Lab7_LU/part2/part2.v
 */
module rate_counter1(clock,reset_n,enable,q);
		input clock;
		input reset_n;
		input enable;
		output reg [4:0] q;

		always @(posedge clock)
		begin
			if(reset_n == 1'b0)
				q <= 5'b10000;
			else if(enable ==1'b1)
			begin
			   if ( q == 5'b00000 )
					q <= 5'b10000;
				else
					q <= q - 1'b1;
			end
		end
endmodule



module control(select_btn, reset_n, clock, enable, player);
		input select_btn, reset_n, clock;
		output reg enable;
		output reg [1:0] player;

		reg [2:0] current_state, next_state;

		 wire clock_1;
		 rate_counter1 m1(clock,reset_n,1'b1,q);
		 assign clock_1 = (q==  5'b00000) ? 1 : 0;

		localparam  SELECT_1 = 3'd0,
					P_ONE = 3'd1,
					SELECT_2 = 3'd2,
					P_TWO = 3'd3,
					SELECT_3 = 3'd4;



		always@(*)
		begin: state_table
			case (current_state)
				SELECT_1: next_state = select_btn ?  P_ONE : SELECT_1;
				P_ONE: next_state = ~select_btn ? SELECT_2 : P_ONE;
				SELECT_2: next_state = select_btn ? P_TWO : SELECT_2;
				P_TWO: next_state = ~select_btn ? SELECT_3 : P_TWO;
				SELECT_3: next_state = SELECT_1;
				default: next_state = SELECT_1;
			endcase
		end

		always@(*)
		begin: enable_signals
			enable = 1'b0;
			player = 2'b00;
			case(current_state)
				P_ONE:
				begin
					enable = 1'b1;
					player = 2'b01;
				end
				P_TWO:
				begin
					enable = 1'b1;
					player = 2'b10;
				end
			endcase
		end

		always@(posedge clock_1)
		begin: state_FFs
	        if(!reset_n)
	            current_state <= SELECT_1;
	        else
	            current_state <= next_state;
		end
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b111_1111; // displays nothing
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b000_1100; // display 'P'
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule
