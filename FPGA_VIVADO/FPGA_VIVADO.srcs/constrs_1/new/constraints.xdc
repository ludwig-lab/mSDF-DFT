create_clock -period 12.500 -name i_sys_clk [get_ports i_sys_clk]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports i_sys_clk]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports i_sys_rst]


#set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {i_mosi}];
#set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {o_miso}];
#set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports {i_ss}];
#set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {i_sclk}];
#set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS33} [get_ports {rx_ready}];     #led12
#set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports {o_ss}];
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports o_done]

