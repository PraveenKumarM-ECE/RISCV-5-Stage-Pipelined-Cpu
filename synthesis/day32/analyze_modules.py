import json
from pathlib import Path
from collections import Counter

path = Path("synthesis/day31/netlist/riscv_pipeline_netlist.json")

with open(path) as f:
    data = json.load(f)

modules = data["modules"]

rows = []

for name, module in modules.items():
    cells = Counter(
        cell["type"]
        for cell in module.get("cells", {}).values()
    )

    mux = cells.get("$_MUX_", 0)

    ff = sum(
        count
        for kind, count in cells.items()
        if kind.startswith("$_DFF") or kind.startswith("$_SDFF")
    )

    logic = sum(
        count
        for kind, count in cells.items()
        if kind.startswith("$_")
        and not kind.startswith("$_DFF")
        and not kind.startswith("$_SDFF")
        and kind != "$_MUX_"
    )

    rows.append((name, mux, ff, logic))

rows.sort(key=lambda x: x[1] + x[2] + x[3], reverse=True)

print("=" * 78)
print("DAY 32 - MODULE RESOURCE ANALYSIS")
print("=" * 78)

print(f"{'Module':<30} {'MUX':>10} {'FF':>10} {'Other':>10}")

for name, mux, ff, logic in rows:
    print(f"{name:<30} {mux:>10} {ff:>10} {logic:>10}")

print("=" * 78)
print("Counts are per module definition, not flattened instance totals.")
print("Only generic mapped cells are counted in these columns.")
