module clock(
    i_sys_clk,
    i_sys_rst,
    o_clk
);

    input i_sys_clk, i_sys_rst;
    output reg o_clk;
    reg rst_p;
    always@(posedge i_sys_clk) begin
        rst_p <= i_sys_rst;
        if(i_sys_rst && !rst_p) o_clk <= 0;
        else o_clk <= !o_clk;
    end
endmodule