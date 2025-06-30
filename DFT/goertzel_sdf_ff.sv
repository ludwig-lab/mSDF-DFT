module goertzel_sdf_ff(
    i_sys_clk,             // Clock signal
    i_sys_rst,           // Reset signal
    i_x,   // Input sample (16-bit signed)
    o_y,
    i_wr,
    o_done
);
    parameter WIDTH = 12;
    parameter N_MAX = 512;           
    parameter FRAC_BITS = 4;
    parameter BIN_NUM = 4;
    

    //IOs
    input i_sys_clk, i_sys_rst, i_wr; 
    input signed [WIDTH-1:0] i_x;
    output reg signed [WIDTH-1:0] o_y [1:0]; 
    output reg o_done;

    // Internal variables
    reg signed [WIDTH-1:0] y [BIN_NUM-1:0][1:0]; 
    reg signed [WIDTH-1:0] Q0 [BIN_NUM-1:0];
    reg signed [WIDTH-1:0] Q2 [BIN_NUM-1:0];
    reg signed [WIDTH-1:0] Q1 [BIN_NUM-1:0];
    reg [$clog2(N_MAX):0] count;           
    //reg signed [WIDTH-1:0] tabl [(N_MAX*2)-1:0];	
    wire signed [WIDTH-1:0] cosine [BIN_NUM-1:0];
    wire signed [WIDTH-1:0] sine [BIN_NUM-1:0];
    reg [0:2] state;
    reg [$clog2(BIN_NUM)-1:0] bin_counter;
    //reg [$clog2(N_MAX):0] k; 
    //reg [$clog2(N_MAX):0] i_k[BIN_NUM-1:0];
    /*
	initial begin
	    $readmemh("C:/Users/richa/Documents/FPGA-closed-loop/DFT/DFT_coefficient_hex_full.txt", tabl);
    end
    */
    genvar i;
	generate
		for(i = 0; i < BIN_NUM; i = i + 1)begin 
            assign cosine[i] = $rtoi($cos(2*3.1415*i/N_MAX)*(1<<FRAC_BITS));
            assign sine[i] = $rtoi($sin(2*3.1415*i/N_MAX)*(1<<FRAC_BITS));
		end
	endgenerate
    
    localparam FILTER = 0;
    localparam MULTIPLY1 = 1;
    localparam READY = 2;
    localparam MULTIPLY2 = 3;
    localparam GET_W = 4;
    localparam CHECK = 5;
    localparam MULTIPLY0 = 6;

    reg signed [WIDTH-1:0] a,b;
    wire signed [WIDTH-1:0]x;

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
            state = GET_W;
            y = '{default: '0};
            o_y = '{default: '0};
            o_done = 0;
            bin_counter = 0;
            sent = 0;
        end 
        if(o_done & !sent)begin 
            o_y = y[bin_counter];
            if(bin_counter == (BIN_NUM-1)) begin 
                sent = 1;
            end
            else bin_counter = bin_counter + 1;
            
        end
        case(state)
        READY: begin
            if(i_wr) begin
                o_done = 1'b0;
                state = GET_W;
                sent = 0;
            end
        end

        GET_W: begin
            a = Q1[bin_counter];
            b = cosine[bin_counter];
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
                if(count == (N_MAX-1)) state = MULTIPLY0;
                else begin 
                    count = count + 1;
                    state = READY;
                end
            end
            else begin 
                state = GET_W;
                bin_counter = bin_counter + 1;
            end
        end
        
        MULTIPLY0: begin
            state = MULTIPLY1;
            a = Q2[bin_counter];
            b = cosine[bin_counter];
        end

        MULTIPLY1: begin
            y[bin_counter][0] = Q1[bin_counter] - (x>>>FRAC_BITS);
            b = sine[bin_counter];
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
                state = MULTIPLY0;
            end
        end
        endcase
    end
endmodule

