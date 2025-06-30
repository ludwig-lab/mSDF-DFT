
module SPI_slave_interface(
    i_sys_clk,
    i_sys_rst,
    i_mosi,
    o_miso,
    i_ss,
    i_sclk,
    o_data,
    o_data_ready,
    i_data,
    //i_enable,
    o_tx_ready
);
// read on posedge, push on negedge
// sck idle high
// Parameters
parameter spi_s_width = 12;
parameter spi_m_width = 16;

// IOs
input i_sys_clk, i_sys_rst, i_mosi, i_ss, i_sclk;
input [spi_s_width-1:0] i_data;
output o_miso, o_tx_ready;
output reg [spi_s_width - 1:0] o_data;
output reg o_data_ready;

// SPI components declaration
reg [spi_m_width - 1:0] s_data;         //data for MISO, data slave is to transmit
wire [spi_m_width - 1:0] m_data;        // data from MOSI, data master transmitted 
reg wr, rd, cpol, cpha, lsb_first, SPI_rst;
reg sent;
// tx_ready only high if enabled and ss high
wire rx_ready, 
    tx_ready,
    tx_error, 
    rx_error, 
    tx_ack, 
    tx_no_ack
    ;
reg csn;
//assign csn = !i_enable;
assign o_tx_ready = tx_ready;


reg state;
localparam READ = 0;
localparam RESET = 1;

// System reset 
always@(posedge i_sys_clk) begin
    if (i_sys_rst) begin 
        cpol <= 1'b1;
        cpha <= 1'b1;
        lsb_first <= 1'b0;
		state <= READ;
		rd <= 0;
        wr <= 0;
        SPI_rst <= 1;
        o_data <= 0;
        o_data_ready <= 0;
        sent <= 0;
        csn <= 1;
    end
	else begin 
        SPI_rst <= 0;
        if (rx_ready) begin 
            //o_data <= m_data[spi_s_width-1:0]; // discarding most significant bits
            o_data <= m_data;
            rd <= 1;
            state <= RESET;
            o_data_ready <= 1;
            sent <= 1;
            csn <= 0;
        end else begin 
            o_data_ready <= 0;
            rd <= 0;
            csn <= 1;
        end
        if(tx_ready) begin
            wr <= 1;
            //s_data <= { {6{i_data[11]}}, i_data};
            s_data <= i_data;
        end else begin 
            wr <= 0;
        end
	end
end


SPI_Slave_top#(
    .DATA_SIZE(spi_m_width)
)SPI(
    .i_sys_clk(i_sys_clk),  
    .i_sys_rst(SPI_rst),  
    .i_csn(csn),      
    .i_data(s_data),     
    .i_wr(wr),       
    .i_rd(rd),       
    .o_data(m_data),     
    .o_tx_ready(tx_ready), 
    .o_rx_ready(rx_ready), 
    .o_tx_error(tx_error), 
    .o_rx_error(rx_error), 
    .i_cpol(cpol),      
    .i_cpha(cpha),    
    .i_lsb_first(lsb_first), 
    .o_miso(o_miso),      
    .i_mosi(i_mosi),      
    .i_ssn(i_ss),       
    .i_sclk(i_sclk),
    .o_tx_ack(tx_ack),
    .o_tx_no_ack(tx_no_ack)
);
endmodule

/*
module SPI_slave_interface(
    i_sys_clk,
    i_sys_rst,
    i_mosi,
    o_miso,
    i_ss,
    i_sclk,
    o_data,
    o_data_ready,
    i_enable,
    o_tx_ready,
    rx_ready,
    o_mosi
);
// read on posedge, push on negedge
// sck idle high
// Parameters
parameter spi_s_width = 12;
parameter spi_m_width = 16;

// IOs
input i_sys_clk, i_sys_rst, i_mosi, i_ss, i_sclk, i_enable;
output o_miso, o_tx_ready,rx_ready, o_mosi;
output reg [spi_s_width - 1:0] o_data;
output reg o_data_ready;

// SPI components declaration
reg [spi_m_width - 1:0] s_data;         //data for MISO, data slave is to transmit
wire [spi_m_width - 1:0] m_data;        // data from MOSI, data master transmitted 
reg wr, rd, cpol, cpha, lsb_first, SPI_rst;
wire [spi_s_width-1:0] i_data;
// tx_ready only high if enabled and ss high
wire  tx_ready,
    tx_error, 
    rx_error, 
    tx_ack, 
    tx_no_ack
    ;
wire csn;
assign csn = !i_enable;
assign o_tx_ready = tx_ready;
assign i_data = o_data;
assign o_mosi = i_mosi;


reg state;
localparam READ = 0;
localparam RESET = 1;

// System reset 
always@(posedge i_sys_clk) begin
    if (i_sys_rst) begin 
        cpol <= 1'b1;
        cpha <= 1'b1;
        lsb_first <= 1'b0;
		state <= READ;
		rd <= 0;
        wr <= 0;
        SPI_rst <= 1;
        o_data <= 0;
        o_data_ready <= 0;
    end
	else begin 
        SPI_rst <= 0;
        if (rx_ready) begin 
            o_data <= m_data[spi_s_width-1:0]; // discarding most significant bits
            rd <= 1;
            state <= RESET;
            o_data_ready <= 1;
        end else begin 
            o_data_ready <= 0;
            rd <= 0;
        end
        if(tx_ready) begin
            wr <= 1;
            s_data <= { {6{i_data[11]}}, i_data};
        end else begin 
            wr <= 0;
        end
	end
end


SPI_Slave_top#(
    .DATA_SIZE(spi_m_width)
)SPI(
    .i_sys_clk(i_sys_clk),  
    .i_sys_rst(SPI_rst),  
    .i_csn(csn),      
    .i_data(s_data),     
    .i_wr(wr),       
    .i_rd(rd),       
    .o_data(m_data),     
    .o_tx_ready(tx_ready), 
    .o_rx_ready(rx_ready), 
    .o_tx_error(tx_error), 
    .o_rx_error(rx_error), 
    .i_cpol(cpol),      
    .i_cpha(cpha),    
    .i_lsb_first(lsb_first), 
    .o_miso(o_miso),      
    .i_mosi(i_mosi),      
    .i_ssn(i_ss),       
    .i_sclk(i_sclk),
    .o_tx_ack(tx_ack),
    .o_tx_no_ack(tx_no_ack)
);
endmodule
*/