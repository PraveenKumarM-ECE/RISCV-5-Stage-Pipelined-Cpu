module tb_register_file;

    logic clk = 0;
    logic reg_write;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] write_data;
    logic [31:0] read_data1, read_data2;

    integer tests = 0;
    integer errors = 0;

    register_file dut (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock period = 10 time units
    always #5 clk = ~clk;

    task write_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            rd = addr;
            write_data = data;
            reg_write = 1;

            @(posedge clk);
            #1;
            reg_write = 0;
        end
    endtask

    task check;
        input [4:0] addr1, addr2;
        input [31:0] expected1, expected2;
        begin
            rs1 = addr1;
            rs2 = addr2;
            #1;

            tests = tests + 1;

            if (read_data1 !== expected1 ||
                read_data2 !== expected2) begin

                $display("FAIL: rs1=%0d rs2=%0d data1=%h data2=%h",
                         rs1, rs2, read_data1, read_data2);

                errors = errors + 1;
            end
            else begin
                $display("PASS: rs1=%0d rs2=%0d data1=%h data2=%h",
                         rs1, rs2, read_data1, read_data2);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/register_file.vcd");
        $dumpvars(0, tb_register_file);

        reg_write = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        write_data = 0;

        // Test 1: x0 must always be zero
        check(0, 0, 0, 0);

        // Test 2: Write and read x1
        write_reg(1, 100);
        check(1, 0, 100, 0);

        // Test 3: Write and read x2
        write_reg(2, 200);
        check(1, 2, 100, 200);

        // Test 4: Attempt to write x0
        write_reg(0, 999);
        check(0, 1, 0, 100);

        // Test 5: Overwrite x1
        write_reg(1, 500);
        check(1, 2, 500, 200);

        // Test 6: Read the same register twice
        check(1, 1, 500, 500);

        // Test 7: Read an unwritten register
        check(3, 4, 0, 0);

        // Test 8: Write disabled
        @(negedge clk);
        rd = 5'd5;
        write_data = 32'd999;
        reg_write = 0;

        @(posedge clk);
        #1;
        check(5, 0, 0, 0);

        // Test 9: Write to the last register
        write_reg(31, 32'hDEADBEEF);
        check(31, 0, 32'hDEADBEEF, 0);

        // Test 10: Read two different registers
        check(1, 31, 500, 32'hDEADBEEF);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL REGISTER FILE TESTS PASSED");
        else
            $fatal(1, "REGISTER FILE TEST FAILED");

        $finish;
    end

endmodule