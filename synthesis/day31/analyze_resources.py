import json
from pathlib import Path
from collections import Counter

path = Path("synthesis/day31/netlist/riscv_pipeline_netlist.json")

if not path.exists():
    print("ERROR: JSON netlist not found!")
    exit(1)

with open(path) as f:
    data = json.load(f)

modules = data["modules"]
total = Counter()

print("=" * 55)
print("DAY 31 - RISC-V CPU SYNTHESIS RESOURCE REPORT")
print("=" * 55)

print("Total module definitions:", len(modules))

for name, module in sorted(modules.items()):
    cells = Counter(
        cell["type"]
        for cell in module.get("cells", {}).values()
    )

    total.update(cells)

    print(f"\nModule: {name}")
    print("Direct cells:", sum(cells.values()))

    for cell_type, count in cells.most_common(8):
        print(f"  {cell_type:<25} {count}")

print("\n" + "=" * 55)
print("CELL TYPES ACROSS MODULE DEFINITIONS")
print("=" * 55)

for cell_type, count in total.most_common():
    print(f"{cell_type:<30} {count}")

print("\nNOTE:")
print("These are generic synthesized cell counts.")
print("They are not FPGA LUT or physical flip-flop counts.")
print("Hierarchical module reuse is not expanded in these totals.")

print("\nDAY 31 RESOURCE REPORT GENERATED")
