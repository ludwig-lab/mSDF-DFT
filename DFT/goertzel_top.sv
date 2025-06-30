module goertzel_top(
    i_sys_clk,             
    i_sys_rst,           
    o_y,
    i_x,
    o_done,
    i_enable,
    i_k,
    i_N,
    o_ready
);
    parameter WIDTH = 12;
    parameter N_MAX = 32768;
    parameter BIN_NUM = 32;
    parameter LOG_N_MAX = $clog2(N_MAX);

    input i_sys_clk, i_sys_rst, i_enable; 
    input signed [WIDTH-1:0] i_x;
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output reg o_done;
    input [LOG_N_MAX:0] i_k;
    input [$clog2(LOG_N_MAX)-1:0] i_N;
    output o_ready;


    goertzel#(
        .WIDTH(WIDTH),
        .N_MAX(N_MAX),
        .BIN_NUM(BIN_NUM),
        .FRAC_BITS(4)
    ) UUT(
        .i_sys_clk(i_sys_clk),             
        .i_sys_rst(i_sys_rst),           
        .i_x(i_x),   
        .o_y(o_y),
        .o_done(o_done),
        .i_enable(i_enable),
        .i_k(i_k),
        .i_N(i_N),
        .o_ready(o_ready)
    );
endmodule