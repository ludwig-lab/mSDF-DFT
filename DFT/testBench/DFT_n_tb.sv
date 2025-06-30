`timescale 1ns/1ns  

module DFT_n_tb();
	parameter WIDTH = 12;
	parameter BIN_NUM = 4;
	parameter N_MAX = 32;
	parameter LOG_N_MAX = $clog2(N_MAX);

	reg clk, reset, wr;
	reg [$clog2(LOG_N_MAX)-1:0] N;
	reg [LOG_N_MAX:0] k;
	reg signed [WIDTH-1:0] x [0:1];
	wire signed [WIDTH-1:0] o_X [0:1];
	reg inverse;
	wire done;
	reg [1:0] scale;
	reg [WIDTH-1:0] x_buffer [0:N_MAX-1];


	always #25 clk = ~clk;

	DFT_i_q_n#(
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
		.o_done(done),
		.i_inverse(inverse),
		.i_scale(scale)
	);
	integer i;
	initial begin 
		$readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/LFP_128.txt",x_buffer);
		$monitor("time %t, x_real_table %h", $time,UUT.x_real_table);
		$monitor("time %t, x_img_table %h", $time,UUT.x_img_table);
		//$monitor("time %t, X[1] %h", $time,UUT.X[1]);
		//$monitor("time %t, X[2] %h", $time,UUT.X[2]);
		//$monitor("time %t, X[3] %h", $time,UUT.X[3]);
		//$monitor("time %t, y %h", $time,UUT.y);
		$monitor("time %t, n %d", $time,UUT.n);
		//$monitor("time %t, k %h", $time,UUT.k);
		//$monitor("time %t, pf_real %h, pf_img %h", $time,UUT.pf[0],UUT.pf[1]);
		//$monitor("time %t, bin_counter %h", $time,UUT.bin_counter);
		//$monitor("time %t, k_table %h %h %h %h", $time,UUT.k_table[0],UUT.k_table[1],UUT.k_table[2],UUT.k_table[3]);
		//$monitor("time %t, pf %h", $time,UUT.tabl[32]);
		$monitor("time %t, state %d", $time,UUT.state);
	 	//$monitor("%d", UUT.o_X[1]);
		clk = 0;
		reset = 1;
		scale = 0;
		#100;
		reset = 0;
		wr = 0;
		inverse = 0;
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
		x[1] = 0;
		#100;

		@(negedge clk);
		wr = 1;
		x[0] = 1;
		@(negedge clk);
		wr = 1;
		x[0] = 0;
		@(negedge clk);
		wr = 1;
		x[0] = 1;
		@(negedge clk);
		wr = 1;
		x[0] = 0;
		@(negedge clk);
		wr = 0;
		wait(done);
		
		/*
		x[0] = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x[0] = 0;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x[0] = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000
		*/
	end
endmodule