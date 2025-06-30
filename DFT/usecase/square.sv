module square (
    i_sys_clk,
    i_x,
    o_y,
    i_enable
);
always@(posedge i_sys_clk) begin
    if(i_enable) o_y <= i_x ** 2;
end
endmodule