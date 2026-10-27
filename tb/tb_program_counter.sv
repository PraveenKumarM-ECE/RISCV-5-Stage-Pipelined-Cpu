`timescale 1ns/1ps

module tb_program_counter;

    logic clk = 0;
    logic reset;
    logic enable;
    logic pc_src;
    logic [31:0] pc_target;
    logic [31:0] pc;

    integer tests = 0;
    integer errors = 0;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .pc(pc)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] expected;
        begin
            tests = tests + 1;

            if (pc !== expected) begin
                $display("FAIL: PC=%h Expected=%h",
                         pc, expected);
                errors = errors + 1;
            end
            else
                $display("PASS: PC=%h", pc);
        end
    endtask

    initial begin
        $dumpfile("sim/program_counter.vcd");
        $dumpvars(0, tb_program_counter);

        reset = 0;
        enable = 1;
        pc_src = 0;
        pc_target = 0;

        // Test 1: Reset
        #1;
        reset = 1;
        #1;
        check(32'h00000000);

        // Test 2: PC = 4
        @(negedge clk);
        reset = 0;
        @(posedge clk);
        #1;
        check(32'h00000004);

        // Test 3: PC = 8
        @(posedge clk);
        #1;
        check(32'h00000008);

        // Test 4: PC = 12
        @(posedge clk);
        #1;
        check(32'h0000000C);

        // Test 5: Stall (PC must hold)
        @(negedge clk);
        enable = 0;
        @(posedge clk);
        #1;
        check(32'h0000000C);

        // Test 6: Resume
        @(negedge clk);
        enable = 1;
        @(posedge clk);
        #1;
        check(32'h00000010);

        // Test 7: Jump to address 0x100
        @(negedge clk);
        pc_src = 1;
        pc_target = 32'h00000100;
        @(posedge clk);
        #1;
        check(32'h00000100);

        // Test 8: Continue after jump
        @(negedge clk);
        pc_src = 0;
        @(posedge clk);
        #1;
        check(32'h00000104);

        // Test 9: Reset again
        @(negedge clk);
        reset = 1;
        #1;
        check(32'h00000000);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL PROGRAM COUNTER TESTS PASSED");
        else
            $fatal(1, "PROGRAM COUNTER TEST FAILED");

        $finish;
    end

endmodule