module DFT_singleBin_tb();
	parameter WIDTH = 16;
	parameter N_MAX = 1024;
	parameter LOG_N_MAX = 10;
	parameter FRAC_BITS = 6;

	reg clk, reset, wr;
	reg [0:WIDTH-1] k, n, N;
	reg signed [0:WIDTH-1] x;
	wire signed [0:WIDTH-1] X [0:1];
	wire [0:2] state;
	wire signed [0:WIDTH -1] buffer [0:1];
	wire signed [0:WIDTH-1] c [0:1];
	wire [0:WIDTH-1] index;

	always #25 clk = ~clk;

	DFT_singleBin#(
		.WIDTH(WIDTH),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX),
		.FRAC_BITS(FRAC_BITS)
	) UUT(
		.i_sys_clk(clk),
		.i_reset(reset),
		.i_x(x),
		.i_wr(wr),
		.i_k(k),
        .i_n(n),
		.i_N(N),
		.o_X(X),
		.o_done(done)
	);

	initial begin 
		clk = 0;
		reset = 1;
		#100;
		reset = 0;
		wr = 0;
		k = 0;
		N = 2;

		x = 0;
        n = 0;
		wr = 1;
		#50;
		wr = 0;
		#800;

		x = -1;
        n = 1;
		wr = 1;
		#50;
		wr = 0;
		#800;

		x = 0;
        n = 2;
		wr = 1;
		#50;
		wr = 0;
		#800;

		x = 1;
        n = 3;
		wr = 1;
		#50;
		wr = 0;
		#800

		@(done == 1)
		#100;
		$finish;
	end
endmodule