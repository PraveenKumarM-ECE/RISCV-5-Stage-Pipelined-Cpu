import json
from collections import Counter
from pathlib import Path

path = Path("synthesis/day35/netlist/riscv_cpu_core.json")

if not path.exists():
    raise SystemExit("ERROR: Day 35 JSON netlist not found")

with open(path) as f:
    modules = json.load(f)["modules"]

top = "riscv_pipeline_cpu"

def count_cells(name, stack=()):
    if name in stack:
        raise RuntimeError("Recursive module hierarchy detected")

    result = Counter()

    for cell in modules[name].get("cells", {}).values():
        kind = cell["type"]

        if kind in modules:
            result.update(count_cells(kind, stack + (name,)))
        else:
            result[kind] += 1

    return result

cells = count_cells(top)

mux = cells.get("$_MUX_", 0)

ff = sum(
    count for kind, count in cells.items()
    if kind.startswith(("$_DFF", "$_SDFF", "$_ADFF"))
)

logic = sum(
    count for kind, count in cells.items()
    if kind.startswith("$_")
    and kind != "$_MUX_"
    and not kind.startswith(("$_DFF", "$_SDFF", "$_ADFF"))
)

other = sum(
    count for kind, count in cells.items()
    if not kind.startswith("$_")
)

print("=" * 60)
print("DAY 35 - RISC-V CPU SYNTHESIS RESOURCE REPORT")
print("=" * 60)

print("Top module:", top)
print("Module definitions:", len(modules))

print("\nHIERARCHY-EXPANDED CELL COUNTS")
print("Multiplexers:", mux)
print("Flip-flops:", ff)
print("Other logic gates:", logic)
print("Other cells:", other)
print("Total cells:", sum(cells.values()))

print("\nTOP 15 CELL TYPES")

for kind, count in cells.most_common(15):
    print(f"{kind:<28} {count:>8}")

print("\nNOTE:")
print("Counts include instantiated module occurrences.")
print("These are generic Yosys cells, not FPGA LUTs.")
print("External instruction ROM is excluded.")

print("\nDAY 35 RESOURCE ANALYSIS COMPLETED")
