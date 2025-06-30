module top_test(
	i_ref_clk,
	i_rst,
	o_X,
	done
);
	parameter DFT_WIDTH = 16;
    parameter N_MAX = 1024;
    parameter LOG_N_MAX = 10;
    parameter FRAC_BITS = 6;

	//IOs
	input i_ref_clk, i_rst;
	output reg signed [DFT_WIDTH-1:0] o_X[1:0];
	output done;

	wire sys_rst, sys_clk;
    reg signed [SPI_WIDTH-1:0]x;
  	reg signed [DFT_WIDTH-1:0]k,n;
    wire signed [DFT_WIDTH-1:0] X [1:0];
	reg wr;  
    wire [DFT_WIDTH-1:0] N;

	assign sys_rst = ~i_rst;
	assign N = 2;

	always@(negedge sys_clk) begin
		if(done)begin
            o_X[0] = X[0] >>> FRAC_BITS;
            o_X[1] = X[1] >>> FRAC_BITS;
        end
		if(sys_rst) begin
            o_X = '{default: '0};
            x = -1;
            wr = 1;
            k = 0;
            n = 0;
        end
	end
	
	DFT_singleBin#(
        .WIDTH(DFT_WIDTH),
        .N_MAX(N_MAX),
        .LOG_N_MAX(LOG_N_MAX),
        .FRAC_BITS(FRAC_BITS)
    ) DFT(
		.i_sys_clk(sys_clk),
		.i_reset(sys_rst),
		.i_x(x),
		.i_wr(wr),
		.i_k(k),
		.i_N(N),
		.i_n(n),
		.o_X(X),
		.o_done(done)
	);
	   
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0100),
        .DIVF('b0101111),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b010)
    )pll(
        .REFERENCECLK(i_ref_clk),
        .PLLOUTCORE(sys_clk),
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );
endmodule