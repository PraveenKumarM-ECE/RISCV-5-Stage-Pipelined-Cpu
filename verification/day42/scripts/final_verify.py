from pathlib import Path
import subprocess
import re
import sys

base = Path("verification/day42")
reports = base / "reports"
reference = Path("synthesis/day38/reference")

total = 0
passed = 0
failed = 0

def check(name, condition):
    global total, passed, failed
    total += 1
    if condition:
        passed += 1
        print(f"PASS: {name}")
    else:
        failed += 1
        print(f"FAIL: {name}")

def read_log(name):
    path = reports / f"{name}.log"
    if not path.exists():
        return ""
    return path.read_text()

def extract(output, day, kind):
    pattern = rf"^DAY{day}_{kind}\s+(\d+)\s+([0-9a-fA-F]{{8}})$"
    return {
        int(i): int(v, 16)
        for i, v in re.findall(pattern, output, re.MULTILINE)
    }

def reference_run(day, program):
    exe = reference / f"tb_day{day}_auto"
    if not exe.exists():
        raise FileNotFoundError(exe)

    cmd = ["vvp", str(exe), f"+PROGRAM={program}"]
    if day == 29:
        cmd.append("+CYCLES=120")

    result = subprocess.run(
        cmd, capture_output=True, text=True, timeout=120
    )

    if result.returncode != 0 or f"DAY{day}_END" not in result.stdout:
        raise RuntimeError(f"Reference failed: {program}")

    return result.stdout

print("=" * 55)
print("DAY 42 - FINAL FUNCTIONAL VERIFICATION")
print("=" * 55)

print("\nDIRECTED TESTS")

for day in (26, 27):
    for i in range(1, 7):
        output = read_log(f"day{day}_case{i}")

        marker = f"DAY {day} CASE {i} PASSED"
        match = re.search(
            r"Total Tests\s*=\s*(\d+).*?"
            r"Passed\s*=\s*(\d+).*?"
            r"Failed\s*=\s*(\d+)",
            output, re.DOTALL
        )

        valid = (
            marker in output
            and match is not None
            and int(match.group(1)) == int(match.group(2))
            and int(match.group(3)) == 0
        )

        check(f"Day {day} Case {i}", valid)

print("\nRANDOMIZED STATE COMPARISON")

state_checks = 0
state_passed = 0

cases = [
    (28, f"random_{i}", f"day28_{i}")
    for i in range(2800, 2810)
]

cases += [
    (29, name, f"day29_{name}")
    for name in [
        "branch_compare",
        "byte_memory",
        "half_memory",
        "jumps_flush",
        "load_branch_loop",
        "word_loads"
    ]
]

for day, name, log_name in cases:
    program = f"programs/day{day}/{name}.hex"
    current = read_log(log_name)

    try:
        original = reference_run(day, program)
        complete = f"DAY{day}_END" in current

        kinds = [("REG", 32)]
        if day == 29:
            kinds.append(("MEM", 64))

        case_ok = complete

        for kind, count in kinds:
            a = extract(original, day, kind)
            b = extract(current, day, kind)

            if set(a) != set(range(count)):
                case_ok = False
                continue

            if set(b) != set(range(count)):
                case_ok = False
                continue

            for index in range(count):
                state_checks += 1

                if a[index] == b[index]:
                    state_passed += 1
                else:
                    case_ok = False
                    print(
                        f"MISMATCH: {name} {kind}[{index}] "
                        f"reference={a[index]:08x} "
                        f"day42={b[index]:08x}"
                    )

        check(f"Day {day} {name}", case_ok)

    except Exception as error:
        check(f"Day {day} {name}", False)
        print("ERROR:", error)

print("\nPERFORMANCE BENCHMARKS")

for name in ["independent", "dependent", "load_use", "branches"]:
    output = read_log(f"day30_{name}")

    complete = (
        "DAY30_BEGIN" in output
        and "DAY30_END" in output
        and re.search(r"DAY30_CYCLES\s+\d+", output) is not None
        and "FATAL:" not in output
    )

    check(f"Day 30 {name}", complete)

print("\n" + "=" * 55)
print("FUNCTIONAL TEST CASES:", total)
print("PASSED:", passed)
print("FAILED:", failed)
print("STATE CHECKS:", state_checks)
print("STATE MATCHES:", state_passed)
print("=" * 55)

success = (
    failed == 0
    and total == 32
    and state_checks == 896
    and state_passed == 896
)

if success:
    print("DAY 42 FINAL VERIFICATION: PASSED")
else:
    print("DAY 42 FINAL VERIFICATION: FAILED")

sys.exit(0 if success else 1)
