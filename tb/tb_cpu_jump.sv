`timescale 1ns/1ps

module tb_cpu_jump;

    logic clk, reset;
    logic [31:0] pc, instruction;

    integer tests = 0;
    integer errors = 0;
    integer i;

    logic [31:0] expected_pc [0:7];

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
                $display("FAIL: x%0d Got=%0d Expected=%0d",
                    reg_num, dut.regfile.regs[reg_num], expected);
                errors = errors + 1;
            end
            else
                $display("PASS: x%0d = %0d",
                    reg_num, expected);
        end
    endtask

    initial begin
        $dumpfile("sim/cpu_jump.vcd");
        $dumpvars(0, tb_cpu_jump);

        // PC after each executed instruction
        expected_pc[0] = 4;
        expected_pc[1] = 16;
        expected_pc[2] = 20;
        expected_pc[3] = 28;
        expected_pc[4] = 32;
        expected_pc[5] = 36;
        expected_pc[6] = 44;
        expected_pc[7] = 48;

        reset = 1;
        #12;
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 8; i = i + 1) begin
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

        // Verify register values and link addresses
        check_register(1, 16);
        check_register(2, 7);
        check_register(3, 11);
        check_register(4, 18);
        check_register(5, 8);
        check_register(6, 24);
        check_register(7, 22);
        check_register(0, 0);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL CPU JUMP TESTS PASSED");
        else
            $fatal(1, "CPU JUMP TEST FAILED");

        $finish;
    end

endmodule
