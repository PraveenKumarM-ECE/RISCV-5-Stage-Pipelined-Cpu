#!/bin/bash
set -e

cd ~/projects/riscv-cpu

echo "Compiling Day 27 corner-case testbench..."

iverilog -g2012 -s tb_day27_corner_cases \
    -o sim/pipeline/day27_sim \
    rtl/program_counter.sv \
    rtl/instruction_memory.sv \
    rtl/instruction_decoder.sv \
    rtl/immediate_generator.sv \
    rtl/control_unit.sv \
    rtl/register_file.sv \
    rtl/alu.sv \
    rtl/data_memory.sv \
    rtl/pipeline/if_stage.sv \
    rtl/pipeline/if_id_reg.sv \
    rtl/pipeline/id_stage.sv \
    rtl/pipeline/id_ex_reg.sv \
    rtl/pipeline/ex_stage.sv \
    rtl/pipeline/ex_mem_reg.sv \
    rtl/pipeline/mem_stage.sv \
    rtl/pipeline/mem_wb_reg.sv \
    rtl/pipeline/wb_stage.sv \
    rtl/pipeline/forwarding_unit.sv \
    rtl/pipeline/hazard_detection_unit.sv \
    rtl/pipeline/riscv_pipeline_cpu.sv \
    tb/pipeline/tb_day27_corner_cases.sv

names=(
    case1_load_chain
    case2_same_rd
    case3_load_branch
    case4_store_hazards
    case5_branch_store
    case6_loop
)

passed=0

for i in 1 2 3 4 5 6; do
    name=${names[$((i-1))]}

    echo ""
    echo "=================================="
    echo "Day 27 Case $i: $name"
    echo "=================================="

    vvp sim/pipeline/day27_sim \
        +CASE=$i \
        +PROGRAM=programs/day27/$name.hex

    cp sim/pipeline/day27_corner_cases.vcd \
       sim/pipeline/day27_case${i}.vcd

    passed=$((passed+1))
done

echo ""
echo "=================================="
echo "DAY 27 FINAL SUMMARY"
echo "=================================="
echo "Cases Passed = $passed"
echo "Cases Failed = $((6-passed))"
echo "ALL DAY 27 CORNER-CASE TESTS PASSED"
