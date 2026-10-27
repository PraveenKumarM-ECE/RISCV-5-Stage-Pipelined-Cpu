# CPU Memory Architecture

## Data Memory

The processor uses a synchronous data memory.

Configuration:

- Depth: 256 words
- Word width: 32 bits
- Total capacity: 8192 bits
- Total capacity: 1024 bytes (1 KiB)

The memory supports byte-enable write operations.

## FPGA Memory Mapping

Yosys synthesis for the Xilinx 7-series target
reported the following memory resources:

| Resource | Count | Purpose |
|---|---:|---|
| RAMB18E1 | 1 | Data memory |
| RAM32M | 12 | Distributed register-file memory |

## Load and Store Operations

The CPU supports RV32I load and store instructions
including byte, halfword, and word accesses.

Supported load types:

- LB
- LBU
- LH
- LHU
- LW

Supported store types:

- SB
- SH
- SW

## Timing Considerations

The synchronous memory implementation was verified
using simulation regression tests.

The FPGA synthesis results establish memory inference
and resource mapping, not physical timing closure.
