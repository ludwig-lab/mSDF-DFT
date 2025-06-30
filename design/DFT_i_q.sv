// ============================================================================
// Module Name      : DFT_i_q
// Description      : Computes the runtime configurable variant of the DFT. The 
//                    indices of the frequency bins to be computed can be 
//                    changed during runtime. 

//                    i means this module can perform iDFT. 

//                    q means this module stores only a quarter of the full
//                    twiddle factor table and multiplies by -i during runtime
//                    to obtain the next quarter. 
// Author           : Richard Yang
// Date             : Sep/8/2024
// Version          : 1.0
// File             : DFT_i_q.sv
// ----------------------------------------------------------------------------
// Revision History:
// ----------------------------------------------------------------------------
// | Version | Author      | Date        | Changes                            |
// |---------|-------------|-------------|------------------------------------|
// | 1.0     | Richard Yang| Sep/8/2024  | Initial creation                   |
// ----------------------------------------------------------------------------
// Inputs:
// ----------------------------------------------------------------------------
// | Name          | Width | Description                                      |
// |---------------|-------|--------------------------------------------------|
// | i_sys_clk     | 1     | system clock                                     |
// | i_sys_rst     | 1     | reset signal                                     |
// | i_x           |WIDTH*2| input stream                                     |
// | i_k           |Log2(N_MAX)| runtime configuration of bin index           |
// | i_wr          | 1     | pulled up when a new sample arrive (input clock) |         
// | i_N           |Log2(N_MAX)| runtime configuration of point size          |
// | i_inverse     | 1     | 0 for forward, 1 for backward                    |
// | i_scale       | 3     | scaling schedule to prevent overflow             |
// ----------------------------------------------------------------------------
// Outputs:
// ----------------------------------------------------------------------------
// | Name          | Width | Description                                      |
// |---------------|-------|--------------------------------------------------|
// | o_X           |WIDTH*2| output stream                                    |
// | o_done        | 1     | done signal                                      |
// ----------------------------------------------------------------------------
// Parameters:
// ----------------------------------------------------------------------------
// | Name          | Default | Description                                    |
// |---------------|---------|------------------------------------------------|
// | WIDTH         | 12      | precision of operations and data               |
// | BIN_NUM       | 2       | number of frequency bins to compute            |
// | N_MAX         | 32      | point size (length of transform window)        |
// | FRAC_BITS     | 4       | number of fractional bits                      |
// ----------------------------------------------------------------------------
// Additional Notes:
// path to the txt file for cos and sine may need to be changed 
// 
// i_k needs to be set to N_MAX to activate index configuration mode. Example:
// N_MAX, k0, k1, k2, k3 ... 
//
// The following is the pesudo code.
// 
// For each x in input{
//      For each bin in bins{
//          multiply;
//          add;
//      };
// };
// ============================================================================

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
    parameter FRAC_BITS = 4;
    parameter Q = N_MAX/4;// not a true parameter, precalculated for convenience
    parameter LOG_N_MAX = $clog2(N_MAX);// not a true parameter, precalculated for convenience

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
    
    // output accumulartor
    reg signed [WIDTH-1:0] X [0:BIN_NUM-1][0:1];
    // store the current state 
    reg [2:0] state;
    /*
    track the current index frequency bin. Note this tracks only the bins that
    we want to compute, NOT the total number of bins. 
    */
    reg [$clog2(BIN_NUM):0] bin_counter;
    // track the current index in the time domain
    reg [LOG_N_MAX-1:0] n;
    // track whether the output has been sent
    reg sent;
    // track the current index in the frequency domain
    reg [LOG_N_MAX-1:0] k;
    // stores the current set of frequency bin indices to be transformed
    (* rom_style = "block" *) reg [LOG_N_MAX-1:0] k_table [0:BIN_NUM-1];
    // hold the current twiddle factor
    wire signed [WIDTH-1:0] pf [1:0];
    // hold the inputs of the multiplier module
    reg signed [WIDTH-1:0] a,b,c;
    // hold the output of the multiplier module
    wire signed [WIDTH-1:0]y[0:1];
    // latch the input stream
    reg signed [WIDTH-1:0] x [0:1];
    // ROM for twiddle factor
    (* rom_style = "block" *) reg signed [WIDTH-1:0] cos [0:Q-1];	
    (* rom_style = "block" *) reg signed [WIDTH-1:0] sine [0:Q-1];	
    // index of the twiddle factor in the table
    wire [LOG_N_MAX-1:0] index;
    // 1 indicates k_table needs to be updated 
    reg set_k;
    // Internal states
    localparam RESET = 0;
	localparam START = 1;
	localparam MULTIPLY1 = 2;
	localparam MULTIPLY2 = 3;
	localparam DONE = 4;
    // delay timer
    reg timer;

	initial begin
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/sine.txt", sine);
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/cos.txt", cos);
        // $readmemh("../DFT_coefficient_hex.txt", tabl);
    end
    reg signed [WIDTH-1:0] r,i;
    assign index = ((k*n) << (LOG_N_MAX-i_N))%(N_MAX);

    // outputs the twiddle factor
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

    // multiply core
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
        // send output
        if(o_done & !sent)begin 
            o_X <= X[bin_counter];
            bin_counter <= bin_counter + 1;
            if(bin_counter == (BIN_NUM-1)) begin 
                sent <= 1;
                X <= '{default: '0};
                n <= 0;
            end
        end

        /*
        i_k needs to be set to N_MAX to activate index configuration mode. 
        */
        if(i_k == N_MAX) set_k <= 1;
        // read in the indices at runtime
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
        /*
        this needs one more cycle of delay when compared to the fully fixed
        variant since one cycle is needed to access k_table and another to 
        compute pf. 
        */
		START: begin 
            timer <= timer + 1;
            if (timer == 1) state <= MULTIPLY1;
		end

		//2
        /*
        multiply input by the real component of the twiddle factor
        (a+ib)*cos
        */ 
		MULTIPLY1: begin
            timer <= 0;
			b <= x[1];
			a <= x[0];
			c <= pf[0];
			state <= MULTIPLY2;
        end
		//3
        /* 
        1. accumulate the real components
        2. multiply input by the imgainary component of the twiddle factor
        (a+ib)*isin
        Note that since we pass in a imaginary c, the output is reversed: y[0]
        is the imaginary component and y[1] is the real component
        */
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
            // Check if the current bin is complete
            if(bin_counter == BIN_NUM - 1) begin
                // check if the entire window is complete
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

    // fetch the real and imaginary components of the twiddle factors in the 
    // quarter table
    always@(negedge i_sys_clk) begin
        k <= k_table[bin_counter];
        r <= cos[index % Q];
        i <= sine[index % Q];
    end
endmodule