import subprocess
import re
from pathlib import Path

base = Path("verification/day42")
sim = base / "sim"
reports = base / "reports"

sim.mkdir(parents=True, exist_ok=True)
reports.mkdir(parents=True, exist_ok=True)

src = sorted(base.glob("*.sv"))
tb_dir = Path("synthesis/day38/tb")

tests = []

for i in range(1, 7):
    files = sorted(Path("programs/day26").glob(f"case{i}_*.hex"))
    if len(files) != 1:
        raise RuntimeError(f"Missing or duplicate Day 26 case {i}")
    tests.append(("tb_day26_regression", f"day26_case{i}",
                  [f"+CASE={i}", f"+PROGRAM={files[0]}"]))

for i in range(1, 7):
    files = sorted(Path("programs/day27").glob(f"case{i}_*.hex"))
    if len(files) != 1:
        raise RuntimeError(f"Missing or duplicate Day 27 case {i}")
    tests.append(("tb_day27_corner_cases", f"day27_case{i}",
                  [f"+CASE={i}", f"+PROGRAM={files[0]}"]))

for i in range(2800, 2810):
    program = Path(f"programs/day28/random_{i}.hex")
    tests.append(("tb_day28_auto", f"day28_{i}",
                  [f"+PROGRAM={program}"]))

day29 = [
    "branch_compare",
    "byte_memory",
    "half_memory",
    "jumps_flush",
    "load_branch_loop",
    "word_loads"
]

for name in day29:
    program = Path(f"programs/day29/{name}.hex")
    tests.append(("tb_day29_auto", f"day29_{name}",
                  [f"+PROGRAM={program}", "+CYCLES=120"]))

day30 = [
    "independent",
    "dependent",
    "load_use",
    "branches"
]

for name in day30:
    program = Path(f"programs/day30/{name}.hex")
    tests.append(("tb_day30_performance", f"day30_{name}",
                  [f"+PROGRAM={program}"]))

print("=" * 60)
print("DAY 42 - FINAL CPU REGRESSION")
print("=" * 60)

executables = {}
compile_failed = set()

for tb_name in sorted(set(t[0] for t in tests)):
    exe = sim / tb_name
    tb = tb_dir / f"{tb_name}.sv"

    cmd = [
        "iverilog", "-g2012",
        "-s", tb_name,
        "-o", str(exe),
        *map(str, src),
        str(tb)
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    (reports / f"{tb_name}_compile.log").write_text(
        result.stdout + result.stderr
    )

    if result.returncode != 0:
        compile_failed.add(tb_name)
        print("COMPILE FAIL:", tb_name)
    else:
        executables[tb_name] = exe
        print("COMPILED:", tb_name)

passed = 0
failed = 0
executed = 0

summary = []

for tb_name, name, args in tests:
    log = reports / f"{name}.log"

    if tb_name in compile_failed:
        status = "COMPILE FAIL"
    elif not all(
        Path(arg.split("=", 1)[1]).exists()
        for arg in args if arg.startswith("+PROGRAM=")
    ):
        status = "MISSING PROGRAM"
    else:
        try:
            result = subprocess.run(
                ["vvp", str(executables[tb_name]), *map(str, args)],
                capture_output=True,
                text=True,
                timeout=120
            )

            output = result.stdout + result.stderr
            log.write_text(output)
            executed += 1

            has_error = bool(re.search(
                r"(?im)^\s*(?:FATAL:|ERROR:|FAIL:|"
                r"DAY\s*\d+\s+CASE\s+\d+\s+FAILED\b)",
                output
            ))

            if result.returncode != 0 or has_error:
                status = "FAIL"
            else:
                status = "EXECUTED"

        except subprocess.TimeoutExpired:
            status = "TIMEOUT"
            log.write_text("Simulation exceeded 120 seconds\n")

    if status == "EXECUTED":
        passed += 1
    else:
        failed += 1

    summary.append(f"{name}: {status}")
    print(f"{name}: {status}")

summary.extend([
    "",
    f"TOTAL PROGRAMS: {len(tests)}",
    f"EXECUTED WITHOUT DETECTED ERRORS: {passed}",
    f"FAILED OR NOT EXECUTED: {failed}"
])

(reports / "execution_summary.txt").write_text(
    "\n".join(summary) + "\n"
)

print("=" * 60)
print("TOTAL PROGRAMS:", len(tests))
print("EXECUTED WITHOUT DETECTED ERRORS:", passed)
print("FAILED OR NOT EXECUTED:", failed)
print("=" * 60)
print("NOTE: EXECUTED does not yet confirm functional PASS.")
