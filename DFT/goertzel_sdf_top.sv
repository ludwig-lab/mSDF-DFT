module goertzel_sdf_top(
    i_sys_clk,             
    i_sys_rst,           
    o_y,
    i_x,
    i_k,
    i_wr,
    i_N,
    o_done
);
    parameter WIDTH = 12;
    parameter N_MAX = 32768;
    parameter BIN_NUM = 64;
    parameter LOG_N_MAX = $clog2(N_MAX);

    input i_sys_clk, i_sys_rst, i_wr; 
    input signed [WIDTH-1:0] i_x;
    input [$clog2(N_MAX):0] i_k;
    input [$clog2(LOG_N_MAX)-1:0] i_N;
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output reg o_done;

    goertzel_sdf_ff#(
        .WIDTH(WIDTH),
        .N_MAX(N_MAX),
        .BIN_NUM(BIN_NUM),
        .FRAC_BITS(4)
    ) UUT(
        .i_sys_clk(i_sys_clk),             
        .i_sys_rst(i_sys_rst),           
        .i_x(i_x),   
        .o_y(o_y),
        //.i_k(i_k),
        .i_wr(i_wr),
        .o_done(o_done)
        //.i_N(i_N)
    );
endmodule