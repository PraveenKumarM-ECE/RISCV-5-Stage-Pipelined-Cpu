`timescale 1ns/1ps

module tb_pipeline_cpu;

    logic clk;
    logic reset;

    logic [31:0] pc;
    logic [31:0] instruction;

    integer tests = 0;
    integer errors = 0;
    integer cycle;

    riscv_pipeline_cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*40-1:0] name;
        begin
            tests = tests + 1;

            if (actual !== expected) begin
                $display(
                    "FAIL: %0s Got=%h Expected=%h",
                    name, actual, expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %0s = %h",
                    name, expected
                );
            end
        end
    endtask

    initial begin
        $dumpfile("sim/pipeline/day24_pipeline.vcd");
        $dumpvars(0, tb_pipeline_cpu);

        reset = 1;

        #12;

        check(pc, 0, "Reset PC");

        @(negedge clk);
        reset = 0;

        $display("-------------------------");
        $display("Starting pipeline execution");
        $display("-------------------------");

        // Run enough cycles for all five instructions
        // to travel through IF, ID, EX, MEM and WB.
        for (cycle = 1; cycle <= 12; cycle = cycle + 1) begin
            @(posedge clk);
            #1;

            $display(
                "Cycle %0d | PC=%h | WB_RD=%0d | WB_DATA=%h | WB_EN=%b",
                cycle,
                pc,
                dut.wb_rd,
                dut.wb_data,
                dut.wb_reg_write
            );
        end

        $display("-------------------------");
        $display("Checking register values");
        $display("-------------------------");

        check(dut.stage_id.regfile.regs[1],
              10, "Register x1");

        check(dut.stage_id.regfile.regs[2],
              20, "Register x2");

        check(dut.stage_id.regfile.regs[3],
              30, "Register x3");

        check(dut.stage_id.regfile.regs[4],
              40, "Register x4");

        check(dut.stage_id.regfile.regs[5],
              50, "Register x5");

        check(dut.stage_id.regfile.regs[0],
              0, "Register x0");

        check(pc, 48, "PC after 12 cycles");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 24 PIPELINE TESTS PASSED");
        else
            $fatal(1, "DAY 24 PIPELINE TEST FAILED");

        $finish;
    end

endmodule
