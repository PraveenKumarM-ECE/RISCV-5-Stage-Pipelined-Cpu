#!/bin/bash
set -e

cd ~/projects/riscv-cpu

names=(
    case1_priority
    case2_alu
    case3_load
    case4_memory
    case5_signed
    case6_control
)

passed=0

for i in 1 2 3 4 5 6; do
    name=${names[$((i-1))]}

    echo ""
    echo "===================================="
    echo "Running Day 26 Case $i: $name"
    echo "===================================="

    vvp sim/pipeline/day26_regression_sim \
        +CASE=$i \
        +PROGRAM=programs/day26/$name.hex

    cp sim/pipeline/day26_regression.vcd \
       sim/pipeline/day26_case${i}.vcd

    passed=$((passed + 1))
done

echo ""
echo "===================================="
echo "DAY 26 REGRESSION SUMMARY"
echo "===================================="
echo "Cases Passed = $passed"
echo "Cases Failed = $((6-passed))"
echo "ALL DAY 26 REGRESSION CASES PASSED"
