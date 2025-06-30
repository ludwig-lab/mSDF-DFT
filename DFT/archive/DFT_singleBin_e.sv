module DFT_singleBin_e#(
	parameter WIDTH = 8,
    parameter N_MAX = 1024,
    parameter LOG_N_MAX = 10
	)
(
    input i_sys_clk,
    input i_reset,
    input signed [0:WIDTH-1] i_x,
    input i_wr,         // high if new i_x was written to
    input [0:WIDTH-1] i_k,
    input [0:WIDTH-1] i_N,
    input [0:WIDTH-1] i_n,
    output reg signed [0:WIDTH-1] o_X[0:1],
    output reg o_done
);

	reg signed [0:WIDTH-1] tabl [0:(N_MAX*2)-1];	
    reg signed [0:WIDTH-1] a,b;
    wire signed [0:WIDTH-1]x;
	wire signed [0:WIDTH-1] c [0:1];
    reg [0:2] state;
    reg [0:WIDTH-1] index;
	reg table_reset;

	localparam READY = 0;
    localparam MULTIPLY1 = 1;
    localparam MULTIPLY2 = 2;
    localparam DONE = 3;

    multiplier multiplier(
        .i_a(a),
        .i_b(b),
        .o_x(x)
    );
	defparam multiplier.WIDTH = WIDTH;

	coefTabl coefTabl(
		.i_index(index),
		.i_sys_clk(i_sys_clk),
		.i_reset(table_reset),
		.o_c(c),
		.o_done(table_done)
	);
	defparam coefTabl.WIDTH = WIDTH;
	defparam coefTabl.N_MAX = N_MAX;
	defparam coefTabl.Q = N_MAX / 4;
    
    always@(negedge i_sys_clk) begin
        if (i_reset) begin
            state <= READY;
            o_done <= 1'b0;
            o_X[0] <= 0;
			o_X[1] <= 0;
        end
        case (state)
            READY: begin
                if(i_wr) state <= MULTIPLY1;
                index <= ((i_k*i_n) << (LOG_N_MAX-i_N));
				table_reset <= 1;
                o_done <= 1'b0;
            end

            MULTIPLY1: begin
				table_reset <= 0;
				if (table_done) begin
					a <= i_x;
					b <= c[0];
					state <= MULTIPLY2;
				end
			end

            MULTIPLY2: begin
                b <= c[1];
                o_X[0] <= x;
                state <= DONE;
            end

            DONE: begin
                o_X[1] <= x;
                o_done <= 1'b1;
                state <= READY;
            end
        endcase
    end

endmodule