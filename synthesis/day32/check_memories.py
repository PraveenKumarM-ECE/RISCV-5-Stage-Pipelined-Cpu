import json
from pathlib import Path

path = Path("synthesis/day32/netlist/memory_inference.json")

with open(path) as f:
    data = json.load(f)

print("=" * 65)
print("DAY 32 - MEMORY INFERENCE REPORT")
print("=" * 65)

found = 0

for module_name, module in sorted(data["modules"].items()):
    for cell_name, cell in module.get("cells", {}).items():
        cell_type = cell["type"]

        if not cell_type.startswith("$mem"):
            continue

        params = cell.get("parameters", {})

        def get_number(key):
            value = params.get(key)
            if value is None:
                return "unknown"
            if isinstance(value, str) and all(
                c in "01" for c in value
            ):
                return int(value, 2)
            return str(value)

        width = get_number("WIDTH")
        size = get_number("SIZE")
        read_ports = get_number("RD_PORTS")
        write_ports = get_number("WR_PORTS")

        print(f"\nModule: {module_name}")
        print(f"Memory cell: {cell_name}")
        print(f"Cell type: {cell_type}")
        print(f"Width: {width} bits")
        print(f"Depth: {size} words")
        print(f"Read ports: {read_ports}")
        print(f"Write ports: {write_ports}")

        found += 1

print("\n" + "=" * 65)
print("Memory cells found:", found)

if found == 0:
    print("No abstract memory cells remain at this stage.")
    print("Check whether optimization removed or transformed them.")

print("Memory inference inspection completed.")
