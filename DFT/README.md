DFT flags:
i: inverse capable
q: using quarter of the phase factors by exploiting symmetry
ff: fully fixed
n: non-continuous input stream





beat 638 LUT usage offered by lattice IP
2163 LUTs if using LUT-based multiplier 

6/3 
written and tested coeftabl moduel, written first draft of DFT, not tested, script to generate coefficient for mem is in MATLAB folder: DFT_coefficientGenerate
coeftabl module uses 217 LUTs (THIS WAS USING DSP)


6/4
first draft of DFT tested. capacble of only one fourier coefficient at a time. LUT consumption is 1252 for 1024 points. Coefficient table takes up 537 LUTs

1324 LUT in total for 16384 point transform
DFT-e is now designated as the memory efficient variant. only a quarter of the constants are stored in memory. This, however, requies a lot more LUT to implememt. The next implementation will store the all the constant in memory in order to minimize LUT usage. 

1033 LUT with the new DFT (LUT-based multiplier)
667 LUT if using 12-bit precision; 237 LUT if using DSP

TODO: implement multi-bin support

6/5
implemented the multiplier module, using 133 LUTs.

new implementation is verified. Fixed number of bins, dynamic bin index and transform length. All multiplications share one LUT-based multiplier.
all the following data are based on 4096-point maximum 
840 ns to compute 4 bins, 30 ns clock period
assuming 12 bit SPI transmission, at 8 MHz, maximum 7 bins can be calculated in time
863 LUT for 4 bins.
935 LUT for 7 bins. 

1024-point DFT with 4 bins uses 751 LUTs in total. Single bin uses 338 LUTs. 

TODO: check if reducing constant precision helps
		check if using different clk edges for the two modules help
		check if clokcing the multiplier help

6/7
1024-point DFT with 4 bins(12bit) uses 661 LUTs. the same DFT with a quarter table uses 795

6/9
verified SPI-integrated DFT
TODO: build top module and verify on Nordic

6/11
DFT needs to be reset after each cycle
DFT does not yet work for negative SPI numbers
also fails in simulation, compiler complains about port size in DFT_SPI's SPI_data