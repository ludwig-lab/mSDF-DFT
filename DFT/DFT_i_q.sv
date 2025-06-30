(* use_dsp = "no" *)module DFT_i_q(
    i_sys_clk,
    i_sys_rst,
    i_x,
    i_wr,         // high if new i_x was written to
    i_k,
    i_N,
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
    parameter Q = N_MAX/4;

    input i_sys_clk;
    input i_sys_rst;
    input signed [WIDTH-1:0] i_x [0:1];
    input i_wr;         // high if new i_x was written to
    input [LOG_N_MAX:0] i_k;
    input [$clog2(LOG_N_MAX)-1:0] i_N;
    output reg signed [WIDTH-1:0] o_X [0:1];
    output reg o_done;
    input i_inverse;
    input [1:0] i_scale;
    
    reg signed [WIDTH-1:0] X [0:BIN_NUM-1][0:1];
    reg [2:0] state;
    reg [$clog2(BIN_NUM):0] bin_counter;
    reg [LOG_N_MAX-1:0] n;
    reg sent;
    reg [LOG_N_MAX-1:0] k;
    (* rom_style = "block" *) reg [LOG_N_MAX-1:0] k_table [0:BIN_NUM-1];
    wire signed [WIDTH-1:0] pf [1:0];
    reg signed [WIDTH-1:0] a,b,c;
    wire signed [WIDTH-1:0]y[0:1];
    reg signed [WIDTH-1:0] x [0:1];
    (* rom_style = "block" *) reg signed [WIDTH-1:0] cos [0:Q-1];	
    (* rom_style = "block" *) reg signed [WIDTH-1:0] sine [0:Q-1];	
    
    wire [LOG_N_MAX-1:0] index;
    reg set_k;
    localparam RESET = 0;
	localparam START = 1;
	localparam MULTIPLY1 = 2;
	localparam MULTIPLY2 = 3;
	localparam DONE = 4;

    reg timer;

	initial begin
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/sine.txt", sine);
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/cos.txt", cos);
        // $readmemh("../DFT_coefficient_hex.txt", tabl);
    end
    reg signed [WIDTH-1:0] r,i;
    assign index = ((k*n) << (LOG_N_MAX-i_N))%(N_MAX);

	pfTable#(
        .WIDTH(WIDTH),
        .N_MAX(N_MAX)
    )pfTable(
        .i_index(index),
        .i_sys_clk(i_sys_clk),
        .o_c(pf),
        .i_r(r),
        .i_i(i)
    );

    multiplier_complex#(
        .WIDTH(WIDTH)
    )multiplier(
        .i_a(a),
        .i_b(b),
        .i_c(c),
        .o_x(y),
        .i_scale(i_scale)
    );
    
    always@(negedge i_sys_clk) begin
        if(i_sys_rst) begin
            o_done <= 1'b0;
            //o_X <= '{default: '0};
            X <= '{default: '0};
            bin_counter <= 0;
            state <= RESET;
            n <= 0;
            sent <= 0;
            set_k <= 0;
            //k_table <= '{default: '0};
            timer <= 0;
        end
        if(o_done & !sent)begin 
            o_X <= X[bin_counter];
            bin_counter <= bin_counter + 1;
            if(bin_counter == (BIN_NUM-1)) begin 
                sent <= 1;
                X <= '{default: '0};
                n <= 0;
            end
        end

        if(i_k == N_MAX) set_k <= 1;
        if(set_k == 1)begin
            k_table[bin_counter] <= i_k[LOG_N_MAX-1:0];
            if(bin_counter == BIN_NUM-1) begin
                set_k <= 0;
                bin_counter <= 0;
                n <= 0;
            end
            else bin_counter <= bin_counter + 1;
        end

        case(state)
		//0
        RESET: begin
            if(i_wr) begin
                o_done <= 1'b0;
				state <= START;
                x <= i_x;
                sent <= 0;
            end
        end
		//1
		START: begin 
            timer <= timer + 1;
            if (timer == 1) state <= MULTIPLY1;
		end

		//2
		MULTIPLY1: begin
            timer <= 0;
			b <= x[1];
			a <= x[0];
			c <= pf[0];
			state <= MULTIPLY2;
        end
		//3
		MULTIPLY2: begin
			if(i_inverse) c <= -pf[1];
			else c <= pf[1];
			X[bin_counter][0] <= X[bin_counter][0] + y[0];
            X[bin_counter][1] <= X[bin_counter][1] + y[1];
			state <= DONE;
		end
		//4
		DONE: begin
			X[bin_counter][0] <= X[bin_counter][0] - y[1];
			X[bin_counter][1] <= X[bin_counter][1] + y[0];
            if(bin_counter == BIN_NUM - 1) begin
                if (n == ((1<<i_N)-1)) o_done <= 1;
                else n <= n + 1;
                bin_counter <= 0;
                state <= RESET;
            end else begin
                bin_counter <= bin_counter + 1;
                state <= START;
            end
		end
        endcase
    end


    always@(negedge i_sys_clk) begin
        k <= k_table[bin_counter];
        r <= cos[index % Q];
        i <= sine[index % Q];
    end
endmodule