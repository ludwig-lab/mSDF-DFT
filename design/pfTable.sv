// ============================================================================
// Module Name      : pfTable
// Description      : Computes the twiddle factor given its index in the full
//                    table and its corresponding pair in the quarter table. 
//                    This is accomplished by checking which quadrant it lies 
//                    and multiply by -i by the corresponding number of times.
// Author           : Richard Yang
// Date             : Aug/12/2024
// Version          : 1.1
// File             : pfTable.sv
// ----------------------------------------------------------------------------
// Revision History:
// ----------------------------------------------------------------------------
// | Version | Author      | Date        | Changes                            |
// |---------|-------------|-------------|------------------------------------|
// | 1.0     | Richard Yang| Jul/26/2024 | Initial creation                   |
// | 1.1     | Richard Yang| Aug/12/2024 | Improve throughput                 |
// ----------------------------------------------------------------------------
// Inputs:
// ----------------------------------------------------------------------------
// | Name          | Width | Description                                      |
// |---------------|-------|--------------------------------------------------|
// | i_i           | WIDTH | imaginary component                              |
// | i_r           | WIDTH | real component                                   |
// | i_sys_clk     | 1     | system clock                                     |
// | i_index       |Log2(N_MAX)| index of the twiddle factor in the full table|
// ----------------------------------------------------------------------------
// Outputs:
// ----------------------------------------------------------------------------
// | Name          | Width | Description                                      |
// |---------------|-------|--------------------------------------------------|
// | o_c           |WIDTH*2| computed twiddle factor                          |
// ----------------------------------------------------------------------------
// Parameters:
// ----------------------------------------------------------------------------
// | Name          | Default | Description                                    |
// |---------------|---------|------------------------------------------------|
// | WIDTH         | 12      | precision of operations and data               |
// | N_MAX         | 32      | point size (length of transform window)        |
// ----------------------------------------------------------------------------
// Additional Notes:
// ============================================================================

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