
module goertzel_sdf_tb;

  // Parameters
  parameter WIDTH = 12;
  parameter N_MAX = 32768;
  parameter BIN_NUM = 4;
  parameter FRAC_BITS = 4;
  parameter LOG_N_MAX = $clog2(N_MAX);

  // Signals
  reg i_sys_clk;
  reg i_sys_rst;
  reg i_wr;
  reg signed [WIDTH-1:0] i_x;
  reg [$clog2(N_MAX):0] i_k;
  wire signed [WIDTH-1:0] o_y [1:0];
  wire o_done;
  reg [3:0] state;
  wire signed [WIDTH-1:0] Q0 [BIN_NUM-1:0];
  wire signed [WIDTH-1:0] Q2 [BIN_NUM-1:0];
  wire signed [WIDTH-1:0] Q1 [BIN_NUM-1:0];
  wire [$clog2(BIN_NUM)-1:0] bin_counter;
  wire signed [WIDTH-1:0] a,b;
  wire signed [WIDTH-1:0]x;
  wire signed [WIDTH-1:0] y [BIN_NUM-1:0][1:0]; 
  reg [$clog2(LOG_N_MAX)-1:0] i_N;
  wire [$clog2(N_MAX)-1:0] count;  
  wire [$clog2(N_MAX):0] N;
  wire [LOG_N_MAX-1:0] k_table [BIN_NUM-1:0];

  goertzel #(
    .WIDTH(WIDTH),
    .N_MAX(N_MAX),
    .FRAC_BITS(FRAC_BITS),
    .BIN_NUM(BIN_NUM)
  ) UUT (
    .i_sys_clk(i_sys_clk),
    .i_sys_rst(i_sys_rst),
    .i_x(i_x),
    .i_k(i_k),
    .i_wr(i_wr),
    .o_y(o_y),
    .o_done(o_done),
    .i_N(i_N)
  );

  // Clock Generation
  initial begin
    i_sys_clk = 0;
    forever #5 i_sys_clk = ~i_sys_clk; // 100 MHz clock
  end

  // Reset Generation
  initial begin
    i_sys_rst = 1;
    #20;
    i_sys_rst = 0;
  end

  // Test Sequence
  initial begin
    // Initial values
    i_x = 0;
    //i_k[0] = 0;
    i_wr = 0;
    i_N = 2;
    
    // Wait for reset de-assertion
    @(negedge i_sys_rst);
    
    // Apply input samples
    @(negedge i_sys_clk);
		i_k = N_MAX;
		@(negedge i_sys_clk);
		i_k = 0;
		@(negedge i_sys_clk);
		i_k = 1;
		@(negedge i_sys_clk);
		i_k = 2;
		@(negedge i_sys_clk);
		i_k = 3;

    @(posedge i_sys_clk);
    i_wr = 1;
    i_x = 0; 
    @(posedge i_sys_clk);
    i_wr = 0; 
    #500;

    @(posedge i_sys_clk);
    i_wr = 1;
    i_x = 1; 
    @(posedge i_sys_clk);
    i_wr = 0; 
    #500;

    @(posedge i_sys_clk);
    i_wr = 1;
    i_x = 0; 
    @(posedge i_sys_clk);
    i_wr = 0; 
    #500;

    @(posedge i_sys_clk);
    i_wr = 1;
    i_x = 1; 
    @(posedge i_sys_clk);
    i_wr = 0; 
    #500;



    // Wait for processing to complete
    wait (o_done);
    
    // Check outputs
    $display("Output y0: %d, y1: %d", o_y[0], o_y[1]);
    
    // Finish simulation
    $finish;
  end

endmodule

/*module goertzel_tb();
parameter N_MAX = 512; 
parameter WIDTH = 12;  
parameter BIN_NUM = 1;
reg i_sys_clk, reset;
reg signed [11:0] sample;
reg [$clog2(N_MAX):0] i_N; 
reg [$clog2(N_MAX):0] i_k[BIN_NUM-1:0];
reg signed [31:0] magnitude;
wire signed [11:0] o_y [1:0];
wire done;
reg wr;
wire signed [WIDTH-1:0] Q0, Q2, Q1[BIN_NUM-1:0];
wire signed [WIDTH-1:0] W [BIN_NUM-1:0][1:0]; 

initial begin
    i_sys_clk = 0;
    reset = 1;
    i_k[0] = 0;
    i_N = 4;
    @(posedge i_sys_clk);
    #10;
    reset = 0;

    @(posedge i_sys_clk);
    wr=1;
    sample = 0;
    @(posedge i_sys_clk);
    wr = 0;
    #500;

    @(posedge i_sys_clk);
    wr = 1;
    sample = 1;
    @(posedge i_sys_clk);
    wr = 0;
    #500;


    @(posedge i_sys_clk);
    wr = 1;
    sample = 0;
    @(posedge i_sys_clk);
    wr = 0;
    #500;

    @(posedge i_sys_clk);
    wr = 1;
    sample = 1;
    @(posedge i_sys_clk);
    wr = 0;
    #500;

    if(!done)#50;
    $finish;

end

always #10 i_sys_clk = ~i_sys_clk;

goertzel#(
        .WIDTH(WIDTH),
        .N_MAX(N_MAX),
        .BIN_NUM(BIN_NUM)
    ) UUT(
    .i_sys_clk(i_sys_clk),
    .i_sys_rst(reset),
    .i_x(sample),
    .o_y(o_y),
    .i_k(i_k),
    .i_N(i_N),
    .o_done(done),
    .i_wr(wr),
    .Q0(Q0),
    .Q1(Q1),
    .Q2(Q2),
    .W(W)
);
endmodule
*/
