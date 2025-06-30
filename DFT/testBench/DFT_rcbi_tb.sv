`timescale 1ns/1ns  

module DFT_rcbi_tb();
	parameter WIDTH = 12;
	parameter BIN_NUM = 4;
	parameter N_MAX = 8;
	parameter LOG_N_MAX = $clog2(N_MAX);

	reg clk, reset, wr;
	reg [$clog2(LOG_N_MAX):0] N;
	reg [LOG_N_MAX:0] k [BIN_NUM-1:0];
	reg signed [WIDTH-1:0] x;
	wire signed [WIDTH-1:0] o_X [1:0];
	wire signed [WIDTH-1:0] X [BIN_NUM-1:0][1:0];
	wire [2:0] state;
	wire [15:0] bin_counter;
	wire [15:0] n;
    wire [WIDTH-1:0] o_k;


	always #25 clk = ~clk;

	DFT_rcbi#(
		.WIDTH(WIDTH),
		.BIN_NUM(BIN_NUM),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX)
	) UUT(
		.i_sys_clk(clk),
		.i_sys_rst(reset),
		.i_x(x),
		.i_wr(wr),
		.i_k(k),
		.o_X(o_X),
		.o_done(done),
		.X(X),
		.state(state)
	);

	initial begin 
		clk = 0;
		reset = 1;
		#100;
		reset = 0;
		wr = 0;
		k[0] = 0;
		k[1] = 1;
		k[2] = 2;
		k[3] = 3;
		N = LOG_N_MAX;

		x = 0;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x = 0;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000

		x = 0;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x = 0;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000

		@(done == 1)
		#100;
		$finish;
	end
endmodule