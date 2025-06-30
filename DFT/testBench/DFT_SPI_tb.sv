`timescale 1ns/1ns
module DFT_SPI_tb();
parameter SPI_WIDTH = 8;
parameter DFT_WIDTH = 16;
parameter data_total = 4;
parameter BIN_NUM = 1;

reg ss, mosi, miso, sck, clk, rst;
reg signed [0:SPI_WIDTH - 1] data_to_send [0:data_total-1];  
wire signed [0:DFT_WIDTH - 1] o_X [0:BIN_NUM-1][0:1];
wire [0:SPI_WIDTH - 1] spi_data;
wire [0:1] state;
wire [0:2] DFT_state;
wire done, rx_ready, tx_ack, rd, SPI_rst;
wire signed [0:DFT_WIDTH - 1] x;
reg [0:DFT_WIDTH - 1] N;

DFT_SPI UUT(
    .i_sys_clk(clk),
    .i_sys_rst(rst),
    .i_mosi(mosi),
    .o_miso(miso),
    .i_ss(ss),
    .i_sclk(sck),
    .o_X(o_X),
	.i_N(N),
	.o_done(done),
    .spi_data(spi_data),
    .SPI_rst(SPI_rst),
    .rx_ready(rx_ready)
);
	
always #50 clk = ~clk;  // FPGA clock 	
always #250 sck = ~sck;	 
    
integer i, j;
initial begin 
    data_to_send = {1, -4, 1, 1};
	sck = 1'b0;
	clk = 1'b0;
    rst = 1;
	N = 2;
    #800;
    rst = 0;
    for(j = 0; j < data_total; j = j + 1)begin
        for(i = 0; i < SPI_WIDTH; i = i + 1)begin	
			@(posedge sck)
			ss<=0;
            @(negedge sck); 
            mosi <= data_to_send[j][i];
        end	  
    end
    #1400;
    ss = 1;
    @(done)
	#1000;
    
    $finish;

end

endmodule 
	