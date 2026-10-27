`timescale 1ns/1ps

module tb_riscv_system;

    logic clk;
    logic reset;

    logic [31:0] pc;
    logic [31:0] instruction;

    integer passed = 0;
    integer failed = 0;

    riscv_system dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic check(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        begin
            if (actual === expected) begin
                passed = passed + 1;
                $display("PASS %s = %0d", name, actual);
            end
            else begin
                failed = failed + 1;
                $display(
                    "FAIL %s got=%0d expected=%0d",
                    name, actual, expected
                );
            end
        end
    endtask

    initial begin
        reset = 1;

        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 0;

        repeat (35) @(posedge clk);
        @(negedge clk);

        check("x1", dut.cpu.stage_id.regfile.regs[1], 5);
        check("x2", dut.cpu.stage_id.regfile.regs[2], 10);
        check("x3", dut.cpu.stage_id.regfile.regs[3], 15);
        check("x4", dut.cpu.stage_id.regfile.regs[4], 15);
        check("x5", dut.cpu.stage_id.regfile.regs[5], 20);

        check(
            "memory[0]",
            dut.cpu.stage_mem.dmem.memory[0],
            15
        );

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("DAY 34 INTEGRATION TEST PASSED");
        else
            $fatal(1, "DAY 34 INTEGRATION TEST FAILED");

        $finish;
    end

endmodule
