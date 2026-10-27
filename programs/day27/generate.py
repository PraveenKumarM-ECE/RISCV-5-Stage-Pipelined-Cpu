import sys
from pathlib import Path

sys.path.insert(0, "programs/day26")

from generate import (
    addi, add, sub, lw, sw, branch, jal,
    NOP
)

OUT = Path("programs/day27")
OUT.mkdir(parents=True, exist_ok=True)

def save(name, program):
    assert len(program) <= 256
    program = program + [NOP] * (256 - len(program))
    (OUT / (name + ".hex")).write_text(
        "".join(f"{x:08x}\n" for x in program)
    )
    print("Generated:", name)

# CASE 1: Three consecutive load-use dependencies.
save("case1_load_chain", [
    addi(1, 0, 5),
    sw(1, 0, 0),
    lw(2, 0, 0),
    add(3, 2, 2),      # 10; stall
    sw(3, 0, 4),
    lw(4, 0, 4),
    add(5, 4, 3),      # 20; stall
    sw(5, 0, 8),
    lw(6, 0, 8),
    add(7, 6, 5),      # 40; stall
])

# CASE 2: Newest writer must take priority.
save("case2_same_rd", [
    addi(1, 0, 1),
    addi(1, 1, 2),     # 3
    addi(1, 1, 4),     # 7
    addi(1, 1, 8),     # 15
    add(2, 1, 1),      # 30
    addi(1, 0, 20),
    add(3, 1, 2),      # 50
    add(4, 3, 1),      # 70
])

# CASE 3: Loaded data controls a branch.
save("case3_load_branch", [
    addi(1, 0, 9),
    sw(1, 0, 0),
    lw(2, 0, 0),
    branch(2, 1, 8, 0),  # BEQ taken, load-use stall
    addi(3, 0, 99),     # Wrong path
    addi(4, 0, 4),
    lw(5, 0, 0),
    branch(5, 0, 8, 0),  # BEQ not taken, stall
    addi(6, 0, 6),
    addi(7, 0, 7),
])

# CASE 4: Store data and address dependencies.
save("case4_store_hazards", [
    addi(1, 0, 16),
    addi(2, 0, 42),
    sw(2, 1, 0),
    lw(3, 1, 0),
    sw(3, 1, 4),      # Load-to-store-data stall
    lw(4, 1, 4),
    addi(5, 4, 8),    # Load-use stall: 50
    sw(5, 1, 8),
    lw(6, 1, 8),
    addi(7, 6, 1),    # 51
    addi(8, 0, 20),
    lw(9, 1, 0),      # 42
    sw(9, 8, 0),      # Store through new address
])

# CASE 5: Taken branch must squash wrong-path stores.
save("case5_branch_store", [
    addi(1, 0, 77),
    addi(2, 0, 1),
    branch(2, 2, 12, 0), # Taken to PC 20
    sw(1, 0, 0),         # Must not execute
    sw(1, 0, 4),         # Must not execute
    addi(3, 0, 33),      # PC 20
    sw(3, 0, 8),
    lw(4, 0, 8),
    addi(5, 4, 1),       # 34
])

# CASE 6: Backward branch loop.
# x1 counts from 0 to 5, x2 accumulates 5+4+3+2+1.
save("case6_loop", [
    addi(1, 0, 5),       # PC 0: counter
    addi(2, 0, 0),       # PC 4: sum
    add(2, 2, 1),        # PC 8: sum += counter
    addi(1, 1, -1),      # PC 12: counter--
    branch(1, 0, -8, 1), # PC 16: BNE to PC 8
    addi(3, 2, 0),       # PC 20: copy final sum
    sw(3, 0, 0),
    lw(4, 0, 0),
])

print("All six Day 27 programs generated.")
