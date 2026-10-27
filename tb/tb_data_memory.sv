`timescale 1ns/1ps

module tb_data_memory;

    logic clk;
    logic mem_write;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [31:0] read_data;

    integer tests = 0;
    integer errors = 0;

    data_memory dut (
        .clk(clk),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] addr;
        input [31:0] expected;
        begin
            address = addr;
            #2;
            tests = tests + 1;

            if (read_data !== expected) begin
                $display("FAIL: Test=%0d Addr=%0d Got=%h Expected=%h",
                         tests, addr, read_data, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Test=%0d Addr=%0d Data=%h",
                         tests, addr, read_data);
            end
        end
    endtask

    task write_word;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            address = addr;
            write_data = data;
            mem_write = 1;
            @(posedge clk);
            #1;
            mem_write = 0;
        end
    endtask

    initial begin
        mem_write = 0;
        address = 0;
        write_data = 0;

        $dumpfile("sim/data_memory.vcd");
        $dumpvars(0, tb_data_memory);

        // Test 1: Memory initialized to zero
        check(0, 0);

        // Test 2: Write and read address 0
        write_word(0, 32'd100);
        check(0, 100);

        // Test 3: Write and read address 4
        write_word(4, 32'd200);
        check(4, 200);

        // Test 4: Write and read address 8
        write_word(8, 32'hDEADBEEF);
        check(8, 32'hDEADBEEF);

        // Test 5: Earlier address retains data
        check(0, 100);

        // Test 6: Another address retains data
        check(4, 200);

        // Test 7: Disabled write should not change memory
        @(negedge clk);
        address = 0;
        write_data = 999;
        mem_write = 0;
        @(posedge clk);
        #1;
        check(0, 100);

        // Test 8: Highest valid word address
        write_word(1020, 32'd500);
        check(1020, 500);

        // Test 9: Another unwritten address
        check(16, 0);

        // Test 10: Overwrite existing location
        write_word(4, 32'd777);
        check(4, 777);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DATA MEMORY TESTS PASSED");
        else
            $fatal(1, "DATA MEMORY TEST FAILED");

        $finish;
    end

endmodule