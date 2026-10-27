import subprocess
from pathlib import Path

src = Path("synthesis/day39/src")
reports = Path("synthesis/day39/reports")

reports.mkdir(parents=True, exist_ok=True)

files = sorted(src.glob("*.sv"))

passed = []
failed = []

print("=" * 55)
print("DAY 39 - INDIVIDUAL RTL MODULE DIAGNOSTIC")
print("=" * 55)

for file in files:
    name = file.stem

    command = (
        f"read_verilog -sv {file}; "
        f"hierarchy -check -top {name}; "
        "proc"
    )

    result = subprocess.run(
        ["yosys", "-Q", "-T", "-p", command],
        capture_output=True,
        text=True
    )

    log = result.stdout + result.stderr
    (reports / f"module_{name}.log").write_text(log)

    if result.returncode == 0:
        passed.append(name)
        print(f"PASS : {name}")
    else:
        failed.append(name)
        print(f"FAIL : {name}")

        for line in log.splitlines():
            if "ERROR:" in line:
                print("      " + line.strip())

print("=" * 55)
print("PASSED:", len(passed))
print("FAILED:", len(failed))

if failed:
    print("FAILING MODULES:", ", ".join(failed))
else:
    print("ALL MODULES PASSED INDIVIDUAL PROCESSING")
