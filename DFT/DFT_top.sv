module DFT_top#(
	parameter WIDTH = 12,
	parameter BIN_NUM = 32,
	parameter N_MAX = 32,
	parameter LOG_N_MAX = $clog2(N_MAX)
)(
	i_sys_clk,
	i_sys_rst,
	i_x,
	i_wr,
	//i_k,
	//i_N,
	o_X,
	o_done,
	i_inverse,
	i_scale
);

    input i_sys_clk,i_sys_rst, i_wr;	// high if new i_x was written to
	//input signed [WIDTH-1:0] i_x;
	input signed [WIDTH-1:0] i_x [0:1];
    //input [LOG_N_MAX:0] i_k;
    //input [$clog2(LOG_N_MAX)-1:0] i_N;
    output reg o_done;
	output reg signed [WIDTH-1:0] o_X [1:0];
	input i_inverse;
	input [1:0] i_scale;
	wire signed [WIDTH-1:0] X [1:0];
	always@(negedge i_sys_clk)begin
		if(i_inverse)begin
			o_X[0] <= X[0] >>> LOG_N_MAX;
			o_X[1] <= X[1] >>> LOG_N_MAX;
		end
		else o_X <= X;
	end
	//wire [$clog2(LOG_N_MAX):0] i_N;
	//assign i_N = LOG_N_MAX;
	/*
	wire [LOG_N_MAX:0] i_k [0:BIN_NUM-1];
	genvar i;
	generate
		for(i = 0; i < BIN_NUM; i = i + 1)begin 
			assign i_k[i] = i;
		end
	endgenerate
	*/
	
    /*
	DFT_q#(
		.WIDTH(WIDTH),
		.BIN_NUM(BIN_NUM),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX)
	)DFT(
		.i_sys_clk(i_sys_clk),
		.i_sys_rst(i_sys_rst),
		.i_x(i_x),
		.i_wr(i_wr),
		.i_k(i_k),
		.i_N(i_N),
		.o_X(o_X),
		.o_done(o_done)
	);
	*/
	
	DFT_i_q_n#(
		.WIDTH(WIDTH),
		.BIN_NUM(BIN_NUM),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX)
	)DFT(
		.i_sys_clk(i_sys_clk),
		.i_sys_rst(i_sys_rst),
		.i_x(i_x),
		.i_wr(i_wr),
		.o_X(X),
		.i_k(i_k),
		.i_N(i_N),
		.o_done(o_done),
		.i_inverse(i_inverse),
		.i_scale(i_scale)
	);
	/*
	DFT_ff#(
		.WIDTH(WIDTH),
		.BIN_NUM(BIN_NUM),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX)
	)DFT(
		.i_sys_clk(i_sys_clk),
		.i_sys_rst(i_sys_rst),
		.i_x(i_x),
		.i_wr(i_wr),
		.o_X(o_X),
		.o_done(o_done)
	);
	*/
	
endmodule
