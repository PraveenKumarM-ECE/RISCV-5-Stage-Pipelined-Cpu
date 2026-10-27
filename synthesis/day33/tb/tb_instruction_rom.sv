`timescale 1ns/1ps

module tb_instruction_rom;

    logic [31:0] address;
    logic [31:0] instruction;

    integer passed;
    integer failed;

    instruction_rom dut (
        .address(address),
        .instruction(instruction)
    );

    task automatic check(
        input logic [31:0] addr,
        input logic [31:0] expected
    );
        begin
            address = addr;
            #1;

            if (instruction === expected) begin
                passed = passed + 1;
                $display(
                    "PASS address=%h instruction=%h",
                    address, instruction
                );
            end
            else begin
                failed = failed + 1;
                $display(
                    "FAIL address=%h got=%h expected=%h",
                    address, instruction, expected
                );
            end
        end
    endtask

    initial begin
        passed = 0;
        failed = 0;

        check(32'h00000000, 32'h00500093);
        check(32'h00000004, 32'h00A00113);
        check(32'h00000008, 32'h002081B3);
        check(32'h0000000C, 32'h00302023);
        check(32'h00000010, 32'h00002203);

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("DAY 33 ROM TEST PASSED");
        else
            $fatal(1, "DAY 33 ROM TEST FAILED");

        $finish;
    end

endmodule
