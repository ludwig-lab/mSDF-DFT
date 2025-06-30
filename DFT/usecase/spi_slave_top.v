//   ==================================================================
//   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
//   ------------------------------------------------------------------
//   Copyright (c) 2013 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED 
//   ------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement. 
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
//   --------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02 
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
//   --------------------------------------------------------------------
//


//--------------------------------------------------------------------------------------------------

/*
F_PLLIN:   100.000 MHz (given)
F_PLLOUT:  100.000 MHz (requested)
F_PLLOUT:  100.000 MHz (achieved)

FEEDBACK: SIMPLE
F_PFD:  100.000 MHz
F_VCO:  800.000 MHz

DIVR:  0 (4'b0000)
DIVF:  7 (7'b0000111)
DIVQ:  3 (3'b011)

FILTER_RANGE: 5 (3'b101)
*/
module SPI_Slave_top (
                          i_sys_clk,  
                          i_sys_rst,  
                          i_csn,      
                          i_data,     
                          i_wr,       
                          i_rd,       
                          o_data,     
                          o_tx_ready, 
                          o_rx_ready, 
                          o_tx_error, 
                          o_rx_error, 
                          i_cpol,      
                          i_cpha,      
                          i_lsb_first, 
                          o_miso,      
                          i_mosi,      
                          i_ssn,       
                          i_sclk,
                          o_tx_ack,
                          o_tx_no_ack
                          );

    input i_sys_clk ; 
    input i_sys_rst ;
    input i_csn ;                 // slave enable/select
    input [15:0] i_data ;         // input
    input        i_wr ;           // active low write enable (pull high when writing)
    input        i_rd ;           // active high read enable (pull high when reading)
    output [15:0] o_data ;        // output
    output        o_tx_ready ;    // transmitter ready
    output        o_rx_ready ;    // receiver ready
    output        o_tx_error ;    
    output        o_rx_error ;
    input         i_cpol ;        
    input         i_cpha ;
    input         i_lsb_first ;   // lsb first when 1, msb first when 0
    output        o_miso ;
    input         i_mosi ;
    input         i_ssn ;         // select, active low
    input         i_sclk ;        // sck
    output        o_tx_ack;       // Transmission acknowledged from slave
    output        o_tx_no_ack;    // Transmission not acknowledged from slave
    
    wire          miso_tri_en;
    parameter wgnd = 1'b0;
    parameter wvcc = 1'b1;
    wire          miso_i;

    parameter DATA_SIZE = 16;


    spi_slave 
        #(
          .DATA_SIZE(DATA_SIZE)
          )
    spi_slave_u1 (
                  .i_sys_clk(i_sys_clk),  
                  .i_sys_rst(i_sys_rst),  
                  .i_csn(i_csn),      
                  .i_data(i_data),     
                  .i_wr(i_wr),       
                  .i_rd(i_rd),       
                  .o_data(o_data),     
                  .o_tx_ready(o_tx_ready), 
                  .o_rx_ready(o_rx_ready), 
                  .o_tx_error(o_tx_error), 
                  .o_rx_error(o_rx_error), 
                  .i_cpol(i_cpol),      
                  .i_cpha(i_cpha),    
                  .i_lsb_first(i_lsb_first), 
                  .o_miso(o_miso),      
                  .i_mosi(i_mosi),      
                  .i_ssn(i_ssn),       
                  .i_sclk(i_sclk),
                  .miso_tri_en(miso_tri_en),
                  .o_tx_ack(o_tx_ack),
                  .o_tx_no_ack(o_tx_no_ack)
                  );

  
endmodule 