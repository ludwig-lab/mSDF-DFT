(* use_dsp = "no" *)module DFT_ff_i(
    i_sys_clk,
    i_sys_rst,
    i_x,
    i_wr,         // high if new i_x was written to
    o_X,
    o_done,
    i_inverse,
    i_scale
);
    parameter WIDTH = 12;
    parameter BIN_NUM = 2;
    parameter N_MAX = 32;
    parameter LOG_N_MAX = $clog2(N_MAX);
    parameter FRAC_BITS = 4;

    input i_sys_clk;
    input i_sys_rst;
    input signed [WIDTH-1:0] i_x [0:1];
    input i_wr;         // high if new i_x was written to
    
    output reg signed [WIDTH-1:0] o_X [0:1];
    output reg o_done;
    input i_inverse;      // config channel, 0 is foward, 1 is backward
    input [1:0] i_scale;
    
    reg signed [WIDTH-1:0] X [0:BIN_NUM-1][0:1];
    reg [2:0] state;
    reg [$clog2(BIN_NUM):0] bin_counter;
    reg [LOG_N_MAX:0] n;
    reg sent;
    wire [LOG_N_MAX:0] k;
	(* rom_style = "block" *) reg signed [WIDTH-1:0] tabl [0:(N_MAX*2)-1];	
    reg signed [WIDTH-1:0] a,b,c;
    wire signed [WIDTH-1:0] y [0:1];
    wire [LOG_N_MAX:0] i_k [0:BIN_NUM-1];

    reg [LOG_N_MAX:0] index;
    reg signed [WIDTH-1:0] x [0:1];

    localparam RESET = 0;
	localparam START = 1;
	localparam MULTIPLY1 = 2;
	localparam MULTIPLY2 = 3;
	localparam DONE = 4;
	localparam CHECK = 5;
	localparam FINISH = 6;
    genvar i;
    generate
		for(i = 0; i < BIN_NUM; i = i + 1)begin 
            assign i_k[i] = i;
		end
	endgenerate

	initial begin
	    $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/DFT_coefficient_hex_full.txt", tabl);
        //$readmemh("../DFT_coefficient_hex_full.txt", tabl);
		//$readmemh("DFT_coefficient_hex_full.txt", tabl);
    end

    multiplier_complex#(
        .WIDTH(WIDTH)
    )multiplier(
        .i_a(a),
        .i_b(b),
        .i_c(c),
        .o_x(y),
        .i_scale(i_scale)
    );

    assign k = i_k[bin_counter];

    always@(negedge i_sys_clk) begin
        if(i_sys_rst) begin
            o_done <= 1'b0;
            o_X <= '{default: '0};
            X <= '{default: '0};
            bin_counter <= 0;
            state <= RESET;
            n <= 0;
            sent <= 0;
        end
        if(o_done & !sent)begin 
            /*
            if(i_inverse) begin 
                o_X[0] <= X[bin_counter][0] / N_MAX;
                o_X[1] <= X[bin_counter][1] / N_MAX;
            end
            else o_X <= X[bin_counter];
            */
            o_X <= X[bin_counter];
            bin_counter <= bin_counter + 1;
            if(bin_counter == (BIN_NUM-1)) begin 
                sent <= 1;
                X <= '{default: '0};
                n <= 0;
            end
        end

        case(state)
		//0
        RESET: begin
            if(i_wr) begin
                o_done <= 1'b0;
				state <= START;
				sent <= 0;
                x <= i_x;
            end
        end
		//1
		START: begin 
			state <= MULTIPLY1;
            index <= ((k*n)%(N_MAX));
		end
		//2
		MULTIPLY1: begin
            b <= x[1];
			a <= x[0];
			c <= tabl[index << 1];
			state <= MULTIPLY2;
        end
		//3
		MULTIPLY2: begin
            if(i_inverse) c <= -tabl[(index << 1)+1];
			else c <= tabl[(index << 1)+1];
			X[bin_counter][0] <= X[bin_counter][0] + y[0];
            X[bin_counter][1] <= X[bin_counter][1] + y[1];
			state <= DONE;
		end
		//4
		DONE: begin
            /*
            if(i_inverse) begin
                X[bin_counter][0] <= X[bin_counter][0] + y[1];
			    X[bin_counter][1] <= X[bin_counter][1] - y[0];
            end
            else X[bin_counter][1] <= X[bin_counter][1] + y[0];
            */
            X[bin_counter][0] <= X[bin_counter][0] - y[1];
			X[bin_counter][1] <= X[bin_counter][1] + y[0];
			state <= CHECK;
			bin_counter <= bin_counter + 1;
		end
		//5
        CHECK: begin
            if(bin_counter == BIN_NUM) begin
                state <= FINISH;
                bin_counter <= 0;
                n <= n + 1;
            end
            else begin
                state <= START;
            end
        end
		//6
        FINISH: begin
            if (n == (1<<LOG_N_MAX)) begin 
                o_done <= 1;
            end
            state <= RESET;
        end
        endcase
    end
endmodule