`timescale 1ns/1ns  

module DFT_tb();
	parameter WIDTH = 12;
	parameter BIN_NUM = 4;
	parameter N_MAX = 8192;
	parameter LOG_N_MAX = $clog2(N_MAX);

	reg clk, reset, wr;
	reg [$clog2(LOG_N_MAX)-1:0] N;
	reg [LOG_N_MAX:0] k;
	reg signed [WIDTH-1:0] x;
	wire signed [WIDTH-1:0] o_X [1:0];
	wire signed [WIDTH-1:0] X [BIN_NUM-1:0][1:0];
	wire [2:0] state;
	wire [$clog2(BIN_NUM):0] bin_counter; 
	wire [15:0] n;
    wire [LOG_N_MAX-1:0] k_table [BIN_NUM-1:0];
	wire set_k;
	wire signed [WIDTH-1:0] pf [1:0];


	always #25 clk = ~clk;

	DFT_q#(
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
		.i_N(N),
		.o_X(o_X),
		.o_done(done)
	);

	initial begin 
		clk = 0;
		reset = 1;
		#100;
		reset = 0;
		wr = 0;
		// set k
		@(negedge clk);
		k = N_MAX;
		@(negedge clk);
		k = 0;
		@(negedge clk);
		k = 1;
		@(negedge clk);
		k = 2;
		@(negedge clk);
		k = 3;
		N = 2;

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