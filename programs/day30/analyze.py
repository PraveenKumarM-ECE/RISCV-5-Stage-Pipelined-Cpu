import subprocess
import sys

BENCHMARKS = [
    {
        "name": "Independent ALU",
        "file": "independent",
        "instructions": 32,
        "stalls": 0,
        "redirects": 0,
        "registers": {"X1": 31},
    },
    {
        "name": "Dependent ALU",
        "file": "dependent",
        "instructions": 32,
        "stalls": 0,
        "redirects": 0,
        "registers": {"X1": 31},
    },
    {
        "name": "Load-use hazards",
        "file": "load_use",
        "instructions": 32,
        "stalls": 14,
        "redirects": 0,
        "registers": {"X1": 7, "X3": 98},
    },
    {
        "name": "Taken branches",
        "file": "branches",
        "instructions": 17,
        "stalls": 0,
        "redirects": 8,
        "registers": {
            "X1": 8,
            "X20": 0,
            "X21": 0,
        },
    },
]

def simulate(name):
    command = [
        "vvp",
        "sim/pipeline/day30_sim",
        "+PROGRAM=programs/day30/" + name + ".hex",
    ]

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        raise RuntimeError("Simulation failed: " + name)

    data = {}
    inside = False

    for line in result.stdout.splitlines():
        parts = line.split()

        if not parts:
            continue

        if parts[0] == "DAY30_BEGIN":
            inside = True
            continue

        if parts[0] == "DAY30_END":
            inside = False
            continue

        if inside and len(parts) == 2:
            key = parts[0].replace("DAY30_", "")
            if key.startswith("X"):
                data[key] = int(parts[1], 16)
            else:
                data[key] = int(parts[1])

    required = [
        "CYCLES", "STALLS", "FWD_MEM",
        "FWD_WB", "REDIRECTS",
        "X1", "X3", "X20", "X21",
    ]

    for key in required:
        if key not in data:
            raise RuntimeError(
                f"Missing {key} in simulation: {name}\n"
                + result.stdout
            )

    return data

def main():
    print("=" * 74)
    print("DAY 30 - FIVE-STAGE RISC-V PIPELINE PERFORMANCE REPORT")
    print("=" * 74)

    rows = []

    for benchmark in BENCHMARKS:
        data = simulate(benchmark["file"])
        name = benchmark["name"]
        instructions = benchmark["instructions"]

        expected_cycles = (
            instructions
            + 4
            + benchmark["stalls"]
            + 2 * benchmark["redirects"]
        )

        failures = []

        if data["CYCLES"] != expected_cycles:
            failures.append(
                f"cycles={data['CYCLES']} "
                f"expected={expected_cycles}"
            )

        if data["STALLS"] != benchmark["stalls"]:
            failures.append(
                f"stalls={data['STALLS']} "
                f"expected={benchmark['stalls']}"
            )

        if data["REDIRECTS"] != benchmark["redirects"]:
            failures.append(
                f"redirects={data['REDIRECTS']} "
                f"expected={benchmark['redirects']}"
            )

        for reg, expected in benchmark["registers"].items():
            if data[reg] != expected:
                failures.append(
                    f"{reg}={data[reg]} expected={expected}"
                )

        if failures:
            print(f"\nFAIL: {name}")
            for failure in failures:
                print(" ", failure)
            sys.exit(1)

        cycles = data["CYCLES"]
        cpi = cycles / instructions
        ipc = instructions / cycles

        rows.append((name, instructions, cycles, cpi, ipc, data))

        print(
            f"PASS: {name:<20} "
            f"cycles={cycles:<3} "
            f"stalls={data['STALLS']:<2} "
            f"redirects={data['REDIRECTS']}"
        )

    print("\n" + "-" * 74)
    print(
        f"{'Benchmark':<22}"
        f"{'Instr':>7}"
        f"{'Cycles':>9}"
        f"{'CPI':>9}"
        f"{'IPC':>9}"
    )
    print("-" * 74)

    for name, n, cycles, cpi, ipc, data in rows:
        print(
            f"{name:<22}"
            f"{n:>7}"
            f"{cycles:>9}"
            f"{cpi:>9.3f}"
            f"{ipc:>9.3f}"
        )

    print("\n" + "-" * 74)
    print("HAZARD ANALYSIS")
    print("-" * 74)

    for name, n, cycles, cpi, ipc, data in rows:
        print(f"\n{name}:")
        print(f"  Load stalls       : {data['STALLS']}")
        print(f"  EX/MEM forwarding : {data['FWD_MEM']}")
        print(f"  MEM/WB forwarding : {data['FWD_WB']}")
        print(f"  PC redirects      : {data['REDIRECTS']}")
        print(f"  CPI               : {cpi:.3f}")

    total_instructions = sum(r[1] for r in rows)
    total_cycles = sum(r[2] for r in rows)

    print("\n" + "=" * 74)
    print("DAY 30 FINAL SUMMARY")
    print("=" * 74)
    print(f"Benchmarks Passed  = {len(rows)}/4")
    print(f"Total Instructions = {total_instructions}")
    print(f"Total Cycles       = {total_cycles}")
    print(f"Aggregate CPI      = {total_cycles / total_instructions:.3f}")
    print("ALL DAY 30 PERFORMANCE TESTS PASSED")

if __name__ == "__main__":
    main()
