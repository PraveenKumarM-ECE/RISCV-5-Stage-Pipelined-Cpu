#!/usr/bin/env bash

set -uo pipefail

cd "$(dirname "$0")/.."

RTL=(
    rtl/alu.sv
    rtl/register_file.sv
    rtl/program_counter.sv
    rtl/instruction_memory.sv
    rtl/instruction_decoder.sv
    rtl/immediate_generator.sv
    rtl/control_unit.sv
    rtl/data_memory.sv
    rtl/riscv_cpu.sv
)

DAYS=(11 12 13 14 15 16 17)

TESTS=(
    tb_riscv_cpu
    tb_cpu_memory
    tb_cpu_branch
    tb_cpu_jump
    tb_cpu_day15
    tb_cpu_day16
    tb_cpu_day17
)

mkdir -p sim

# Preserve the currently selected program.
backup=$(mktemp)
cp programs/program.hex "$backup"

restore_program() {
    cp "$backup" programs/program.hex
    rm -f "$backup"
}

trap restore_program EXIT

passed=0
failed=0

for i in "${!DAYS[@]}"; do

    day="${DAYS[$i]}"
    tb="${TESTS[$i]}"

    echo
    echo "================================"
    echo "DAY $day REGRESSION"
    echo "================================"

    if ! cp "programs/day${day}_program.hex" programs/program.hex; then
        echo "FAIL: Program file missing"
        ((failed+=1))
        continue
    fi

    if iverilog -g2012 \
        -s "$tb" \
        -o "sim/regression_day${day}" \
        "${RTL[@]}" \
        "tb/${tb}.sv" \
        && vvp "sim/regression_day${day}"; then

        echo "DAY $day: PASS"
        ((passed+=1))

    else
        echo "DAY $day: FAIL"
        ((failed+=1))
    fi

done

echo
echo "================================"
echo "REGRESSION SUMMARY"
echo "================================"
echo "Suites passed: $passed"
echo "Suites failed: $failed"

if [ "$failed" -eq 0 ]; then
    echo "ALL REGRESSION SUITES PASSED"
else
    echo "REGRESSION FAILED"
    exit 1
fi
