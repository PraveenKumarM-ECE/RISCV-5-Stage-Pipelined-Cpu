module tb_alu;

    logic [31:0] a, b;
    logic [3:0] op;
    logic [31:0] y;
    logic zero;

    integer tests = 0;
    integer errors = 0;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .zero(zero)
    );

    task check;
        input [31:0] x, z, expected;
        input [3:0] operation;
        begin
            a = x;
            b = z;
            op = operation;
            #10;

            tests = tests + 1;

            if (y !== expected ||
                zero !== (expected == 32'd0)) begin
                $display("FAIL: op=%b a=%h b=%h y=%h expected=%h",
                         op, a, b, y, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: op=%b a=%h b=%h y=%h",
                         op, a, b, y);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/alu.vcd");
        $dumpvars(0, tb_alu);

        // Basic operations
        check(10, 5, 15, 4'b0000);
        check(10, 5, 5,  4'b0001);
        check(10, 5, 0,  4'b0010);
        check(10, 5, 15, 4'b0011);
        check(10, 5, 15, 4'b0100);
        check(5, 10, 1,  4'b0101);
        check(5, 10, 1,  4'b0110);
        check(5, 2, 20,  4'b0111);
        check(20, 2, 5,  4'b1000);
        check(20, 2, 5,  4'b1001);

        // Edge cases
        check(32'hFFFFFFFF, 1, 0, 4'b0000);
        check(0, 1, 32'hFFFFFFFF, 4'b0001);
        check(32'hFFFFFFFF, 1, 1, 4'b0101);
        check(32'hFFFFFFFF, 1, 0, 4'b0110);
        check(32'hFFFFFFF8, 2, 32'hFFFFFFFE, 4'b1001);
        check(32'hFFFFFFF8, 2, 32'h3FFFFFFE, 4'b1000);
        check(1, 31, 32'h80000000, 4'b0111);
        check(1, 32, 1, 4'b0111);
        check(5, 5, 0, 4'b0001);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $fatal(1, "ALU VERIFICATION FAILED");

        $finish;
    end

endmodule