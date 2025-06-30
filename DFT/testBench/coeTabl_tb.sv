module coeTabl_tb();
    parameter WIDTH = 12;

    reg clk, reset;
    wire done;
    wire signed [0:WIDTH-1] c [0:1];
	wire [0:2] state;
	wire [0:1] quarter;
	reg [0:WIDTH-1] index;
	wire [0:WIDTH-1] temp, index_quarter;
    integer i,j;

    always #25 clk = !clk;

    coefTabl coefTabl(
		.i_index(index),
		.i_sys_clk(clk),
		.i_reset(reset),
		.o_c(c),
		.o_done(done),
		.quarter(quarter),
		.state(state),
		.index_quarter(index_quarter)
	);
    initial begin
        clk = 0;
        reset = 1;
		index = 0;
        #50;
        reset = 0;
        for (i = 0; i < 4; i = i + 1) begin
			reset = 1;
			#50;
			reset = 0;
			@(done);
			#100;
			index = index + 256;
        end
        $finish;
    end
    
endmodule