import json
from pathlib import Path
from collections import Counter

path = Path("synthesis/day40/netlist/cpu_xilinx.json")

data = json.loads(path.read_text())
modules = data["modules"]

print("=" * 60)
print("DAY 40 - FPGA MEMORY PRIMITIVE ANALYSIS")
print("=" * 60)

total = Counter()

for module_name, module in sorted(modules.items()):

    if module.get("attributes", {}).get("blackbox") == "00000000000000000000000000000001":
        continue

    cells = module.get("cells", {})
    memory_cells = []

    for cell_name, cell in cells.items():

        kind = cell["type"]

        if kind.startswith(("RAMB", "RAM32M", "RAM64M")):
            memory_cells.append((cell_name, kind))
            total[kind] += 1

    if memory_cells:
        print("\nMODULE:", module_name)

        for cell_name, kind in memory_cells:
            print(" ", kind, ":", cell_name)

print("\n" + "=" * 60)
print("MEMORY RESOURCE SUMMARY")
print("=" * 60)

for kind, count in sorted(total.items()):
    print(f"{kind:15s}: {count}")

print("=" * 60)
