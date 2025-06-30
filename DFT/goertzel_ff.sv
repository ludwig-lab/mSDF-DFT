module goertzel_ff #(
    parameter N_MAX = 32,             // Number of samples in the input signal
    parameter WIDTH = 16,           // Bit width for fixed-point arithmetic
    parameter BIN_NUM = 1,            // Number of i_k values to compute in parallel
    parameter FRAC_BITS = 4,
    parameter LOG_N_MAX = $clog2(N_MAX)
) (
    i_sys_clk,                // Clock signal
    i_sys_rst,              // Reset signal
    i_x,    // Input signal (sampled data)
    i_enable,
    o_y, // Output power of the detected frequency components
    o_done
);
    input wire i_sys_clk, i_sys_rst,  i_enable;         
    wire [$clog2(N_MAX):0] i_k;
    input wire signed [WIDTH-1:0] i_x;    
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output reg o_done;

    // Internal signals
    reg signed [WIDTH-1:0] q1 [0:BIN_NUM-1];
    reg signed [WIDTH-1:0] q3 [0:BIN_NUM-1];
    reg signed [WIDTH-1:0] q2 [0:BIN_NUM-1];
    reg signed [WIDTH-1:0] x;
    integer i, j;
    // Coefficient LUT
    wire signed [WIDTH-1:0] cosine [(BIN_NUM)-1:0];	
    wire signed [WIDTH-1:0] sine [(BIN_NUM)-1:0];	
    reg [$clog2(BIN_NUM)-1:0] bin_counter;
    reg [$clog2(N_MAX)-1:0] n;

    // Compute the coefficients for all i_k values
    genvar m;
    generate
        for (m = 0; m < BIN_NUM; m = m + 1) begin
            assign cosine[m+1] = $rtoi($cos(2*3.1415*(m+1)/N_MAX)*(1<<FRAC_BITS));
            assign sine[m+1] = $rtoi($sin(2*3.1415* (m+1)/N_MAX)*(1<<FRAC_BITS));
        end
    endgenerate

    always@(negedge i_sys_clk)begin
        if (i_sys_rst) begin
            bin_counter <= 0;
            o_y = '{default: '0};
        end
        if (o_done & i_enable) begin
            o_y[0] = q1[bin_counter] - ((q2[bin_counter] * cosine[bin_counter]) >>> (FRAC_BITS));
            o_y[1] = (q2[bin_counter] * sine[bin_counter])>>> (FRAC_BITS);
            if(bin_counter == BIN_NUM-1) bin_counter = 0;
            else bin_counter = bin_counter + 1;
        end
    end

    always @(negedge i_sys_clk) begin
        if (i_sys_rst) begin
            q1 = '{default: '0};
            q2 = '{default: '0};
            q3 = '{default: '0};
            n = 0;
            o_done = 0;
        end else if (i_enable)begin
            x = i_x;
            for (j = 0; j < BIN_NUM; j = j + 1) begin
                q3[j] = x + ((2*cosine[j] * q1[j]) >>> (FRAC_BITS)) - q2[j];
                q2[j] = q1[j];
                q1[j] = q3[j];    
            end
            if (n == N_MAX-1) o_done = 1;
            else n = n + 1;
        end
    end

endmodule