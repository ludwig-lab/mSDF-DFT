 (* use_dsp = "yes" *)module multiplier #(
    parameter WIDTH = 12,
    parameter FRAC_BITS = 4
    )
(
    i_a,
    i_b,
    o_x
);

    input wire signed [WIDTH-1:0] i_a,i_b;
    output wire signed [WIDTH-1:0] o_x;

    assign o_x = (i_a * i_b);
endmodule