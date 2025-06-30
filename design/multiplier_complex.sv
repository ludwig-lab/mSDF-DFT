 // ============================================================================
// Module Name      : multiplier_complex
// Description      : Computes the (a+ib)*c or (a*ib)*ic
// Author           : Richard Yang
// Date             : Sep/8/2024
// Version          : 1.0
// File             : multiplier_complex.sv
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
// | i_a           | WIDTH | real component                                   |
// | i_b           | WIDTH | imaginary compone                                |
// | i_scale       | 3     | number of bits to right shift at the end         |
// ----------------------------------------------------------------------------
// Outputs:
// ----------------------------------------------------------------------------
// | Name          | Width | Description                                      |
// |---------------|-------|--------------------------------------------------|
// | o_x           |WIDTH*2| computed complex output                          |
// ----------------------------------------------------------------------------
// Parameters:
// ----------------------------------------------------------------------------
// | Name          | Default | Description                                    |
// |---------------|---------|------------------------------------------------|
// | WIDTH         | 12      | precision of operations and data               |
// | FRAC_BITS     | 4       | Deprecated                                     |
// ----------------------------------------------------------------------------
// Additional Notes:
// o_x[0] is real and o_x[1] is imaginary when i_c is real and reversed when c 
// is imaginary
// ============================================================================
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