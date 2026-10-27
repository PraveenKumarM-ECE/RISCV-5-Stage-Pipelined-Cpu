# RISC-V CPU Technical Specifications

| Parameter | Specification |
|---|---|
| Architecture | RISC-V |
| ISA | RV32I |
| Datapath width | 32 bits |
| Pipeline | 5 stages |
| Stages | IF, ID, EX, MEM, WB |
| Register file | 32 architectural registers |
| Hazard handling | Forwarding, stalls, flushing |
| Branch support | Conditional branches |
| Jump support | JAL, JALR |
| Data memory | 256 x 32-bit words |
| Data memory capacity | 1 KiB |
| Data memory implementation | Synchronous RAM |
| RTL | SystemVerilog |
| Simulation | Icarus Verilog |
| Synthesis | Yosys 0.52 |
| FPGA target family | Xilinx 7-series |
| Target clock | 100 MHz (unverified) |

## FPGA Synthesis Resources

| Resource | Utilization |
|---|---:|
| LUTs | 1,827 |
| Flip-flops | 509 |
| CARRY4 | 60 |
| RAMB18E1 | 1 |
| RAM32M | 12 |

These values are from Yosys technology-mapped synthesis,
not FPGA place-and-route.

## Verification

Final Day 42 regression:

- 32 test programs passed.
- 896 reference-state comparisons matched.
- Zero failures.

## Timing Limitation

The 100 MHz clock is a design target only.

No FPGA placement, routing, or physical static timing
analysis has been performed.

Maximum verified clock frequency is not available.
