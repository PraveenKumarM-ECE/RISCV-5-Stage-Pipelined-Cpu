`timescale 1ns/1ps

module tb_memory_timing;

    logic clk = 0;
    logic read_enable = 0;
    logic [3:0] write_enable = 0;
    logic [7:0] address = 0;
    logic [31:0] write_data = 0;
    logic [31:0] read_data;

    integer passed = 0;
    integer failed = 0;

    data_memory_bram dut (
        .clk(clk),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    task automatic check(
        input string name,
        input logic [31:0] expected
    );
    begin
        if (read_data === expected) begin
            passed = passed + 1;
            $display("PASS %s", name);
        end else begin
            failed = failed + 1;
            $display(
                "FAIL %s got=%h expected=%h",
                name, read_data, expected
            );
        end
    end
    endtask

    task automatic write(
        input logic [7:0] addr,
        input logic [31:0] data
    );
    begin
        @(negedge clk);
        address = addr;
        write_data = data;
        write_enable = 4'b1111;
        read_enable = 0;

        @(posedge clk);
        #1;

        @(negedge clk);
        write_enable = 0;
    end
    endtask

    initial begin

        write(8'd1, 32'h11111111);
        write(8'd2, 32'h22222222);

        // Read address 1 at a rising edge.
        @(negedge clk);
        address = 8'd1;
        read_enable = 1;

        @(posedge clk);
        #1;
        check("Read address 1", 32'h11111111);

        // Change address between clock edges.
        @(negedge clk);
        address = 8'd2;
        #1;

        // Output should still contain address 1 data.
        check("No asynchronous update", 32'h11111111);

        // Next rising edge updates output.
        @(posedge clk);
        #1;
        check("Read address 2", 32'h22222222);

        // Disable reading.
        @(negedge clk);
        read_enable = 0;
        address = 8'd1;

        @(posedge clk);
        #1;
        check("Read enable holds output", 32'h22222222);

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("DAY 37 MEMORY TIMING TEST PASSED");
        else
            $fatal(1, "DAY 37 MEMORY TIMING TEST FAILED");

        $finish;

    end

endmodule
