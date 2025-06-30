module pfTable (
    i_i,
    i_r,
    i_sys_clk,
    i_index,
    o_c
);
    // Parameters
    parameter WIDTH = 12;
    parameter N_MAX = 1024;
    parameter Q = N_MAX/4;
    parameter LOG_N_MAX = $clog2(N_MAX);
    
    // IOs
    input signed [WIDTH-1:0] i_r,i_i;
    input i_sys_clk;
    output reg signed [WIDTH-1:0] o_c [1:0];
    input wire [LOG_N_MAX-1:0] i_index;

    always @(negedge i_sys_clk) begin
        if(i_index < Q)begin
            o_c[0] <= i_r;
            o_c[1] <= i_i;
        end
        else if(i_index < Q * 2) begin
            o_c[0] <= i_i;
            o_c[1] <= -i_r;
        end
        else if(i_index < Q * 3) begin
            o_c[0] <= -i_r;
            o_c[1] <= -i_i;
        end
        else begin
            o_c[0] <= -i_i;
            o_c[1] <= i_r;
        end
    end
endmodule