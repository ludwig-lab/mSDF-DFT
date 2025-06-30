module LUT_full#(
    parameter WIDTH = 12,
    parameter LOG_N_MAX = 10,
    parameter N_MAX = 1024
)(
    input [0:WIDTH-1] i_index,
    input [0:WIDTH-1] i_N,
    output signed [0:WIDTH-1] o_c [0:1]
);

    reg signed [0:WIDTH-1] tabl [0:(N_MAX*2)-1];
    wire [0:WIDTH] table_index;
    assign table_index = (i_index << (LOG_N_MAX-i_N))%(N_MAX);
    assign o_c[0] = tabl[table_index << 1];
    assign o_c[1] = tabl[(table_index << 1)+1];

	initial begin
        $readmemh("../DFT_coefficient_hex_full.txt", tabl);
		//$readmemh("DFT_coefficient_hex_full.txt", tabl);
    end

endmodule