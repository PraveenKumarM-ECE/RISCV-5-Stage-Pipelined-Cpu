from pathlib import Path

def addi(rd, rs1, imm):
    return ((imm & 0xfff) << 20) | (rs1 << 15) | (rd << 7) | 0x13

def lui(rd, imm20):
    return (imm20 << 12) | (rd << 7) | 0x37

def auipc(rd, imm20):
    return (imm20 << 12) | (rd << 7) | 0x17

def branch(rs1, rs2, offset, funct3):
    assert offset % 2 == 0 and -4096 <= offset <= 4094
    v = offset & 0x1fff
    return (((v >> 12) & 1) << 31 |
            ((v >> 5) & 0x3f) << 25 |
            (rs2 << 20) | (rs1 << 15) |
            (funct3 << 12) |
            ((v >> 1) & 0xf) << 8 |
            ((v >> 11) & 1) << 7 | 0x63)

def add(rd, rs1, rs2):
    return (rs2 << 20) | (rs1 << 15) | (rd << 7) | 0x33

def jal_zero():
    return 0x0000006f

program = [
    addi(1, 0, -1),          # 0: x1 = -1
    addi(2, 0, 1),           # 4: x2 = 1
    lui(5, 0x12345),         # 8: x5 = 0x12345000
    auipc(6, 1),             # 12: x6 = 0x100C
    branch(1, 2, 8, 4),      # 16: BLT taken
    addi(7, 0, 99),          # 20: skipped
    branch(2, 1, 8, 5),      # 24: BGE taken
    addi(8, 0, 99),          # 28: skipped
    branch(1, 2, 8, 6),      # 32: BLTU not taken
    addi(9, 0, 9),           # 36
    branch(1, 2, 8, 7),      # 40: BGEU taken
    addi(10, 0, 99),         # 44: skipped
    branch(2, 1, 8, 4),      # 48: BLT not taken
    addi(11, 0, 11),         # 52
    branch(2, 1, 8, 7),      # 56: BGEU not taken
    addi(12, 0, 12),         # 60
    add(13, 11, 12),         # 64: x13 = 23
    jal_zero()               # 68: loop here
]

Path("programs/program.hex").write_text(
    "".join(f"{word:08x}\n" for word in program)
)

print(f"SUCCESS: Generated {len(program)} RISC-V instructions.")
