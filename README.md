# 32-bit RISC-V 5-Stage Pipelined CPU

### RV32I Processor Designed and Verified Using SystemVerilog

A 32-bit RISC-V processor implementing the RV32I base
integer instruction set with a five-stage instruction
pipeline, data forwarding, hazard detection, branch
handling, and synchronous data memory.

The processor was developed from individual RTL modules
through single-cycle integration, pipelined implementation,
functional verification, and FPGA-oriented synthesis.

## Project Highlights

- 32-bit RV32I processor
- Five-stage instruction pipeline
- Data forwarding and hazard detection
- Pipeline stalls and control-flow flushing
- Arithmetic, logical, branch, jump, load, and store support
- Synchronous data memory with byte enables
- SystemVerilog RTL implementation
- Automated simulation and regression testing
- Xilinx 7-series technology-mapped synthesis

## Processor Architecture

The CPU uses five pipeline stages:

1. IF - Instruction Fetch
2. ID - Instruction Decode
3. EX - Execute
4. MEM - Memory Access
5. WB - Write Back

```mermaid
flowchart LR
    IF["IF<br/>Instruction Fetch"]
    IFID["IF/ID"]
    ID["ID<br/>Decode"]
    IDEX["ID/EX"]
    EX["EX<br/>Execute"]
    EXMEM["EX/MEM"]
    MEM["MEM<br/>Memory"]
    MEMWB["MEM/WB"]
    WB["WB<br/>Write Back"]

    IF --> IFID --> ID --> IDEX --> EX
    EX --> EXMEM --> MEM --> MEMWB --> WB
