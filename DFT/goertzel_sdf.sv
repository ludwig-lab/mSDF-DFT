module goertzel_sdf (
    i_sys_clk,             // Clock signal
    i_sys_rst,           // Reset signal
    i_x,   
    o_y,
    i_k,
    i_N,
    i_wr,
    o_done
);
    parameter WIDTH = 12;
    parameter N_MAX = 512;           
    parameter FRAC_BITS = 4;
    parameter BIN_NUM = 4;
    parameter LOG_N_MAX = $clog2(N_MAX);
    

    //IOs
    input i_sys_clk, i_sys_rst, i_wr; 
    input signed [WIDTH-1:0] i_x;
    input [$clog2(N_MAX):0] i_k;
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output reg o_done;
    input [$clog2(LOG_N_MAX)-1:0] i_N;

    // Internal variables
    reg signed [WIDTH-1:0] y [BIN_NUM-1:0][1:0]; 
    reg signed [WIDTH-1:0] Q0 [BIN_NUM-1:0];
    reg signed [WIDTH-1:0] Q2 [BIN_NUM-1:0];
    reg signed [WIDTH-1:0] Q1 [BIN_NUM-1:0];
    reg [LOG_N_MAX-1:0] k_table [BIN_NUM-1:0];
    reg [$clog2(N_MAX)-1:0] count;           
    (* rom_style = "block" *) reg signed [WIDTH-1:0] tabl [(N_MAX*2)-1:0];	
    reg [3:0] state;
    reg [$clog2(BIN_NUM)-1:0] bin_counter;
    reg set_k;
    
	initial begin
	    $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/DFT_coefficient_hex_full.txt", tabl);
        //$readmemh("../DFT_coefficient_hex_full.txt", tabl);
		//$readmemh("DFT_coefficient_hex_full.txt", tabl);
    end
    
    localparam FILTER = 0;
    localparam MULTIPLY1 = 1;
    localparam READY = 2;
    localparam MULTIPLY2 = 3;
    localparam GET_W = 4;
    localparam CHECK = 5;
    localparam MULTIPLY0 = 6;
    localparam GET_INDEX = 7;
    localparam GET_INDEX2 = 8;

    reg signed [WIDTH-1:0] a,b;
    wire signed [WIDTH-1:0]x;
    reg [$clog2(N_MAX):0] index;
    wire [LOG_N_MAX-1:0] k;
    assign k = k_table[bin_counter];
    wire [$clog2(LOG_N_MAX)-1:0] shift;
    assign shift = LOG_N_MAX-i_N;
    
    //this handles all the muliplications
    multiplier#(
        .WIDTH(WIDTH)
    )multiplier(
        .i_a(a),
        .i_b(b),
        .o_x(x)
    );
    
    reg sent;
    always @(negedge i_sys_clk) begin
        if (i_sys_rst) begin
            Q1 = '{default: '0};
            Q2 = '{default: '0};
            Q0 = '{default: '0};
            count = 0;
            state = READY;
            y = '{default: '0};
            o_y = '{default: '0};
            o_done = 0;
            bin_counter = 0;
            sent = 0;
        end 
        // We send all the result one cycle at a time when done
        if(o_done & !sent)begin 
            o_y = y[bin_counter];
            if(bin_counter == (BIN_NUM-1)) begin 
                sent = 1;
            end
            else bin_counter = bin_counter + 1;
        end

        if(i_k == N_MAX) set_k = 1;
        if(set_k == 1)begin
            k_table[bin_counter] = i_k[LOG_N_MAX-1:0];
            if(bin_counter == BIN_NUM-1) begin
                set_k = 0;
                bin_counter = 0;
            end
            else bin_counter = bin_counter + 1;
        end

        case(state)
        READY: begin
            if(i_wr) begin
                o_done = 1'b0;
                state = GET_INDEX;
                sent = 0;
            end
        end

        GET_INDEX: begin
            index = ((k<<shift)) *2;
            state = GET_W;
        end

        GET_W: begin
            a = Q1[bin_counter];
            b = tabl[index];
            state = FILTER;
        end

        FILTER: begin
            Q0[bin_counter] = i_x + 2*((x) >>> (FRAC_BITS)) - Q2[bin_counter];
            Q2[bin_counter] = Q1[bin_counter];
            Q1[bin_counter] = Q0[bin_counter]; 
            state = CHECK;
        end

        CHECK: begin
            if (bin_counter == BIN_NUM-1) begin
                
                bin_counter = 0;
                if(count == (1<<i_N)-1) state = GET_INDEX2;
                else begin 
                    state = READY;
                    count = count + 1;
                end
            end
            else begin 
                state = GET_INDEX;
                bin_counter = bin_counter + 1;
            end
        end

        GET_INDEX2: begin
            index = ((k<<shift)) *2;
            state = MULTIPLY0;
        end

        MULTIPLY0: begin
            state = MULTIPLY1;
            a = Q2[bin_counter];
            b = tabl[index];
        end

        MULTIPLY1: begin
            y[bin_counter][0] = Q1[bin_counter] - (x>>>FRAC_BITS);
            b = tabl[index+1];
            state = MULTIPLY2;
        end

        MULTIPLY2: begin
            y[bin_counter][1] = x >>>FRAC_BITS;
            if (bin_counter == BIN_NUM-1)begin
                state = READY;
                o_done = 1;
                bin_counter = 0;
            end
            else begin
                bin_counter = bin_counter + 1;
                state = GET_INDEX2;
            end
        end
        endcase
    end
endmodule

