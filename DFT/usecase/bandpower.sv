module bandpower(
    i_sys_clk,
    i_sys_rst,
    i_x,
    i_wr,
    o_y,
    o_done
);

    parameter WIDTH = 12;
    parameter BIN_NUM = 14;
    parameter N_MAX = 32;
    parameter FRAC_BITS = 4;
    parameter BAND_NUM = 2;
    parameter BETA_STOP = 3; // counting from 1
    parameter LOG_N_MAX = $clog2(N_MAX);

    input i_sys_clk, i_sys_rst, i_wr;   // high if new i_x was written to
    input signed [WIDTH-1:0] i_x; 
    output reg signed [WIDTH-1:0] o_y [0:BAND_NUM-1];
    output reg o_done;

    wire signed [WIDTH-1:0] X [0:1];
    wire signed [WIDTH-1:0] X_trun [0:1];
    wire DFT_done;
    reg [$clog2(BIN_NUM):0] bin_counter;
    reg state;

    assign X_trun[0] = (X[0] >>> FRAC_BITS);
    assign X_trun[1] = (X[1] >>> FRAC_BITS);

    localparam SQAURE = 0;
    localparam MEAN = 1;

    DFT_LFP#(
        .WIDTH(WIDTH),
        .BIN_NUM(BIN_NUM),
        .N_MAX(N_MAX),
        .LOG_N_MAX($clog2(N_MAX)),
        .FRAC_BITS(FRAC_BITS)
    )DFT(
        .i_sys_clk(i_sys_clk),
        .i_sys_rst(i_sys_rst),
        .i_x(i_x),
        .i_wr(i_wr),
        .o_X(X),
        .o_done(DFT_done)
    );

    always@(posedge i_sys_clk)begin
        if(i_sys_rst)begin
            bin_counter <= 0;
            o_y <= '{default:0};
            o_done <= 0;
            state <= SQAURE;
        end else if(!o_done)begin
            case(state)
            SQAURE: if(DFT_done)begin
                if(bin_counter <= BETA_STOP-1) o_y[0] <= o_y[0] + ((X_trun[0]**2 + X_trun[1]**2)/BETA_STOP);
                else o_y[1] <= o_y[1] + ((X_trun[0]**2 + X_trun[1]**2)/(BIN_NUM - BETA_STOP));
                if(bin_counter == BIN_NUM-1) state <= MEAN;
                else bin_counter <= bin_counter + 1;
            end
            MEAN: begin
                o_done <= 1;
                bin_counter <= 0;
                //o_y[0] <= o_y[0] / BETA_STOP;       // compute mean
                //o_y[1] <= o_y[1] / (BIN_NUM - BETA_STOP);      // compute mean
                state <= SQAURE;
            end
            endcase
        end
        if(i_wr) begin 
            o_done <= 0;
            o_y <= '{default:0};
        end
    end
    endmodule