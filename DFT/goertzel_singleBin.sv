module goertzel_singleBin #(
    parameter N_MAX = 32,             // Number of samples in the input signal
    parameter WIDTH = 16,           // Bit width for fixed-point arithmetic
    parameter FRAC_BITS = 4,
    parameter LOG_N_MAX = $clog2(N_MAX)
) (
    i_sys_clk,                // Clock signal
    i_sys_rst,              // Reset signal
    i_x,    // Input signal (sampled data)
    i_enable,
    o_y, // Output power of the detected frequency components
    i_k,
    i_N,
    o_done
);
    input wire i_sys_clk, i_sys_rst,  i_enable;         
    input wire signed [WIDTH-1:0] i_x;    
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output reg o_done;
    input [LOG_N_MAX-1:0] i_k;
    input [$clog2(LOG_N_MAX):0] i_N;


    // Internal signals
    reg signed [WIDTH-1:0] q1;
    reg signed [WIDTH-1:0] q3;
    reg signed [WIDTH-1:0] q2;
    reg signed [WIDTH-1:0] x;

    // Coefficient LUT	
    reg [$clog2(N_MAX)-1:0] n;
    
    (* rom_style = "block" *) reg signed [WIDTH-1:0] cos_table [N_MAX-1:0];	
    (* rom_style = "block" *) reg signed [WIDTH-1:0] sine_table [N_MAX-1:0];
    reg signed [WIDTH-1:0] cos;	
    reg signed [WIDTH-1:0] sine;
    reg sent;
    reg [1:0] state;
    initial begin
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/sine_full.txt", sine_table);
        $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/cos_full.txt", cos_table);
        // $readmemh("../DFT_coefficient_hex.txt", tabl);
    end
    localparam COS = 0;
    localparam SINE = 1;
    localparam READY = 2;

    always@(negedge i_sys_clk)begin
        if (i_sys_rst) begin
            sent <= 0;
            state <= COS;
        end
        cos <= cos_table[i_k<<(LOG_N_MAX-i_N)];
    end

    always @(negedge i_sys_clk) begin
        if (i_sys_rst) begin
            q1 = 0;
            q2 = 0;
            q3 = 0;
            n = 0;
            o_done = 0;
            o_y[0] = 0;
            o_y[1] = 0;
        end else if (i_enable & !o_done)begin
            x = i_x;
            q3 = x + ((2*cos * q1) >>> (FRAC_BITS)) - q2;
            q2 = q1;
            q1 = q3;    
            if (n == ((1<<i_N)-2)) sine <= sine_table[i_k<<(LOG_N_MAX-i_N)];
            if (n == ((1<<i_N)-1)) begin
                o_done = 1;
                o_y[0] = q1 - ((q2 * cos) >>> (FRAC_BITS));
                o_y[1] = (q2 * sine)>>> (FRAC_BITS);
            end
            else n = n + 1;
        end
        if(!i_enable) o_done = 0;
    end

endmodule