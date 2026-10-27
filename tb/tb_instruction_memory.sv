`timescale 1ns/1ps

module tb_instruction_memory;

    logic [31:0] address;
    logic [31:0] instruction;

    integer tests = 0;
    integer errors = 0;

    instruction_memory dut (
        .address(address),
        .instruction(instruction)
    );

    task check;
        input [31:0] addr;
        input [31:0] expected;
        begin
            address = addr;
            #10;
            tests = tests + 1;

            if (instruction !== expected) begin
                $display("FAIL: Addr=%h Instr=%h Expected=%h",
                         address, instruction, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Addr=%h Instr=%h",
                         address, instruction);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/instruction_memory.vcd");
        $dumpvars(0, tb_instruction_memory);

        check(32'h00000000, 32'h00a00093);
        check(32'h00000004, 32'h01400113);
        check(32'h00000008, 32'h002081b3);
        check(32'h0000000C, 32'h40110233);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL INSTRUCTION MEMORY TESTS PASSED");
        else
            $fatal(1, "INSTRUCTION MEMORY TEST FAILED");

        $finish;
    end

endmodule