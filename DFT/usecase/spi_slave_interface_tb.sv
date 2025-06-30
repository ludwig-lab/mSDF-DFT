`timescale 10ns/1ns
module SPI_slave_interface_tb();
parameter spi_s_width = 12;
parameter spi_m_width = 16;
parameter data_total = 4;

reg ss, mosi, miso, sck, clk, rst, enable;
reg[spi_m_width - 1:0] data_to_send [0:data_total-1];  
wire [spi_s_width - 1:0] o_data;
reg [spi_s_width - 1:0] i_data;
wire o_data_ready,tx_ready;

SPI_slave_interface UUT(
    .i_sys_clk(clk),
    .i_sys_rst(rst),
    .i_mosi(mosi),
    .o_miso(miso),
    .i_ss(ss),
    .i_sclk(sck),
    .o_data(o_data),
    .i_data(i_data),
    .o_data_ready(o_data_ready)
    //.i_enable(enable)
);
	
always #50 clk = ~clk;  // FPGA clock 	

always@(posedge clk) if(o_data_ready) i_data = o_data;
integer i, j;
initial begin 
    ss = 1;
    //$monitor("time: %t rd: %b",$time,UUT.rd);
    $monitor("time: %t s_data: %b",$time,UUT.s_data);
    $monitor("time: %t m_data: %b",$time,UUT.m_data);
    $monitor("time: %t tx_ready: %b",$time,UUT.tx_ready);
    $monitor("time: %t rx_ready: %b",$time,UUT.rx_ready);
    $monitor("time: %t rx_ready_d: %b",$time,UUT.rx_ready_d);
    $monitor("time: %t csn: %b",$time,UUT.csn);
    data_to_send[0] = 1;
    data_to_send[1] = 3;
    data_to_send[2] = 8;
    data_to_send[3] = 2;
    enable = 1;
	sck = 1;
	clk = 1'b0;
    rst = 1;
    #800;
    rst = 0;
    #800;

    
    for(j = 0; j < data_total; j = j + 1)begin
        ss <= 0;
        # 157;
        
        for(i = 0; i < spi_m_width; i = i + 1)begin	  
            sck <= 0;
            mosi <= data_to_send[j][spi_m_width-1-i];
            # 250;
            sck <= 1;
            #250;
        end	 
        #10;
        ss <= 1;
        #1000;	
    end
    #1400;
    ss = 1;
    #3000;
    
    $finish;

end

endmodule 
	