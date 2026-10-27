# Pipeline Hazard Handling

## 1. Data Hazards

Data hazards occur when an instruction requires a result
that an earlier instruction has not yet written back.

Example:

    add x3, x1, x2
    sub x4, x3, x5

The SUB instruction depends on the ADD result.

## 2. Data Forwarding

The forwarding unit selects the latest available operand
from later pipeline stages.

Forwarding reduces unnecessary pipeline stalls.

The design includes forwarding paths associated with
the EX/MEM and MEM/WB pipeline stages.

## 3. Load-Use Hazards

Example:

    lw  x3, 0(x1)
    add x4, x3, x5

A load result may not be available immediately to the
following instruction.

The hazard detection unit identifies this dependency
and inserts a stall when required.

## 4. Control Hazards

Branches and jumps may change the program counter.

Examples:

    beq x1, x2, target
    jal x1, target
    jalr x1, 0(x2)

The processor redirects execution and flushes invalid
pipeline instructions as required.

## 5. Verification

Hazard behavior was exercised using directed,
corner-case, and randomized regression programs.

Day 42 final regression results:

- 32 of 32 test programs passed.
- 896 of 896 reference-state comparisons matched.
- Zero reported failures.
