# RISC-V CPU - Initial FPGA timing target
# Target frequency: 100 MHz
# Clock period: 10 ns

create_clock -name cpu_clk -period 10.000 [get_ports clk]
