from pathlib import Path

OUT = Path("programs/day26")
NOP = 0x00000013

def i_type(rd, rs1, imm, f3, op=0x13):
    return ((imm & 0xfff) << 20) | (rs1 << 15) | \
           (f3 << 12) | (rd << 7) | op

def r_type(rd, rs1, rs2, f3, f7=0):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (rd << 7) | 0x33

def store(rs2, rs1, imm, f3):
    n = imm & 0xfff
    return ((n >> 5) << 25) | (rs2 << 20) | \
           (rs1 << 15) | (f3 << 12) | \
           ((n & 31) << 7) | 0x23

def branch(rs1, rs2, imm, f3):
    assert imm % 2 == 0
    n = imm & 0x1fff
    return (((n >> 12) & 1) << 31) | \
           (((n >> 5) & 63) << 25) | \
           (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (((n >> 1) & 15) << 8) | \
           (((n >> 11) & 1) << 7) | 0x63

def jal(rd, imm):
    assert imm % 2 == 0
    n = imm & 0x1fffff
    return (((n >> 20) & 1) << 31) | \
           (((n >> 1) & 1023) << 21) | \
           (((n >> 11) & 1) << 20) | \
           (((n >> 12) & 255) << 12) | \
           (rd << 7) | 0x6f

def addi(rd, rs1, imm):
    return i_type(rd, rs1, imm, 0)

def slti(rd, rs1, imm):
    return i_type(rd, rs1, imm, 2)

def sltiu(rd, rs1, imm):
    return i_type(rd, rs1, imm, 3)

def add(rd, a, b):
    return r_type(rd, a, b, 0)

def sub(rd, a, b):
    return r_type(rd, a, b, 0, 0x20)

def xor(rd, a, b):
    return r_type(rd, a, b, 4)

def slt(rd, a, b):
    return r_type(rd, a, b, 2)

def sltu(rd, a, b):
    return r_type(rd, a, b, 3)

def sll(rd, a, b):
    return r_type(rd, a, b, 1)

def srl(rd, a, b):
    return r_type(rd, a, b, 5)

def sra(rd, a, b):
    return r_type(rd, a, b, 5, 0x20)

def lw(rd, rs1, imm):
    return i_type(rd, rs1, imm, 2, 0x03)

def lbu(rd, rs1, imm):
    return i_type(rd, rs1, imm, 4, 0x03)

def lh(rd, rs1, imm):
    return i_type(rd, rs1, imm, 1, 0x03)

def lhu(rd, rs1, imm):
    return i_type(rd, rs1, imm, 5, 0x03)

def sw(rs2, rs1, imm):
    return store(rs2, rs1, imm, 2)

def sb(rs2, rs1, imm):
    return store(rs2, rs1, imm, 0)

def jalr(rd, rs1, imm):
    return i_type(rd, rs1, imm, 0, 0x67)

def save(name, instructions):
    assert len(instructions) <= 256
    instructions = instructions + [NOP] * (256 - len(instructions))
    path = OUT / f"{name}.hex"
    path.write_text(
        "".join(f"{x:08x}\n" for x in instructions)
    )
    print(f"Generated {path}")

# CASE 1: Multiple writes to the same register
save("case1_priority", [
    addi(1, 0, 1),
    addi(1, 1, 1),
    addi(1, 1, 1),
    add(2, 1, 1),
    add(3, 2, 1),
    addi(4, 3, 1),
    add(5, 4, 2),
    add(6, 5, 1),
])

# CASE 2: Consecutive ALU dependencies
save("case2_alu", [
    addi(1, 0, -8),
    addi(2, 0, 3),
    add(3, 1, 2),
    sub(4, 3, 2),
    add(5, 4, 1),
    xor(6, 5, 2),
    add(7, 6, 2),
])

# CASE 3: Load-use hazards and store forwarding
save("case3_load", [
    addi(1, 0, 55),
    sw(1, 0, 0),
    lw(2, 0, 0),
    add(3, 2, 2),
    lw(4, 0, 0),
    sw(4, 0, 4),
    lw(5, 0, 4),
    add(6, 5, 3),
])

# CASE 4: Byte/halfword memory operations
save("case4_memory", [
    addi(1, 0, 16),
    addi(2, 0, 127),
    sw(2, 1, 0),
    lw(3, 1, 0),
    addi(4, 3, 1),
    sb(4, 1, 1),
    lbu(5, 1, 1),
    lh(6, 1, 0),
    lhu(7, 1, 0),
])

# CASE 5: Signed/unsigned ALU operations
save("case5_signed", [
    addi(1, 0, -1),
    addi(2, 0, 1),
    slt(3, 1, 2),
    sltu(4, 1, 2),
    sll(5, 2, 2),
    srl(6, 1, 2),
    sra(7, 1, 2),
    slti(8, 1, 0),
    sltiu(9, 1, 1),
])

# CASE 6: Taken/untaken branches, JAL and JALR
p = [
    addi(1, 0, 5),       # PC 0
    addi(2, 0, 5),       # PC 4
    branch(1, 2, 8, 0),  # PC 8: BEQ taken
    addi(3, 0, 99),      # PC 12: skipped
    branch(1, 2, 8, 1),  # PC 16: BNE not taken
    addi(4, 0, 4),       # PC 20
    jal(5, 8),           # PC 24: link = 28
    addi(6, 0, 99),      # PC 28: skipped
    addi(7, 0, 7),       # PC 32
    addi(8, 0, 64),      # PC 36
    jalr(9, 8, 0),       # PC 40: link = 44
    addi(10, 0, 99),     # PC 44: skipped
]

while len(p) < 16:
    p.append(NOP)

p.append(addi(11, 0, 11))  # PC 64
save("case6_control", p)

print("All 6 Day 26 programs generated.")
