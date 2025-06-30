 (* use_dsp = "yes" *)module multiplier_complex #(
    parameter WIDTH = 12,
    parameter FRAC_BITS = 4
    )
(
    i_a,
    i_b,
    i_c,
    o_x,
    i_scale
);

    input wire signed [WIDTH-1:0] i_a,i_b,i_c;
    output reg signed [WIDTH-1:0] o_x [0:1];
    input [2:0] i_scale;

    assign o_x[0] = (i_a * i_c) >>> (i_scale);
    assign o_x[1] = (i_b * i_c) >>> (i_scale);
endmodule