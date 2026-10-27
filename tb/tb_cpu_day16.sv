`timescale 1ns/1ps

module tb_cpu_day16;

    logic clk, reset;
    logic [31:0] pc, instruction;

    integer tests = 0;
    integer errors = 0;
    integer i;

    riscv_cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check_reg;
        input [4:0] r;
        input [31:0] expected;
        begin
            tests = tests + 1;

            if (dut.regfile.regs[r] !== expected) begin
                $display("FAIL: x%0d Got=%h Expected=%h",
                    r, dut.regfile.regs[r], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: x%0d = %h",
                    r, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/cpu_day16.vcd");
        $dumpvars(0, tb_cpu_day16);

        reset = 1;
        #12;
        @(negedge clk);
        reset = 0;

        // Execute 21 instructions
        repeat (21) begin
            @(posedge clk);
            #1;
        end

        check_reg(1, 12);
        check_reg(2, 5);
        check_reg(3, 17);
        check_reg(4, 7);
        check_reg(5, 4);
        check_reg(6, 13);
        check_reg(7, 9);
        check_reg(8, 1);
        check_reg(9, 1);
        check_reg(10, 160);
        check_reg(11, 0);
        check_reg(12, 32'hFFFFFFF0);
        check_reg(13, 32'hFFFFFFFF);
        check_reg(14, 0);
        check_reg(15, 15);
        check_reg(16, 15);
        check_reg(17, 1);
        check_reg(18, 1);
        check_reg(19, 20);
        check_reg(20, 3);
        check_reg(21, 32'hFFFFFFFC);
        check_reg(0, 0);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 16 ALU INSTRUCTION TESTS PASSED");
        else
            $fatal(1, "DAY 16 TEST FAILED");

        $finish;
    end

endmodule
