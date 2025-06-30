
module goertzel_tb;

  // Parameters
  parameter WIDTH = 12;
  parameter N_MAX = 512;
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
  reg i_enable;
  reg [$clog2(N_MAX)-1:0] i_N;
  wire o_ready;

  goertzel#(
    .WIDTH(WIDTH),
    .N_MAX(N_MAX),
    .FRAC_BITS(FRAC_BITS),
    .BIN_NUM(BIN_NUM)
  )UUT(
    .i_sys_clk(i_sys_clk),
    .i_sys_rst(i_sys_rst),
    .i_x(i_x),
    .i_k(i_k),
    .i_N(i_N),
    .i_enable(i_enable),
    .o_y(o_y),
    .o_done(o_done),
    .o_ready(o_ready)
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
    $monitor("Time: %0t, q3: %h q1: %h q2: %h", $time, UUT.gen_single[1].goertzel_singleBin.q3,
                                                        UUT.gen_single[1].goertzel_singleBin.q1, 
                                                        UUT.gen_single[1].goertzel_singleBin.q2);
    $monitor("Time: %0t, cos: %h", $time, UUT.gen_single[1].goertzel_singleBin.cos);
    $monitor("Time: %0t, sine: %h", $time, UUT.gen_single[1].goertzel_singleBin.sine);
    $monitor("Time: %0t, y: %h", $time, UUT.y[0]);
    $monitor("Time: %0t, bin_counter: %h", $time, UUT.bin_counter);
    //$monitor("Time: %0t, k_table: %h", $time, UUT.k_table[0]);
    // Initial values
    i_x = 0;
    //i_k[0] = 0;
    i_wr = 0;
    i_enable = 0;
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
		#100;
    wait(o_ready);
    //$display("Time: %0t, k_table: %h %h %h %h", $time, UUT.k_table[0], UUT.k_table[1], UUT.k_table[2], UUT.k_table[3]);
    //$display("Time: %0t, i_k1: %h", $time, UUT.gen_single[0].goertzel_singleBin.i_k);
    //$display("Time: %0t, i_k2: %h", $time, UUT.gen_single[1].goertzel_singleBin.i_k);
    //$display("Time: %0t, sine: %h", $time, UUT.gen_single[0].goertzel_singleBin.sine);
    @(posedge i_sys_clk);
    i_enable = 1;
    i_x = 0; 
    
    @(posedge i_sys_clk);
    i_x = 1;

    @(posedge i_sys_clk);
    i_x = 0; 

    @(posedge i_sys_clk);
    i_x = 1; 



    // Wait for processing to complete
    wait (o_done);
    #500;
    i_enable = 0;
    
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
