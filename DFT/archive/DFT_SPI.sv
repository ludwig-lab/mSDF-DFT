module DFT_SPI(
    i_sys_clk,
    i_sys_rst,
    i_mosi,
    o_miso,
    i_ss,
    i_sclk,
    o_X,
    i_N,
    o_done,
    singleBin_out,
    singleBin_done,
    x,
    rx_ready,
    a,
    b,
    mul_out,
    i_k
);
  // Parameters
  parameter SPI_WIDTH = 8;
  parameter DFT_WIDTH = 16;
  parameter BIN_NUM = 1;
  parameter N_MAX = 1024;
  parameter LOG_N_MAX = 10;
  parameter FRAC_BITS = 6;

  // IOs
  input i_sys_clk, i_sys_rst, i_mosi, i_ss, i_sclk;
  output o_miso, o_done;
  output signed [DFT_WIDTH - 1:0] o_X [BIN_NUM-1:0][1:0];
  input [15:0] i_N;
  output wire signed [DFT_WIDTH-1:0] singleBin_out [1:0];
  input [15:0] i_k [BIN_NUM-1:0];
  //output signed [DFT_WIDTH-1:0] a,b;

  // SPI components declaration
  reg signed [SPI_WIDTH - 1:0] data;
  wire signed [SPI_WIDTH - 1:0] spi_data;
  reg wr, cpol, cpha, lsb_first, csn;
  reg rd;
  reg SPI_rst;
  wire tx_ready, tx_error, rx_error, tx_no_ack, tx_ack;
  output wire rx_ready;
  reg [1:0] state;

  // DFT components declaration 
  output reg signed [DFT_WIDTH - 1:0] x;
  //reg [DFT_WIDTH - 1:0] k [BIN_NUM-1:0];
  reg DFT_wr, DFT_rst;
  wire signed [DFT_WIDTH - 1:0] X_buffer [BIN_NUM-1:0][1:0];
  wire [2:0] DFT_state;
  output wire singleBin_done;
  output reg signed [DFT_WIDTH-1:0] a,b;
  output wire signed [DFT_WIDTH-1:0] mul_out;

  genvar i; 
  generate 
    for (i = 0; i < BIN_NUM; i = i+1)  begin
      //assign o_X[i][0] = X_buffer[i][0];
      //assign o_X[i][1] = X_buffer[i][1];
      assign o_X[i][0] = X_buffer[i][0] >>> (FRAC_BITS);
      assign o_X[i][1] = X_buffer[i][1] >>> (FRAC_BITS);
    end  
  endgenerate 

  localparam READ = 0;
  localparam RESET = 1;
  localparam WAIT = 2;

  // System reset 
  always@(negedge i_sys_clk) begin
      if (i_sys_rst) begin 
        cpol <= 1'b1;
        cpha <= 1'b1;
        lsb_first <= 1'b0;
        csn <= 1'b1;
        //! set k here
        //k[0] <= i_k;
        state <= READ;
        rd <= 0;
        DFT_wr <= 0;
        //DFT_rst <= 1;
        SPI_rst <= 1;
        end
      else begin 
        case(state)
        READ: begin
          SPI_rst <= 0;
          if (rx_ready) begin 
            DFT_wr <= 1;
            x <= $signed(spi_data);
            //x <= {{(DFT_WIDTH-SPI_WIDTH){spi_data[SPI_WIDTH-1]}}, spi_data[SPI_WIDTH-1:0]};
            SPI_rst <= 1;
            state <= RESET;
          end
        end

        RESET: begin 
          DFT_wr <= 0;
          SPI_rst <= 0;
          state <= READ;
        end
        endcase
      end
  end

  DFT#(
    .WIDTH(DFT_WIDTH),
    .BIN_NUM(BIN_NUM),
    .N_MAX(N_MAX),
    .LOG_N_MAX(LOG_N_MAX),
    .FRAC_BITS(FRAC_BITS)
  ) DFT(
    .i_sys_clk(i_sys_clk),
    .i_sys_rst(i_sys_rst),
    .i_x(x),
    .i_wr(DFT_wr),
    .i_k(i_k),
    .i_N(i_N),
    .o_X(X_buffer),
    .o_done(o_done),
    .singleBin_out(singleBin_out),
    .singleBin_done(singleBin_done),
    .a(a),
    .b(b),
    .x(mul_out)
  );

  //defparam DFT.WIDTH = DFT_WIDTH;
  //defparam DFT.BIN_NUM = BIN_NUM;
  //defparam DFT.N_MAX = N_MAX;
  //defparam LOG_N_MAX = LOG_N_MAX;

  SPI_Slave_top#(
    .DATA_SIZE(SPI_WIDTH)
  )UUT(
      .i_sys_clk(i_sys_clk),  
      .i_sys_rst(SPI_rst),  
      .i_csn(csn),      
      .i_data(data),     
      .i_wr(wr),       
      .i_rd(rd),       
      .o_data(spi_data),     
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