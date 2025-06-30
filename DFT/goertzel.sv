module goertzel #(
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
    i_k,
    i_N,
    o_done,
    o_ready
);
    input wire i_sys_clk, i_sys_rst,  i_enable;         
    input wire signed [WIDTH-1:0] i_x;    
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output o_done;
    input [LOG_N_MAX:0] i_k;
    input [$clog2(LOG_N_MAX):0] i_N;
    output o_ready;

    // Internal signals
    reg signed [WIDTH-1:0] q1 [0:BIN_NUM-1];
    reg signed [WIDTH-1:0] q3 [0:BIN_NUM-1];
    reg signed [WIDTH-1:0] q2 [0:BIN_NUM-1];
    reg signed [WIDTH-1:0] x;
    wire [BIN_NUM-1:0] done;
    // Coefficient LUT	
    reg [LOG_N_MAX-1:0] k_table [BIN_NUM-1:0];
    reg signed [WIDTH-1:0] y [BIN_NUM-1:0][1:0]; 
    reg [$clog2(BIN_NUM)-1:0] bin_counter;
    reg set_k;
    reg sent;
    reg ready;
    assign o_done = done[0];
    wire [BIN_NUM-1: 0] singleBin_ready;
    assign o_ready = ready;

    always@(negedge i_sys_clk)begin
        if (i_sys_rst) begin
            bin_counter <= 0;
            o_y <= '{default: '0};
            sent <= 0;
            ready <= 0;
            set_k <= 0;
        end

        if(i_k == N_MAX) set_k <= 1;
        if(set_k == 1)begin
            k_table[bin_counter] <= i_k[LOG_N_MAX-1:0];
            if(bin_counter == BIN_NUM-1) begin
                set_k <= 0;
                bin_counter <= 0;
                ready <= 1;
            end
            else bin_counter <= bin_counter + 1;
        end
        if(o_done & !sent)begin 
            o_y <= y[bin_counter];
            if(bin_counter == (BIN_NUM-1)) begin 
                sent <= 1;
                bin_counter <= 0;
            end
            else bin_counter <= bin_counter + 1;
        end
    end

    genvar i;
    generate
        for (i = 0; i < BIN_NUM; i = i + 1) begin: gen_single
            goertzel_singleBin#(
                .N_MAX(N_MAX),
                .WIDTH(WIDTH),
                .FRAC_BITS(FRAC_BITS),
                .LOG_N_MAX(LOG_N_MAX)
            )goertzel_singleBin(
                .i_sys_clk(i_sys_clk),
                .i_sys_rst(i_sys_rst),
                .i_x(i_x),
                .i_N(i_N),
                .i_k(k_table[i]),
                .o_done(done[i]),
                .i_enable(i_enable),
                .o_y(y[i])
            );
        end
    endgenerate
endmodule