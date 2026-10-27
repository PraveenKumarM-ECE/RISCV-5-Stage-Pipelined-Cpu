`timescale 1ns/1ps

module tb_riscv_cpu;

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

    task check_register;
        input [4:0] reg_num;
        input [31:0] expected;
        begin
            tests = tests + 1;

            if (dut.regfile.regs[reg_num] !== expected) begin
                $display("FAIL: x%0d = %0d, expected %0d",
                    reg_num, dut.regfile.regs[reg_num], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: x%0d = %0d",
                    reg_num, dut.regfile.regs[reg_num]);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/riscv_cpu.vcd");
        $dumpvars(0, tb_riscv_cpu);

        reset = 1;
        #2;
        #10;
        @(negedge clk);
        reset = 0;

        // Execute four instructions
        repeat (4) begin
            @(posedge clk);
            #1;
            $display("PC=%0d Instruction=%h",
                     pc, instruction);
        end

        check_register(1, 10);
        check_register(2, 20);
        check_register(3, 30);
        check_register(4, 10);
        check_register(0, 0);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("FIRST RISC-V CPU PROGRAM PASSED");
        else
            $fatal(1, "CPU TEST FAILED");

        $finish;
    end

endmodule