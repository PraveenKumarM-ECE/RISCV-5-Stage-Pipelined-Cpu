module tb_alu_random;

    logic [31:0] a, b;
    logic [3:0] op;
    logic [31:0] y;
    logic zero;

    logic [31:0] expected;
    integer i;
    integer errors = 0;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .zero(zero)
    );

    // Reference model
    function automatic [31:0] calculate;
        input [31:0] x, z;
        input [3:0] operation;

        begin
            case (operation)
                0: calculate = x + z;
                1: calculate = x - z;
                2: calculate = x & z;
                3: calculate = x | z;
                4: calculate = x ^ z;
                5: calculate = ($signed(x) < $signed(z));
                6: calculate = (x < z);
                7: calculate = x << z[4:0];
                8: calculate = x >> z[4:0];
                9: calculate = $signed(x) >>> z[4:0];
                default: calculate = 0;
            endcase
        end
    endfunction

    initial begin
        $dumpfile("sim/alu_random.vcd");
        $dumpvars(0, tb_alu_random);

        for (i = 0; i < 1000; i = i + 1) begin

            a = $random;
            b = $random;
            op = i % 10;

            expected = calculate(a, b, op);

            #10;

            if (y !== expected ||
                zero !== (expected == 0)) begin

                $display("FAIL: Test=%0d OP=%0d A=%h B=%h Expected=%h Actual=%h",
                         i, op, a, b, expected, y);

                errors = errors + 1;
            end
        end

        $display("-------------------------");
        $display("Total Tests = 1000");
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL RANDOM TESTS PASSED");
        else
            $fatal(1, "RANDOM VERIFICATION FAILED");

        $finish;
    end

endmodule