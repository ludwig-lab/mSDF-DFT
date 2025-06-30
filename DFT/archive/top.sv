module top(
	i_ref_clk,
	i_rst,
	i_mosi,
	o_miso,
	i_ss,
	i_sclk,
	o_X,
	o_done,
	singleBin_done,
	//singleBin_out,
	rx_ready,
	a,
	b,
	mul_out,
	i_k,
	i_N
);
	parameter SPI_WIDTH = 8;
	parameter DFT_WIDTH = 12;
	parameter BIN_NUM = 1;
	parameter N_MAX = 1024;
	parameter LOG_N_MAX = 10;
	parameter FRAC_BITS = 4;

	//IOs
	input i_ref_clk, i_rst, i_mosi, i_ss, i_sclk;
	output o_miso;
	output reg signed [DFT_WIDTH-1:0] o_X [BIN_NUM-1:0][1:0];
	output o_done;
	output wire signed [DFT_WIDTH-1:0] singleBin_out [1:0];
	output singleBin_done;
	//output signed [DFT_WIDTH-1:0] a,b;
	wire signed [SPI_WIDTH - 1:0] spi_data;
	output wire signed [DFT_WIDTH-1:0] x;
	output wire rx_ready;
	output reg signed [DFT_WIDTH-1:0] a,b;
 	output wire signed [DFT_WIDTH-1:0] mul_out;
	input wire [15:0] i_k [BIN_NUM-1:0];
	input wire [15:0] i_N;

	wire sys_rst, sys_clk;
	reg DFT_rst;
	wire [DFT_WIDTH-1:0] X [BIN_NUM-1:0][1:0];
	//output wire signed [DFT_WIDTH - 1:0] x;
	assign sys_rst = ~i_rst;
	
	/*
	assign i_N = 2;
	genvar i;
	generate
		for(i = 0; i < BIN_NUM; i = i + 1) begin 
			assign i_k[i] = i;
		end
	endgenerate
	*/

	/*
	F_PLLIN:   100.000 MHz (given)
	F_PLLOUT:   16.000 MHz (requested)
	F_PLLOUT:   16.016 MHz (achieved)

	FEEDBACK: SIMPLE
	F_PFD:   25.000 MHz
	F_VCO: 1025.000 MHz

	DIVR:  3 (4'b0011)
	DIVF: 40 (7'b0101000)
	DIVQ:  6 (3'b110)

	FILTER_RANGE: 2 (3'b010)
	*/

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0011),
        .DIVF(7'b0101000),
        .DIVQ(3'b110),
        .FILTER_RANGE(3'b010)
    )pll(
        .REFERENCECLK(i_ref_clk),
        .PLLOUTCORE(sys_clk),
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

	always@(negedge sys_clk) begin
		o_X <= X;
		/*
		if(o_done) begin
			o_X <= X;
			//DFT_rst <= 1;
		end
		*/
		if(sys_rst) begin 
			o_X <= '{default: '0};
			//DFT_rst <= 0;
		end
	end

	DFT_SPI#(
		.SPI_WIDTH(SPI_WIDTH),
		.DFT_WIDTH(DFT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.N_MAX(N_MAX),
		.LOG_N_MAX(LOG_N_MAX),
		.FRAC_BITS(FRAC_BITS)
	) DFT(
		.i_sys_clk(sys_clk),
		.i_sys_rst(sys_rst),
		.i_mosi(i_mosi),
		.o_miso(o_miso),
		.i_ss(i_ss),
		.i_sclk(i_sclk),
		.o_X(X),
		.i_N(i_N),
		.o_done(o_done),
		.singleBin_out(singleBin_out),
		.singleBin_done(singleBin_done),
		.x(x),
		.rx_ready(rx_ready),
		.a(a),
		.b(b),
		.mul_out(mul_out),
		.i_k(i_k)
	);
	//defparam DFT.SPI_WIDTH = SPI_WIDTH;
	//defparam DFT.DFT_WIDTH = DFT_WIDTH;
	//defparam DFT.BIN_NUM = BIN_NUM;
	//defparam DFT.N_MAX = N_MAX;
	//defparam DFT.LOG_N_MAX = LOG_N_MAX;
	//defparam DFT.FRAC_BITS = FRAC_BITS;
	

	/*
	wire [0:DFT_WIDTH-1] x,k,n;
	wire wr;
	DFT_singleBin DFT(
		.i_sys_clk(sys_clk),
		.i_reset(sys_rst),
		.i_x(x),
		.i_wr(wr),
		.i_k(k),
		.i_N(N),
		.i_n(n),
		.o_X(o_X),
		.o_done(done)
	);
	

	assign x = 1;
	assign k = 3;
	assign n = 3;
	assign wr = 1;
	*/
endmodule