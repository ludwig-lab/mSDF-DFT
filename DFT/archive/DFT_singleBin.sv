module DFT_singleBin(
    i_sys_clk,
    i_sys_rst,
    i_x,
    i_wr,         // high if new i_x was written to
    i_k,
    i_N,
    i_n,
    o_X,
    o_done
);
	parameter WIDTH = 12;
    parameter N_MAX = 1024;
    parameter LOG_N_MAX = 10;
    parameter FRAC_BITS = 6;

    input i_sys_clk;
    input i_sys_rst;
    input signed [WIDTH-1:0] i_x;
    input i_wr;         // high if new i_x was written to
    input [15:0] i_k;
    input [15:0] i_N;
    input [15:0] i_n;
    output reg signed [WIDTH-1:0] o_X[1:0];
    output reg o_done;

	reg signed [WIDTH-1:0] tabl [(N_MAX*2)-1:0];	
    reg signed [WIDTH-1:0] a,b;
    wire signed [WIDTH-1:0]x;
    reg [2:0] state;
    
    //wire signed [0:WIDTH-1] c [0:1];


	localparam READY = 0;
    localparam MULTIPLY1 = 1;
    localparam MULTIPLY2 = 2;
    localparam DONE = 3;
    reg [31:0] index;

    multiplier#(
        .WIDTH(WIDTH)
    )multiplier(
        .i_a(a),
        .i_b(b),
        .o_x(x)
    );
	//defparam multiplier.WIDTH = WIDTH;

	initial begin
        $readmemh("../DFT_coefficient_hex_full.txt", tabl);
		//$readmemh("DFT_coefficient_hex_full.txt", tabl);
    end
    
    always@(negedge i_sys_clk) begin
        if (i_sys_rst) begin
            state = READY;
            o_done = 1'b0;
            o_X[0] = 0;
			o_X[1] = 0;
        end
        case (state)
            READY: begin
                if(i_wr) state = MULTIPLY1;
                index = ((i_k*i_n) << (LOG_N_MAX-i_N))%(N_MAX);
                o_done = 1'b0;
            end

            MULTIPLY1: begin
                a = $signed(i_x);
                b = $signed(tabl[index << 1]);
                state = MULTIPLY2;
            end

            MULTIPLY2: begin
                b = $signed(tabl[(index << 1)+1]);
                o_X[0] = x;
                state = DONE;
            end

            DONE: begin
                o_X[1] = x;
                o_done = 1'b1;
                state = READY;
            end
        endcase
    end
endmodule