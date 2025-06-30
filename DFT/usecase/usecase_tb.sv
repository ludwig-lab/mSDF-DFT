module usecase_tb();
    parameter WIDTH = 12;
    parameter BIN_NUM = 2;
    parameter N_MAX = 32;
    parameter LOG_N_MAX = $clog2(N_MAX);
    parameter FRAC_BITS = 4;
    parameter DATA_TOTAL = 1000;

    reg signed [WIDTH-1:0] data_to_send [0:DATA_TOTAL-1];
    reg rst,clk;

    reg ss, mosi, miso, sck, clk, rst;
    reg[data_length - 1:0] data_to_send [0:data_total-1];  
    wire [0:data_length - 1] o_data;

    integer i, j;
    initial begin 
        $readmemh("./SPI_in.txt", data_to_send); 
        sck = 1'b0;
        clk = 1'b0;
        rst = 1;
        #800;
        rst = 0;
        @(negedge sck); 
        #800;
        ss <= 0;
        for(j = 0; j < data_total; j = j + 1)begin
            for(i = 0; i < data_length; i = i + 1)begin	   
                @(negedge sck); 
                mosi <= data_to_send[j][i];
            end	 
            ss <= 1;
            #1000;	 
            @(negedge sck); 
            ss <= 0;
        end
        #1400;
        ss = 1;
        #3000;
        
        $finish;

    end
endmodule