import random
import subprocess
import sys
from pathlib import Path

MASK = 0xFFFFFFFF
OUT = Path("programs/day28")
SIM = "sim/pipeline/day28_sim"

OUT.mkdir(parents=True, exist_ok=True)

OPS = [
    "ADD", "SUB", "AND", "OR", "XOR",
    "SLT", "SLTU", "SLL", "SRL", "SRA",
    "ADDI", "ANDI", "ORI", "XORI",
    "SLTI", "SLTIU", "SLLI", "SRLI", "SRAI"
]

R_INFO = {
    "ADD":  (0, 0x00),
    "SUB":  (0, 0x20),
    "AND":  (7, 0x00),
    "OR":   (6, 0x00),
    "XOR":  (4, 0x00),
    "SLT":  (2, 0x00),
    "SLTU": (3, 0x00),
    "SLL":  (1, 0x00),
    "SRL":  (5, 0x00),
    "SRA":  (5, 0x20),
}

I_INFO = {
    "ADDI": 0,
    "SLTI": 2,
    "SLTIU": 3,
    "XORI": 4,
    "ORI": 6,
    "ANDI": 7,
    "SLLI": 1,
    "SRLI": 5,
    "SRAI": 5,
}

def u32(x):
    return x & MASK

def signed(x):
    x = u32(x)
    return x if x < 0x80000000 else x - 0x100000000

def encode(op, rd, rs1, rs2, imm):
    if op in R_INFO:
        f3, f7 = R_INFO[op]
        return (
            (f7 << 25) |
            (rs2 << 20) |
            (rs1 << 15) |
            (f3 << 12) |
            (rd << 7) |
            0x33
        )

    f3 = I_INFO[op]

    if op in ("SLLI", "SRLI", "SRAI"):
        field = imm & 31
        if op == "SRAI":
            field |= 0x400
    else:
        field = imm & 0xFFF

    return (
        (field << 20) |
        (rs1 << 15) |
        (f3 << 12) |
        (rd << 7) |
        0x13
    )

def execute(op, a, b):
    a = u32(a)
    b = u32(b)
    shift = b & 31

    if op in ("ADD", "ADDI"):
        return u32(a + b)
    if op == "SUB":
        return u32(a - b)
    if op in ("AND", "ANDI"):
        return a & b
    if op in ("OR", "ORI"):
        return a | b
    if op in ("XOR", "XORI"):
        return a ^ b
    if op in ("SLT", "SLTI"):
        return int(signed(a) < signed(b))
    if op in ("SLTU", "SLTIU"):
        return int(a < b)
    if op in ("SLL", "SLLI"):
        return u32(a << shift)
    if op in ("SRL", "SRLI"):
        return a >> shift
    if op in ("SRA", "SRAI"):
        return u32(signed(a) >> shift)

    raise ValueError("Unknown operation: " + op)

def generate(seed, count=80):
    rng = random.Random(seed)

    regs = [0] * 32
    instructions = []
    recent = [0]
    coverage = {op: 0 for op in OPS}

    for index in range(count):
        # The first 19 instructions cover all operations.
        # The rest are randomized.
        if index < len(OPS):
            op = OPS[index]
        else:
            op = rng.choice(OPS)

        # Include x0 as a destination occasionally to verify
        # that writes to x0 are discarded.
        rd = 0 if rng.randrange(12) == 0 else rng.randint(1, 20)

        def source():
            if rng.randrange(100) < 65:
                return rng.choice(recent)
            return rng.randint(0, 20)

        rs1 = source()
        rs2 = source()

        if op in R_INFO:
            imm = 0
            b = regs[rs2]
        elif op in ("SLLI", "SRLI", "SRAI"):
            imm = rng.randint(0, 31)
            b = imm
        else:
            imm = rng.choice([
                -2048, -1024, -33, -1, 0,
                1, 7, 31, 127, 1023, 2047,
                rng.randint(-2048, 2047)
            ])
            b = u32(imm)

        a = regs[rs1]

        code = encode(op, rd, rs1, rs2, imm)
        result = execute(op, a, b)

        instructions.append(code)
        coverage[op] += 1

        if rd != 0:
            regs[rd] = result

        regs[0] = 0

        recent.append(rd)
        recent = recent[-4:]

    # Pad the program with NOPs to fill instruction memory.
    instructions += [0x00000013] * (256 - len(instructions))

    path = OUT / f"random_{seed}.hex"
    path.write_text(
        "".join(f"{x:08x}\n" for x in instructions)
    )

    return path, regs, coverage

def simulate(path):
    command = [
        "vvp", SIM,
        f"+PROGRAM={path}"
    ]

    result = subprocess.run(
        command,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        raise RuntimeError("Verilog simulation failed")

    actual = {}
    stats = None
    inside = False

    for line in result.stdout.splitlines():
        if line == "DAY28_BEGIN":
            inside = True
            continue

        if line == "DAY28_END":
            inside = False
            continue

        if not inside:
            continue

        parts = line.split()

        if parts[0] == "DAY28_REG":
            register = int(parts[1])
            actual[register] = int(parts[2], 16)

        elif parts[0] == "DAY28_STATS":
            stats = [int(x) for x in parts[1:]]

    if len(actual) != 32 or stats is None:
        print(result.stdout)
        raise RuntimeError("Incomplete CPU simulation output")

    return actual, stats

def main():
    total_programs = 10
    instructions_per_program = 80

    passed_programs = 0
    passed_checks = 0
    total_checks = 0
    combined_coverage = {op: 0 for op in OPS}

    print("=" * 52)
    print("DAY 28 - AUTOMATED RV32I ARITHMETIC VERIFICATION")
    print("=" * 52)

    for test in range(total_programs):
        seed = 2800 + test

        path, expected, coverage = generate(
            seed, instructions_per_program
        )

        actual, stats = simulate(path)

        mismatches = []

        for r in range(32):
            total_checks += 1

            if actual[r] == expected[r]:
                passed_checks += 1
            else:
                mismatches.append(
                    (r, actual[r], expected[r])
                )

        for op in OPS:
            combined_coverage[op] += coverage[op]

        stalls, fmem, fwb, redirects = stats

        if mismatches:
            print(f"\nFAIL: Program seed {seed}")
            print(f"Program file: {path}")

            for r, got, want in mismatches:
                print(
                    f"  x{r}: got={got:08x} "
                    f"expected={want:08x}"
                )

            print(
                f"Stalls={stalls} "
                f"EX/MEM={fmem} MEM/WB={fwb} "
                f"Redirects={redirects}"
            )

            print("Stopping at the first failing program.")
            sys.exit(1)

        # Arithmetic-only programs must not stall or redirect.
        if stalls != 0 or redirects != 0:
            print(
                f"FAIL: Unexpected pipeline control activity "
                f"for seed {seed}: "
                f"stalls={stalls}, redirects={redirects}"
            )
            sys.exit(1)

        passed_programs += 1

        print(
            f"PASS: Seed {seed} | "
            f"32/32 registers | "
            f"EX/MEM={fmem} MEM/WB={fwb}"
        )

    print("\nInstruction coverage:")
    for op in OPS:
        print(f"  {op:<6} : {combined_coverage[op]}")

    print("\n" + "=" * 52)
    print("DAY 28 FINAL SUMMARY")
    print("=" * 52)
    print(f"Programs Passed     = {passed_programs}/{total_programs}")
    print(
        f"Instructions Tested = "
        f"{total_programs * instructions_per_program}"
    )
    print(f"Register Checks     = {passed_checks}/{total_checks}")

    if all(combined_coverage[op] > 0 for op in OPS):
        print("All 19 arithmetic instruction types exercised")
    else:
        raise RuntimeError("Missing instruction coverage")

    print("ALL DAY 28 AUTOMATED TESTS PASSED")

if __name__ == "__main__":
    main()
