import json
from collections import Counter

def analyze(path):
    with open(path) as f:
        modules = json.load(f)["modules"]

    def count(name, stack=()):
        if name in stack:
            raise RuntimeError("Recursive hierarchy detected")

        result = Counter()

        for cell in modules[name].get("cells", {}).values():
            kind = cell["type"]

            if kind in modules:
                result.update(count(kind, stack + (name,)))
            else:
                result[kind] += 1

        return result

    cells = count("riscv_pipeline_cpu")

    mux = cells.get("$_MUX_", 0)

    ff = sum(
        n for kind, n in cells.items()
        if kind.startswith(("$_DFF", "$_SDFF", "$_ADFF"))
    )

    return mux, ff, sum(cells.values())

old = analyze(
    "synthesis/day31/netlist/riscv_pipeline_netlist.json"
)

new = analyze(
    "synthesis/day35/netlist/riscv_cpu_core.json"
)

print("=" * 60)
print("DAY 31 VS DAY 35 SYNTHESIS COMPARISON")
print("=" * 60)

print(f"{'Resource':<22} {'Day 31':>12} {'Day 35':>12}")

for label, a, b in zip(
    ["Multiplexers", "Flip-flops", "Total cells"],
    old,
    new
):
    print(f"{label:<22} {a:>12} {b:>12}")

print("\nDay 31: CPU with fixed NOP instruction ROM")
print("Day 35: CPU with external instruction input")
print("Counts are generic cells, not FPGA resources.")
