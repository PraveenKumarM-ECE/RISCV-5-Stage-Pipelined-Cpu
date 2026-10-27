`timescale 1ns/1ps

module tb_cpu_day15;

    logic clk, reset;
    logic [31:0] pc, instruction;

    integer tests = 0;
    integer errors = 0;
    integer i;

    logic [31:0] expected_pc [0:13];

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
            else
                $display("PASS: x%0d = %h",
                         r, expected);
        end
    endtask

    initial begin
        $dumpfile("sim/cpu_day15.vcd");
        $dumpvars(0, tb_cpu_day15);

        expected_pc[0]  = 4;
        expected_pc[1]  = 8;
        expected_pc[2]  = 12;
        expected_pc[3]  = 16;
        expected_pc[4]  = 24;
        expected_pc[5]  = 32;
        expected_pc[6]  = 36;
        expected_pc[7]  = 40;
        expected_pc[8]  = 48;
        expected_pc[9]  = 52;
        expected_pc[10] = 56;
        expected_pc[11] = 60;
        expected_pc[12] = 64;
        expected_pc[13] = 68;

        reset = 1;
        #12;
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 14; i = i + 1) begin
            @(posedge clk);
            #1;
            tests = tests + 1;

            if (pc !== expected_pc[i]) begin
                $display("FAIL: Step=%0d PC=%0d Expected=%0d",
                         i+1, pc, expected_pc[i]);
                errors = errors + 1;
            end
            else
                $display("PASS: Step=%0d PC=%0d",
                         i+1, pc);
        end

        check_reg(1, 32'hFFFFFFFF);
        check_reg(2, 1);
        check_reg(5, 32'h12345000);
        check_reg(6, 32'h0000100C);
        check_reg(7, 0);
        check_reg(8, 0);
        check_reg(9, 9);
        check_reg(10, 0);
        check_reg(11, 11);
        check_reg(12, 12);
        check_reg(13, 23);
        check_reg(0, 0);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 15 CPU TESTS PASSED");
        else
            $fatal(1, "DAY 15 CPU TEST FAILED");

        $finish;
    end

endmodule
