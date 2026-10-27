import subprocess
import sys
from pathlib import Path

MASK = 0xffffffff
OUT = Path("programs/day29")
SIM = "sim/pipeline/day29_sim"
NOP = 0x00000013

OUT.mkdir(parents=True, exist_ok=True)

def u32(x):
    return x & MASK

def signed(x, bits=32):
    x &= (1 << bits) - 1
    return x - (1 << bits) if x & (1 << (bits-1)) else x

def itype(rd, rs1, imm, f3, opcode):
    return ((imm & 4095) << 20) | (rs1 << 15) | \
           (f3 << 12) | (rd << 7) | opcode

def rtype(rd, rs1, rs2, f3=0, f7=0):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (rd << 7) | 0x33

def stype(rs2, rs1, imm, f3):
    n = imm & 4095
    return ((n >> 5) << 25) | (rs2 << 20) | \
           (rs1 << 15) | (f3 << 12) | \
           ((n & 31) << 7) | 0x23

def btype(rs1, rs2, offset, f3):
    assert offset % 2 == 0
    n = offset & 8191
    return (((n >> 12) & 1) << 31) | \
           (((n >> 5) & 63) << 25) | \
           (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (((n >> 1) & 15) << 8) | \
           (((n >> 11) & 1) << 7) | 0x63

def jtype(rd, offset):
    assert offset % 2 == 0
    n = offset & 0x1fffff
    return (((n >> 20) & 1) << 31) | \
           (((n >> 1) & 1023) << 21) | \
           (((n >> 11) & 1) << 20) | \
           (((n >> 12) & 255) << 12) | \
           (rd << 7) | 0x6f

def addi(d, a, n): return itype(d, a, n, 0, 0x13)
def add(d, a, b): return rtype(d, a, b)
def sub(d, a, b): return rtype(d, a, b, 0, 0x20)
def lw(d, a, n): return itype(d, a, n, 2, 0x03)
def lb(d, a, n): return itype(d, a, n, 0, 0x03)
def lbu(d, a, n): return itype(d, a, n, 4, 0x03)
def lh(d, a, n): return itype(d, a, n, 1, 0x03)
def lhu(d, a, n): return itype(d, a, n, 5, 0x03)
def sw(b, a, n): return stype(b, a, n, 2)
def sb(b, a, n): return stype(b, a, n, 0)
def sh(b, a, n): return stype(b, a, n, 1)
def beq(a, b, n): return btype(a, b, n, 0)
def bne(a, b, n): return btype(a, b, n, 1)
def blt(a, b, n): return btype(a, b, n, 4)
def bge(a, b, n): return btype(a, b, n, 5)
def bltu(a, b, n): return btype(a, b, n, 6)
def bgeu(a, b, n): return btype(a, b, n, 7)
def jal(d, n): return jtype(d, n)
def jalr(d, a, n): return itype(d, a, n, 0, 0x67)

def make_programs():
    cases = {}

    # 1. Word memory and consecutive load dependencies.
    cases["word_loads"] = [
        addi(1,0,11), sw(1,0,0),
        lw(2,0,0), add(3,2,2),
        sw(3,0,4), lw(4,0,4),
        add(5,4,3), sw(5,0,8),
        lw(6,0,8)
    ]

    # 2. Byte sign extension and overlapping stores.
    cases["byte_memory"] = [
        addi(1,0,32), addi(2,0,-1),
        sw(2,1,0), lb(3,1,0),
        lbu(4,1,1), addi(5,0,127),
        sb(5,1,2), lb(6,1,2),
        lbu(7,1,2), lw(8,1,0)
    ]

    # 3. Halfword sign extension and partial writes.
    cases["half_memory"] = [
        addi(1,0,48), addi(2,0,-1),
        sh(2,1,0), lh(3,1,0),
        lhu(4,1,0), addi(5,0,123),
        sh(5,1,2), lw(6,1,0),
        lh(7,1,2), lhu(8,1,2)
    ]

    # 4. Signed/unsigned branch comparisons.
    cases["branch_compare"] = [
        addi(1,0,-1), addi(2,0,1),
        blt(1,2,8), addi(3,0,99),
        bge(1,2,8), addi(4,0,4),
        bltu(1,2,8), addi(5,0,5),
        bgeu(1,2,8), addi(6,0,99),
        addi(7,0,7), beq(7,7,8),
        addi(8,0,99), addi(9,0,9)
    ]

    # 5. Load-dependent branches and backward loop.
    cases["load_branch_loop"] = [
        addi(1,0,4), sw(1,0,0),
        lw(2,0,0), beq(2,1,8),
        addi(3,0,99),
        addi(4,0,0),
        add(4,4,2), addi(2,2,-1),
        bne(2,0,-8),
        sw(4,0,4), lw(5,0,4),
        addi(6,5,1)
    ]

    # 6. JAL, JALR, forwarding and wrong-path stores.
    p = [
        addi(1,0,77), addi(2,0,1),
        beq(2,2,12),
        sw(1,0,0), sw(1,0,4),
        jal(3,8), sw(1,0,8),
        addi(4,0,80), jalr(5,4,0),
        sw(1,0,12)
    ]
    while len(p) < 20:
        p.append(NOP)
    p += [
        addi(6,0,42), sw(6,0,16),
        lw(7,0,16), add(8,7,6)
    ]
    cases["jumps_flush"] = p

    return cases

def load_value(mem, address, size, sign_extend):
    if address < 0 or address + size > len(mem):
        raise ValueError(f"Invalid load address {address}")
    if address % size:
        raise ValueError(f"Misaligned load address {address}")
    n = sum(mem[address+i] << (8*i) for i in range(size))
    return u32(signed(n, size*8) if sign_extend else n)

def store_value(mem, address, size, value):
    if address < 0 or address + size > len(mem):
        raise ValueError(f"Invalid store address {address}")
    if address % size:
        raise ValueError(f"Misaligned store address {address}")
    for i in range(size):
        mem[address+i] = (value >> (8*i)) & 255

def reference(program, steps=110):
    regs = [0] * 32
    mem = bytearray(256)
    pc = 0
    redirects = 0

    for _ in range(steps):
        if pc % 4 or pc < 0 or pc >= 1024:
            raise ValueError(f"Invalid instruction PC: {pc}")

        ins = program[pc//4]
        opcode = ins & 127
        rd = (ins >> 7) & 31
        f3 = (ins >> 12) & 7
        rs1 = (ins >> 15) & 31
        rs2 = (ins >> 20) & 31
        f7 = (ins >> 25) & 127

        a, b = regs[rs1], regs[rs2]
        next_pc = pc + 4
        result = None

        imm_i = signed(ins >> 20, 12)
        imm_s = signed(
            ((ins >> 25) << 5) | ((ins >> 7) & 31), 12
        )

        if opcode == 0x13:
            if f3 != 0:
                raise ValueError("Unexpected I-type operation")
            result = u32(a + imm_i)

        elif opcode == 0x33:
            if f3 != 0:
                raise ValueError("Unexpected R-type operation")
            if f7 == 0:
                result = u32(a + b)
            elif f7 == 0x20:
                result = u32(a - b)
            else:
                raise ValueError("Unexpected R-type funct7")

        elif opcode == 0x03:
            address = u32(a + imm_i)
            sizes = {0: (1, True), 1: (2, True),
                     2: (4, False), 4: (1, False),
                     5: (2, False)}
            size, sign_extend = sizes[f3]
            result = load_value(mem, address, size, sign_extend)

        elif opcode == 0x23:
            address = u32(a + imm_s)
            size = {0: 1, 1: 2, 2: 4}[f3]
            store_value(mem, address, size, b)

        elif opcode == 0x63:
            imm_b = (
                (((ins >> 31) & 1) << 12) |
                (((ins >> 7) & 1) << 11) |
                (((ins >> 25) & 63) << 5) |
                (((ins >> 8) & 15) << 1)
            )
            offset = signed(imm_b, 13)

            taken = {
                0: a == b,
                1: a != b,
                4: signed(a) < signed(b),
                5: signed(a) >= signed(b),
                6: a < b,
                7: a >= b
            }[f3]

            if taken:
                next_pc = pc + offset
                redirects += 1

        elif opcode == 0x6f:
            imm_j = (
                (((ins >> 31) & 1) << 20) |
                (((ins >> 12) & 255) << 12) |
                (((ins >> 20) & 1) << 11) |
                (((ins >> 21) & 1023) << 1)
            )
            result = pc + 4
            next_pc = pc + signed(imm_j, 21)
            redirects += 1

        elif opcode == 0x67:
            result = pc + 4
            next_pc = u32(a + imm_i) & ~1
            redirects += 1

        else:
            raise ValueError(
                f"Unsupported opcode {opcode:02x} at PC {pc}"
            )

        if result is not None and rd != 0:
            regs[rd] = u32(result)

        regs[0] = 0
        pc = next_pc

    words = [
        int.from_bytes(mem[i*4:i*4+4], "little")
        for i in range(64)
    ]
    return regs, words, redirects

def simulate(path):
    proc = subprocess.run(
        ["vvp", SIM, f"+PROGRAM={path}", "+CYCLES=120"],
        capture_output=True, text=True
    )

    if proc.returncode:
        print(proc.stdout)
        print(proc.stderr)
        raise RuntimeError("RTL simulation failed")

    regs, words, stats = {}, {}, None
    inside = False

    for line in proc.stdout.splitlines():
        parts = line.split()
        if not parts:
            continue
        if parts[0] == "DAY29_BEGIN":
            inside = True
        elif parts[0] == "DAY29_END":
            inside = False
        elif inside and parts[0] == "DAY29_REG":
            regs[int(parts[1])] = int(parts[2], 16)
        elif inside and parts[0] == "DAY29_MEM":
            words[int(parts[1])] = int(parts[2], 16)
        elif inside and parts[0] == "DAY29_STATS":
            stats = tuple(map(int, parts[1:]))

    if len(regs) != 32 or len(words) != 64 or stats is None:
        raise RuntimeError("Incomplete RTL output:\n" + proc.stdout)

    return regs, words, stats

def main():
    cases = make_programs()
    total_checks = 0
    passed_checks = 0
    passed_cases = 0

    print("=" * 56)
    print("DAY 29 - MEMORY AND BRANCH REFERENCE-MODEL TESTS")
    print("=" * 56)

    for name, instructions in cases.items():
        program = instructions + [NOP] * (256-len(instructions))
        path = OUT / f"{name}.hex"
        path.write_text(
            "".join(f"{ins:08x}\n" for ins in program)
        )

        expected_regs, expected_mem, expected_redirects = \
            reference(program)
        actual_regs, actual_mem, stats = simulate(path)

        failures = []

        for i in range(32):
            total_checks += 1
            if actual_regs[i] == expected_regs[i]:
                passed_checks += 1
            else:
                failures.append(
                    f"x{i}: got={actual_regs[i]:08x} "
                    f"expected={expected_regs[i]:08x}"
                )

        for i in range(64):
            total_checks += 1
            if actual_mem[i] == expected_mem[i]:
                passed_checks += 1
            else:
                failures.append(
                    f"mem[{i*4}]: got={actual_mem[i]:08x} "
                    f"expected={expected_mem[i]:08x}"
                )

        stalls, fmem, fwb, redirects = stats

        if redirects != expected_redirects:
            failures.append(
                f"Redirects: got={redirects} "
                f"expected={expected_redirects}"
            )

        if failures:
            print(f"\nFAIL: {name}")
            print(f"Program: {path}")
            for failure in failures:
                print(" ", failure)
            print(
                f"Stalls={stalls} EX/MEM={fmem} "
                f"MEM/WB={fwb} Redirects={redirects}"
            )
            sys.exit(1)

        passed_cases += 1
        print(
            f"PASS: {name:<18} 96/96 state checks "
            f"| stalls={stalls} redirects={redirects}"
        )

    print("\n" + "=" * 56)
    print("DAY 29 FINAL SUMMARY")
    print("=" * 56)
    print(f"Cases Passed    = {passed_cases}/{len(cases)}")
    print(f"State Checks    = {passed_checks}/{total_checks}")
    print("ALL DAY 29 TESTS PASSED")

if __name__ == "__main__":
    main()
