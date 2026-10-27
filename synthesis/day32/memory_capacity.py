print("=" * 55)
print("DAY 32 - RISC-V CPU MEMORY CAPACITY")
print("=" * 55)

items = [
    ("Instruction memory", 256, 32),
    ("Data memory", 256, 32),
    ("Register file", 32, 32),
]

total = 0

for name, depth, width in items:
    bits = depth * width
    total += bits

    print(f"\n{name}")
    print(f"  Words      : {depth}")
    print(f"  Word width : {width} bits")
    print(f"  Capacity   : {bits} bits")
    print(f"  Capacity   : {bits / 8:.0f} bytes")

print("\n" + "=" * 55)
print(f"Total logical storage: {total:,} bits")
print(f"Total logical storage: {total / 1024 / 8:.2f} KiB")
print("=" * 55)
