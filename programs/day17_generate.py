from pathlib import Path

def addi(rd, rs1, imm):
    return ((imm & 0xfff) << 20) | (rs1 << 15) | (rd << 7) | 0x13

def load(rd, rs1, imm, f3):
    return ((imm & 0xfff) << 20) | (rs1 << 15) | \
           (f3 << 12) | (rd << 7) | 0x03

def store(rs2, rs1, imm, f3):
    v = imm & 0xfff
    return ((v >> 5) << 25) | (rs2 << 20) | \
           (rs1 << 15) | (f3 << 12) | \
           ((v & 31) << 7) | 0x23

p = [
    addi(1, 0, 100),          # Base address
    addi(2, 0, -1),           # x2 = FFFFFFFF
    store(2, 1, 0, 2),        # SW: FFFFFFFF
    addi(3, 0, 0x12),         # x3 = 12
    store(3, 1, 1, 0),        # SB: FFFF12FF
    load(4, 1, 1, 4),         # LBU = 12
    load(5, 1, 0, 0),         # LB = FFFFFFFF
    addi(6, 0, 0x345),        # x6 = 345
    store(6, 1, 2, 1),        # SH: 034512FF
    load(7, 1, 2, 1),         # LH = 345
    load(8, 1, 2, 5),         # LHU = 345
    load(9, 1, 0, 2),         # LW = 034512FF
    addi(10, 0, -128),        # x10 = FFFFFF80
    store(10, 1, 3, 0),       # SB: 804512FF
    load(11, 1, 3, 0),        # LB = FFFFFF80
    load(12, 1, 3, 4),        # LBU = 80
    load(13, 1, 2, 1),        # LH = FFFF8045
    load(14, 1, 2, 5),        # LHU = 8045
    load(15, 1, 0, 2),        # LW = 804512FF
]

Path("programs/program.hex").write_text(
    "".join(f"{x:08x}\n" for x in p)
)

print(f"SUCCESS: Generated {len(p)} instructions.")
