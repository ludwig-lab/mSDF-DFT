`timescale 1ns/1ns  

module DFT_i_tb();
	parameter WIDTH = 12;
	parameter BIN_NUM = 128;
	parameter N_MAX = 128;
	parameter LOG_N_MAX = $clog2(N_MAX);
	parameter FRAC_BITS = 5;

	reg clk, reset, wr;
	reg [$clog2(LOG_N_MAX)-1:0] N;
	reg [LOG_N_MAX:0] k;
	reg signed [WIDTH-1:0] x [0:1];
	wire signed [WIDTH-1:0] o_X [0:1];
	reg inverse;
	wire done;
	reg [2:0] scale;
	reg [WIDTH-1:0] x_buffer [0:N_MAX-1];
	reg [WIDTH-1:0] forward_real [0:N_MAX-1];
	reg [WIDTH-1:0] forward_img [0:N_MAX-1];


	always #25 clk = ~clk;

	DFT_ff_i_q#(
		.WIDTH(WIDTH),
		.BIN_NUM(BIN_NUM),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX),
		.FRAC_BITS(FRAC_BITS)
	) UUT(
		.i_sys_clk(clk),
		.i_sys_rst(reset),
		.i_x(x),
		.i_wr(wr),
		//.i_k(k),
		//.i_N(N),
		.o_X(o_X),
		.o_done(done),
		.i_inverse(inverse),
		.i_scale(scale)
	);
	integer i;
	initial begin 
		$readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/LFP_128.txt",x_buffer);
		$readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/forward_real.txt",forward_real);
		$readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/forward_img.txt",forward_img);
		//$monitor("time %t, X[0] %h", $time,UUT.X[0]);
		//$monitor("time %t, X[1] %h", $time,UUT.X[1]);
		//$monitor("time %t, X[2] %h", $time,UUT.X[2]);
		//$monitor("time %t, X[3] %h", $time,UUT.X[3]);
		//$monitor("time %t, y %h", $time,UUT.y);
		//$monitor("time %t, n %h", $time,UUT.n);
		//$monitor("time %t, k %h", $time,UUT.k);
		//$monitor("time %t, i_x %h %h", $time,UUT.i_x[0],UUT.i_x[1]);
		//$monitor("time %t, pf_real %h, pf_img %h", $time,UUT.pf[0],UUT.pf[1]);
		//$monitor("time %t, bin_counter %h", $time,UUT.bin_counter);
		//$monitor("time %t, k_table %h %h %h %h", $time,UUT.k_table[0],UUT.k_table[1],UUT.k_table[2],UUT.k_table[3]);
		//$monitor("time %t, pf %h", $time,UUT.tabl[32]);
		//$monitor("time %t, state %d", $time,UUT.state);
	 	//$monitor("%d", UUT.o_X[1]);
	 	//$monitor("time %t, index %d", $time,UUT.index);
		clk = 0;
		reset = 1;
		scale = 7;
		#100;
		reset = 0;
		wr = 0;
		inverse = 1;
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

        
		for(i = 0; i < 128; i = i+1)begin
			//x[0] = x_buffer[i];
			x[0] = ((forward_real[i]));
			x[1] = ((forward_img[i]));
			wr = 1;
			#50;
			wr = 0;
			#30000;
		end
		
		
		
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
		
		

		wait(done==1);
		
		
		for(i = 0; i < 128; i = i+1)begin
			$display("%d", UUT.X[i][0]);
		end
		#10000;
		


		x[1] = 0;
		inverse = 1;

		x[0] = 'h002;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x[0] = 1;
		x[1] = 1;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x[0] = 0;
		x[1] = 0;
		wr = 1;
		#50;
		wr = 0;
		#3000;

		x[0] = 1;
		x[1] = 'hFFF;
		wr = 1;
		#50;
		wr = 0;
		#3000

		wait(done);
		#100;
		$finish;
	end
endmodule