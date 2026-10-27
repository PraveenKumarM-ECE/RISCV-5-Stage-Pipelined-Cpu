import json
from pathlib import Path

path = Path("synthesis/day40/netlist/cpu_xilinx.json")

data = json.loads(path.read_text())
modules = data["modules"]

print("=" * 60)
print("DAY 40 - BLOCK RAM CONFIGURATION")
print("=" * 60)

found = 0

for module_name, module in modules.items():

    for cell_name, cell in module.get("cells", {}).items():

        if not cell["type"].startswith(("RAMB18", "RAMB36")):
            continue

        found += 1

        print("\nMODULE:", module_name)
        print("CELL:", cell_name)
        print("TYPE:", cell["type"])

        print("\nPARAMETERS:")

        for key, value in sorted(
            cell.get("parameters", {}).items()
        ):
            if (
                "WIDTH" in key
                or "WRITE_MODE" in key
                or "DO_REG" in key
                or "INIT" in key
            ):
                if key.startswith("INIT_"):
                    continue
                print(f"{key}: {value}")

        print("\nCONNECTED PORTS:")

        for key, value in sorted(
            cell.get("connections", {}).items()
        ):
            if (
                "ADDR" in key
                or "WE" in key
                or "EN" in key
                or "CLK" in key
            ):
                print(f"{key}: {len(value)} bits")

print("\n" + "=" * 60)
print("BLOCK RAM INSTANCES:", found)
