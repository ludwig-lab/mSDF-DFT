// ============================================================================
// Module Name      : DFT_ff_i_q
// Description      : Computes the fully fixed variant of the DFT. The indices 
//                    of the frequency bins to be computed must be defined at 
//                    synthesis and cannot be changed during runtime. 

//                    i means this module can perform iDFT. 

//                    q means this module stores only a quarter of the full
//                    twiddle factor table and multiplies by -i during runtime
//                    to obtain the next quarter. 
// Author           : Richard Yang
// Date             : Sep/8/2024
// Version          : 1.0
// File             : DFT_ff_i_q.sv
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
// | i_wr          | 1     | pulled up when a new sample arrive (input clock) |         
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
// The following is the pesudo code.
// 
// For each x in input{
//      For each bin in bins{
//          multiply;
//          add;
//      };
// };
// ============================================================================

(* use_dsp = "no" *)module DFT_ff_i_q(
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
    parameter FRAC_BITS = 4;
    parameter Q = N_MAX/4;                  // not a true parameter, precalculated for convenience
    parameter LOG_N_MAX = $clog2(N_MAX);    // not a true parameter, precalculated for convenience

    input i_sys_clk;
    input i_sys_rst;
    input signed [WIDTH-1:0] i_x [0:1];
    input i_wr;         // high if new i_x was written to
    input i_inverse;      // config channel, 0 is foward, 1 is backward
    input [2:0] i_scale;
    output reg signed [WIDTH-1:0] o_X [0:1];
    output reg o_done;
    
    // output accumulator 
    reg signed [WIDTH-1:0] X [0:BIN_NUM-1][0:1];
    // store the current state 
    reg [2:0] state;
    /*
    track the current index frequency bin. Note this tracks only the bins that
    we want to compute, NOT the total number of bins. 
    */
    reg [$clog2(BIN_NUM)-1:0] bin_counter;
    // track the current index in the time domain
    reg [LOG_N_MAX:0] n;
    // track whether the output has been sent
    reg sent;
    // track the current index in the frequency domain
    wire [LOG_N_MAX:0] k;
    // ROM for twiddle factors
	(* rom_style = "block" *) reg signed [WIDTH-1:0] cos [0:Q-1];	
    (* rom_style = "block" *) reg signed [WIDTH-1:0] sine [0:Q-1];
    // hold the current twiddle factor
    wire signed [WIDTH-1:0] pf [1:0];
    // hold the inputs of the multiplier module
    reg signed [WIDTH-1:0] a,b,c;
    // hold the output of the multiplier module
    wire signed [WIDTH-1:0] y [0:1];
    // hold the array of frequency indices to transform
    wire [LOG_N_MAX:0] i_k [0:BIN_NUM-1];
    // index of the twiddle factor in the table
    wire [LOG_N_MAX:0] index;
    // latch the input stream
    reg signed [WIDTH-1:0] x [0:1];
    // real and imaginary component of the input to pfTable
    reg signed [WIDTH-1:0] r,i;
    // compute the index of twiddle factor in the pfTable
    assign index = (k*n)%N_MAX;

    // Internal states
    localparam RESET = 0;
	localparam START = 1;
	localparam MULTIPLY1 = 2;
	localparam MULTIPLY2 = 3;
	localparam DONE = 4;
	localparam CHECK = 5;
	localparam FINISH = 6;
    localparam WAIT = 7;

    // configure indices of frequency bins
    genvar m;
    generate
		for(m = 0; m < BIN_NUM; m = m + 1)begin 
            assign i_k[m] = m;
		end
	endgenerate

    // read in the twiddle factor table
	initial begin
	    $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/sine.txt", sine);
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/cos.txt", cos);
        //$readmemh("../DFT_coefficient_hex_full.txt", tabl);
		//$readmemh("DFT_coefficient_hex_full.txt", tabl);
    end

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
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS)
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
            // This logic is currently implement in DFT_top.sv. Though it can
            // be implemented here instead. 
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
                x <= i_x;
                sent <= 0;
            end
        end
		//1
        /*
        Adds a delay so that pf can be fetched. This needs one less clock cycle
        when compared to the runtime configurable variant since i_k is defined
        as an array of wire here and does not require an additional cycle to 
        access
        */
		START: begin 
            state <= MULTIPLY1;
		end

		//2
        /*
        multiply input by the real component of the twiddle factor
        (a+ib)*cos
        */ 
		MULTIPLY1: begin
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
        DONE: begin
			X[bin_counter][0] <= X[bin_counter][0] - y[1];
			X[bin_counter][1] <= X[bin_counter][1] + y[0];
            // Check if the current bin is complete
            if(bin_counter == BIN_NUM - 1) begin
                // check if the entire window is complete
                if (n == ((1<<LOG_N_MAX)-1)) o_done <= 1;
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
        r <= cos[index % Q];
        i <= sine[index % Q];
    end
endmodule