from pathlib import Path
import subprocess
import re
import sys

root = Path("synthesis/day38")
reports = root / "reports"
reference = root / "reference"
sim = root / "sim"

reports.mkdir(parents=True, exist_ok=True)

total = 0
passed = 0
failed = 0

def run(cpu, day, program):
    folder = reference if cpu == "original" else sim
    executable = folder / f"tb_day{day}_auto"

    if not executable.is_file():
        print(f"ERROR: Missing executable: {executable}")
        sys.exit(1)

    command = [
        "vvp",
        str(executable),
        f"+PROGRAM={program}"
    ]

    if day == 29:
        command.append("+CYCLES=120")

    result = subprocess.run(
        command,
        capture_output=True,
        text=True
    )

    log = reports / (
        f"compare_day{day}_{cpu}_{Path(program).stem}.log"
    )
    log.write_text(result.stdout + result.stderr)

    if result.returncode != 0 or f"DAY{day}_END" not in result.stdout:
        print(f"SIMULATION FAILED: {cpu} {program}")
        print(result.stdout[-1500:])
        print(result.stderr[-1500:])
        sys.exit(1)

    return result.stdout


def extract(output, day, kind):
    pattern = re.compile(
        rf"^DAY{day}_{kind}\s+(\d+)\s+([0-9a-fA-F]{{8}})$",
        re.MULTILINE
    )

    return {
        int(index): int(value, 16)
        for index, value in pattern.findall(output)
    }


def compare(day, name, original, updated, kind, expected):
    global total, passed, failed

    a = extract(original, day, kind)
    b = extract(updated, day, kind)

    if set(a) != set(range(expected)) or set(b) != set(range(expected)):
        print(f"ERROR: Incomplete {kind} output for {name}")
        print(f"Original entries: {len(a)}")
        print(f"Day 38 entries: {len(b)}")
        sys.exit(1)

    for index in range(expected):
        total += 1

        if a[index] == b[index]:
            passed += 1
        else:
            failed += 1
            print(
                f"FAIL: {name} {kind}[{index}] "
                f"original={a[index]:08x} "
                f"day38={b[index]:08x}"
            )


print("=" * 55)
print("DAY 38 - CPU STATE COMPARISON")
print("=" * 55)

for number in range(2800, 2810):
    name = f"random_{number}"
    program = f"programs/day28/{name}.hex"

    a = run("original", 28, program)
    b = run("day38", 28, program)

    before = failed
    compare(28, name, a, b, "REG", 32)

    print(f"DAY 28 {name}: {'PASS' if failed == before else 'FAIL'}")


day29 = [
    "branch_compare",
    "byte_memory",
    "half_memory",
    "jumps_flush",
    "load_branch_loop",
    "word_loads"
]

for name in day29:
    program = f"programs/day29/{name}.hex"

    a = run("original", 29, program)
    b = run("day38", 29, program)

    before = failed

    compare(29, name, a, b, "REG", 32)
    compare(29, name, a, b, "MEM", 64)

    print(f"DAY 29 {name}: {'PASS' if failed == before else 'FAIL'}")


print("=" * 55)
print(f"TOTAL CHECKS : {total}")
print(f"PASSED       : {passed}")
print(f"FAILED       : {failed}")
print("=" * 55)

if failed == 0 and total == 896:
    print("DAY 38 RANDOMIZED REGRESSION: PASSED")
else:
    print("DAY 38 RANDOMIZED REGRESSION: FAILED")
    sys.exit(1)
