`timescale 1ns/1ps

module tb_data_memory_bram;

    logic clk = 0;
    logic read_enable;
    logic [3:0] write_enable;
    logic [7:0] address;
    logic [31:0] write_data;
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

    task automatic write_word(
        input logic [7:0] addr,
        input logic [31:0] data,
        input logic [3:0] mask
    );
    begin
        @(negedge clk);
        address = addr;
        write_data = data;
        write_enable = mask;
        read_enable = 0;

        @(posedge clk);
        #1;

        @(negedge clk);
        write_enable = 0;
    end
    endtask

    task automatic check(
        input string name,
        input logic [31:0] expected
    );
    begin
        @(negedge clk);
        read_enable = 1;

        @(posedge clk);
        #1;

        if (read_data === expected) begin
            passed = passed + 1;
            $display("PASS %s", name);
        end
        else begin
            failed = failed + 1;
            $display(
                "FAIL %s got=%h expected=%h",
                name, read_data, expected
            );
        end

        @(negedge clk);
        read_enable = 0;
    end
    endtask

    initial begin

        read_enable = 0;
        write_enable = 0;
        address = 0;
        write_data = 0;

        write_word(8'd5, 32'h12345678, 4'b1111);
        address = 8'd5;
        check("Full word write/read", 32'h12345678);

        write_word(8'd5, 32'h000000AA, 4'b0001);
        address = 8'd5;
        check("Byte 0 update", 32'h123456AA);

        write_word(8'd5, 32'h0000BB00, 4'b0010);
        address = 8'd5;
        check("Byte 1 update", 32'h1234BBAA);

        write_word(8'd5, 32'h00CC0000, 4'b0100);
        address = 8'd5;
        check("Byte 2 update", 32'h12CCBBAA);

        write_word(8'd5, 32'hDD000000, 4'b1000);
        address = 8'd5;
        check("Byte 3 update", 32'hDDCCBBAA);

        write_word(8'd10, 32'hCAFEBABE, 4'b1111);
        address = 8'd10;
        check("Different address", 32'hCAFEBABE);

        @(negedge clk);
        read_enable = 0;
        address = 8'd5;

        @(posedge clk);
        #1;

        if (read_data === 32'hCAFEBABE) begin
            passed = passed + 1;
            $display("PASS Read enable hold");
        end
        else begin
            failed = failed + 1;
            $display("FAIL Read enable hold");
        end

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("DAY 36 MEMORY TEST PASSED");
        else
            $fatal(1, "DAY 36 MEMORY TEST FAILED");

        $finish;

    end

endmodule
