from pathlib import Path

def rtype(rd, rs1, rs2, f3, f7=0):
    return ((f7 & 127) << 25) | (rs2 << 20) | \
           (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x33

def itype(rd, rs1, imm, f3):
    return ((imm & 4095) << 20) | (rs1 << 15) | \
           (f3 << 12) | (rd << 7) | 0x13

p = [
    itype(1, 0, 12, 0),         # x1 = 12
    itype(2, 0, 5, 0),          # x2 = 5
    rtype(3, 1, 2, 0),          # ADD  = 17
    rtype(4, 1, 2, 0, 32),      # SUB  = 7
    rtype(5, 1, 2, 7),          # AND  = 4
    rtype(6, 1, 2, 6),          # OR   = 13
    rtype(7, 1, 2, 4),          # XOR  = 9
    rtype(8, 2, 1, 2),          # SLT  = 1
    rtype(9, 2, 1, 3),          # SLTU = 1
    rtype(10, 2, 2, 1),         # SLL  = 20
    rtype(11, 1, 2, 5),         # SRL  = 0
    itype(12, 0, -16, 0),       # x12 = -16
    rtype(13, 12, 2, 5, 32),    # SRA  = -1
    itype(14, 1, 3, 7),         # ANDI = 0
    itype(15, 1, 3, 6),         # ORI  = 15
    itype(16, 1, 3, 4),         # XORI = 15
    itype(17, 2, 10, 2),        # SLTI = 1
    itype(18, 2, 10, 3),        # SLTIU = 1
    itype(19, 2, 2, 1),         # SLLI = 20
    itype(20, 1, 2, 5),         # SRLI = 3
    itype(21, 12, 0x402, 5),    # SRAI = -4
]

Path("programs/program.hex").write_text(
    "".join(f"{x:08x}\n" for x in p)
)

print("Generated", len(p), "instructions")
