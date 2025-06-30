####---- CreateClock list ----2
create_clock  -period 10.00 -waveform {0.00 5.00} -name {top|i_ref_clk} [get_ports {i_ref_clk}] 
create_clock  -period 10.00 -waveform {0.00 5.00} -name {top|i_sclk} [get_ports {i_sclk}] 

####---- SetFalsePath list ----2
set_false_path  -from [get_clocks {top|i_sclk}]  -to [get_clocks {top|i_ref_clk}]
set_false_path  -from [get_clocks {top|i_ref_clk}]  -to [get_clocks {top|i_sclk}]

