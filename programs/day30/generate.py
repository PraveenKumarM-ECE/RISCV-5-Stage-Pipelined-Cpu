from pathlib import Path

OUT = Path("programs/day30")
OUT.mkdir(parents=True, exist_ok=True)

NOP = 0x00000013

def addi(rd, rs1, imm):
    return ((imm & 4095) << 20) | (rs1 << 15) | \
           (rd << 7) | 0x13

def add(rd, rs1, rs2):
    return (rs2 << 20) | (rs1 << 15) | \
           (rd << 7) | 0x33

def lw(rd, rs1, imm):
    return ((imm & 4095) << 20) | (rs1 << 15) | \
           (2 << 12) | (rd << 7) | 0x03

def sw(rs2, rs1, imm):
    n = imm & 4095
    return ((n >> 5) << 25) | (rs2 << 20) | \
           (rs1 << 15) | (2 << 12) | \
           ((n & 31) << 7) | 0x23

def beq(rs1, rs2, offset):
    assert offset % 2 == 0
    n = offset & 8191
    return (((n >> 12) & 1) << 31) | \
           (((n >> 5) & 63) << 25) | \
           (rs2 << 20) | (rs1 << 15) | \
           (((n >> 1) & 15) << 8) | \
           (((n >> 11) & 1) << 7) | 0x63

MARKER = addi(31, 0, 123)

def save(name, code):
    assert len(code) <= 256
    code = code + [NOP] * (256 - len(code))
    (OUT / f"{name}.hex").write_text(
        "".join(f"{ins:08x}\n" for ins in code)
    )
    print(f"Generated {name}.hex")

# 1. Independent arithmetic: 31 instructions + marker.
p = [addi(i, 0, i) for i in range(1, 31)]
p.append(addi(1, 0, 31))
p.append(MARKER)
save("independent", p)

# 2. Consecutive arithmetic dependencies.
p = [addi(1, 1, 1) for _ in range(31)]
p.append(MARKER)
save("dependent", p)

# 3. Fourteen load-use stalls.
p = [
    addi(1, 0, 7),
    sw(1, 0, 0),
]
for _ in range(14):
    p.append(lw(2, 0, 0))
    p.append(add(3, 3, 2))
p.append(addi(4, 0, 1))
p.append(MARKER)
save("load_use", p)

# 4. Eight taken branches.
# Each branch skips two wrong-path instructions.
p = []
for _ in range(8):
    p.extend([
        addi(1, 1, 1),
        beq(1, 1, 12),
        addi(20, 20, 1),  # Must be flushed
        addi(21, 21, 1),  # Must be flushed
    ])
p.append(MARKER)
save("branches", p)

print("All four Day 30 benchmark programs generated.")
