module bandpower_tb();
    parameter WIDTH = 12;
    parameter BIN_NUM = 4;
    parameter N_MAX = 4;
    parameter FRAC_BITS = 4;
    parameter BAND_NUM = 2;
    parameter BETA_STOP = 2;


    reg clk, reset,wr;
    reg signed [WIDTH-1:0] x; 
    reg signed [WIDTH-1:0] y [0:BAND_NUM-1];
    wire done;

    bandpower#(
        .WIDTH(WIDTH),
        .BIN_NUM(BIN_NUM),
        .N_MAX(N_MAX),
        .FRAC_BITS(FRAC_BITS),
        .BAND_NUM(BAND_NUM),
        .BETA_STOP(BETA_STOP)
    )UUT(
        .i_sys_clk(clk),
        .i_sys_rst(reset),
        .i_x(x),
        .i_wr(wr),
        .o_y(y),
        .o_done(done)
    );

    always #25 clk = ~clk;
	initial begin 
        $monitor("time: %t bin_counter: %b",$time,UUT.bin_counter);
        $monitor("time: %t X: %b",$time,UUT.X);
        $monitor("time: %t state: %b",$time,UUT.state);
        $monitor("time: %t DFT_done: %b",$time,UUT.DFT_done);
		clk = 0;
		reset = 1;
		#100;
		reset = 0;
		wr = 0;

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