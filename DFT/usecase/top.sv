module top(
    i_sys_clk,
    i_sys_rst,
    i_mosi,
    o_miso,
    i_ss,
    i_sclk,
    i_enable
);
    parameter WIDTH = 16;
    parameter BIN_NUM = 29;
    parameter N_MAX = 512;
    parameter LOG_N_MAX = $clog2(N_MAX);
    parameter FRAC_BITS = 4;
    parameter spi_s_width = 16;
    parameter spi_m_width = 16;
    parameter BAND_NUM = 2;
    parameter BETA_STOP = 6;

    input i_sys_clk,i_sys_rst,i_mosi,i_ss,i_sclk,i_enable;
    output o_miso;
    wire clk;
    clock clock(
        .i_sys_clk(i_sys_clk),
        .i_sys_rst(i_sys_rst),
        .o_clk(clk)
    );
    /*
    reg clk, clk_counter;
    always@(posedge i_sys_clk) begin
        if(i_sys_rst) begin
            clk = 0;
            clk_counter = 0;
        end else begin
            clk_counter = !clk_counter;
            if(clk_counter == 0) clk = !clk;
        end
    end
    */

    wire [spi_s_width - 1:0] x;
    wire signed [WIDTH-1:0] o_X [1:0];
    wire DFT_done, data_ready, enable,done;
    reg wr,sent, tx_ready;
    wire signed [WIDTH-1:0] y [0:BAND_NUM-1];
    reg signed [WIDTH-1:0] y_buffer [0:BAND_NUM-1];
    reg signed [spi_s_width-1:0] tx_buffer;
    reg [2:0] state;
    reg counter;
    reg reset;
    localparam BETA = 1;
    localparam GAMMA = 2;
    localparam RESET = 3;
    localparam WAIT = 4;
    localparam START = 0;
    

    assign enable = i_enable;

    SPI_slave_interface#(
        .spi_s_width(spi_s_width),
        .spi_m_width(spi_m_width)
    )SPI(
        .i_sys_clk(clk),
        .i_sys_rst(i_sys_rst),
        .i_mosi(i_mosi),
        .o_miso(o_miso),
        .i_ss(i_ss),
        .i_sclk(i_sclk),
        .o_data(x),
        .o_data_ready(data_ready),
        .i_data(tx_buffer),
        //.i_enable(enable),
        .o_tx_ready(tx_ready)
    );

    bandpower#(
        .WIDTH(WIDTH),
        .BIN_NUM(BIN_NUM),
        .N_MAX(N_MAX),
        .LOG_N_MAX(LOG_N_MAX),
        .FRAC_BITS(FRAC_BITS),
        .BAND_NUM(BAND_NUM),
        .BETA_STOP(BETA_STOP)
    )bandpower(
        .i_sys_clk(clk),
        .i_sys_rst(i_sys_rst),
        .i_x(x),
        .i_wr(wr),
        .o_y(y),
        .o_done(done)
    );

    always @(posedge clk) begin
        if (i_sys_rst) begin
            wr <= 0;
            sent <= 0;
            reset <= 0;
        end
        if(data_ready & !sent & enable) begin
            wr <= 1;
            sent <= 1;
        end else wr <= 0;
        if (!data_ready) begin 
            sent <= 0;
        end
    end

    always @(posedge clk) begin
        if (i_sys_rst) begin
            tx_buffer <= 0;
            state <= START;
        end
        if(done & !reset) begin 
            counter <= 0;
            reset <= 1;
        end
        if (!done) reset <= 0;
        
        case(state)
        START: begin
            if(done) begin
                y_buffer[0] <= y[0];
                y_buffer[1] <= y[1];
                //tx_buffer <= y[0];
                state <= BETA;
            end
        end

        BETA: if (tx_ready) begin 
            tx_buffer <= y_buffer[0];
            state <= WAIT;
        end
        WAIT: if (!tx_ready) state <= GAMMA; 

        GAMMA: if (tx_ready) begin
            state <= RESET;
            tx_buffer <= y_buffer[1];
        end

        RESET:if (!tx_ready) begin 
            state <= START;
            tx_buffer <= 0;
        end 
        endcase
        
    end

endmodule



/*
module top(
    i_sys_clk,
    i_sys_rst,
    i_mosi,
    o_miso,
    i_ss,
    i_sclk,
    i_enable,
    rx_ready,
    o_ss,
    x,
    o_mosi,
    o_sclk
);
    parameter spi_s_width = 12;
    parameter spi_m_width = 16;
    input i_sys_clk,i_sys_rst,i_mosi, i_ss, i_sclk,i_enable;
    output o_miso,rx_ready,o_ss,o_mosi,o_sclk;
    output [spi_s_width - 1:0] x;
    
    assign o_ss = i_ss;
    assign o_sclk = i_sclk;

    SPI_slave_interface#(
        .spi_s_width(spi_s_width),
        .spi_m_width(spi_m_width)
    )SPI(
        .i_sys_clk(i_sys_clk),
        .i_sys_rst(i_sys_rst),
        .i_mosi(i_mosi),
        .o_miso(o_miso),
        .i_ss(i_ss),
        .i_sclk(i_sclk),
        .o_data(x),
        //.o_data_ready(data_ready),
        //.i_data(tx_buffer),
        .i_enable(i_enable),
        .rx_ready(rx_ready),
        .o_mosi(o_mosi)
        //.o_tx_ready(tx_ready)
    );

endmodule
*/