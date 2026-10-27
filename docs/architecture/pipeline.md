# Five-Stage RISC-V Pipeline Architecture

## Overview

This project implements a 32-bit RV32I RISC-V CPU
using a five-stage instruction pipeline.

## Pipeline Stages

### 1. Instruction Fetch (IF)

- Maintains the program counter (PC).
- Fetches instructions from the instruction interface.
- Calculates the next sequential PC.
- Supports control-flow redirects.

### 2. Instruction Decode (ID)

- Decodes the instruction.
- Reads source registers.
- Generates immediate values.
- Produces control signals.

### 3. Execute (EX)

- Performs arithmetic and logical operations.
- Calculates effective addresses.
- Evaluates branch conditions.
- Calculates branch and jump targets.
- Selects forwarded operands when required.

### 4. Memory Access (MEM)

- Handles load and store operations.
- Interfaces with synchronous data memory.
- Supports byte, halfword, and word operations.

### 5. Write Back (WB)

- Selects the result to write into the register file.
- Supports ALU results, memory data, and PC+4 results.

## Pipeline Registers

The pipeline uses:

- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

These registers preserve instruction data and control
signals between pipeline stages.

## Hazard Handling

The processor implements:

- Data forwarding
- Load-use hazard detection
- Pipeline stalls
- Branch and jump redirects
- Pipeline flushing

## Architecture Diagram

```mermaid
flowchart TD
    IF["IF: Instruction Fetch"]
    IFID["IF/ID Register"]
    ID["ID: Instruction Decode"]
    IDEX["ID/EX Register"]
    EX["EX: Execute"]
    EXMEM["EX/MEM Register"]
    MEM["MEM: Memory Access"]
    MEMWB["MEM/WB Register"]
    WB["WB: Write Back"]

    IF --> IFID
    IFID --> ID
    ID --> IDEX
    IDEX --> EX
    EX --> EXMEM
    EXMEM --> MEM
    MEM --> MEMWB
    MEMWB --> WB
