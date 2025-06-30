create_clock -period 10.00 -name {top|i_ref_clk} -waveform [list 0.00 5.00] [get_ports i_ref_clk]
create_clock -period 10.00 -name {top|i_sclk} -waveform [list 0.00 5.00] [get_ports i_sclk]
set_false_path -from [get_clocks top|i_sclk] -to [get_clocks top|i_ref_clk]
set_false_path -from [get_clocks top|i_ref_clk] -to [get_clocks top|i_sclk]
