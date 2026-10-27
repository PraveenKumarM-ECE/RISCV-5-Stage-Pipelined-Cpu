from pathlib import Path
import re

source = Path("tb/pipeline")
target = Path("synthesis/day38/tb")

tests = [
    "tb_day26_regression.sv",
    "tb_day27_corner_cases.sv",
    "tb_day28_auto.sv",
    "tb_day29_auto.sv",
    "tb_day30_performance.sv",
]

for name in tests:
    text = (source / name).read_text()

    # Add test-only instruction storage.
    module_match = re.search(
        r"\bmodule\s+\w+\s*;",
        text
    )
    assert module_match, f"Module declaration not found: {name}"

    insertion = """
    reg [31:0] test_rom [0:255];
    wire [31:0] instruction_feed;

    assign instruction_feed = test_rom[pc[9:2]];
"""

    text = (
        text[:module_match.end()]
        + insertion
        + text[module_match.end():]
    )

    # Connect the new instruction input.
    pattern = r"(riscv_pipeline_cpu\s+dut\s*\()"
    assert re.search(pattern, text), name

    text = re.sub(
        pattern,
        r"\1\n        .instruction_in(instruction_feed),",
        text,
        count=1
    )

    # Redirect program loading to the test ROM.
    old = "dut.stage_if.imem.memory"
    assert old in text, name
    text = text.replace(old, "test_rom")

    (target / name).write_text(text)

    print("ADAPTED:", name)

print("All 5 testbenches adapted.")
