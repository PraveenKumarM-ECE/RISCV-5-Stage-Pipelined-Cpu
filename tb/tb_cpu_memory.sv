`timescale 1ns/1ps

module tb_cpu_memory;

    logic clk, reset;
    logic [31:0] pc, instruction;

    integer tests = 0;
    integer errors = 0;

    riscv_cpu dut (
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
        input [8*32-1:0] name;
        begin
            tests = tests + 1;

            if (actual !== expected) begin
                $display("FAIL: %0s Got=%0d Expected=%0d",
                         name, actual, expected);
                errors = errors + 1;
            end
            else
                $display("PASS: %0s = %0d", name, actual);
        end
    endtask

    initial begin
        $dumpfile("sim/cpu_memory.vcd");
        $dumpvars(0, tb_cpu_memory);

        reset = 1;
        #12;
        @(negedge clk);
        reset = 0;

        // Execute exactly five instructions
        repeat (5) begin
            @(posedge clk);
            #1;
        end

        check(dut.regfile.regs[1], 100, "x1");
        check(dut.regfile.regs[2], 50, "x2");
        check(dut.dmem.memory[25], 50, "Memory[100]");
        check(dut.regfile.regs[3], 50, "x3");
        check(dut.regfile.regs[4], 100, "x4");
        check(dut.regfile.regs[0], 0, "x0");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL CPU MEMORY TESTS PASSED");
        else
            $fatal(1, "CPU MEMORY TEST FAILED");

        $finish;
    end

endmodule
