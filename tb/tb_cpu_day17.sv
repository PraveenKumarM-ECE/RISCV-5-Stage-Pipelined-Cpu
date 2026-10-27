`timescale 1ns/1ps

module tb_cpu_day17;

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
                $display("FAIL: %0s Got=%h Expected=%h",
                         name, actual, expected);
                errors = errors + 1;
            end
            else
                $display("PASS: %0s = %h", name, expected);
        end
    endtask

    initial begin
        $dumpfile("sim/cpu_day17.vcd");
        $dumpvars(0, tb_cpu_day17);

        reset = 1;
        #12;
        @(negedge clk);
        reset = 0;

        repeat (19) begin
            @(posedge clk);
            #1;
        end

        check(dut.regfile.regs[1], 100, "x1");
        check(dut.regfile.regs[2], 32'hFFFFFFFF, "x2");
        check(dut.regfile.regs[3], 32'h12, "x3");
        check(dut.regfile.regs[4], 32'h12, "x4");
        check(dut.regfile.regs[5], 32'hFFFFFFFF, "x5");
        check(dut.regfile.regs[6], 32'h345, "x6");
        check(dut.regfile.regs[7], 32'h345, "x7");
        check(dut.regfile.regs[8], 32'h345, "x8");
        check(dut.regfile.regs[9], 32'h034512FF, "x9");
        check(dut.regfile.regs[10], 32'hFFFFFF80, "x10");
        check(dut.regfile.regs[11], 32'hFFFFFF80, "x11");
        check(dut.regfile.regs[12], 32'h80, "x12");
        check(dut.regfile.regs[13], 32'hFFFF8045, "x13");
        check(dut.regfile.regs[14], 32'h8045, "x14");
        check(dut.regfile.regs[15], 32'h804512FF, "x15");
        check(dut.regfile.regs[0], 0, "x0");

        check(dut.dmem.memory[25], 32'h804512FF, "Memory[100]");
        check(pc, 76, "Final PC");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 17 MEMORY TESTS PASSED");
        else
            $fatal(1, "DAY 17 MEMORY TEST FAILED");

        $finish;
    end

endmodule
