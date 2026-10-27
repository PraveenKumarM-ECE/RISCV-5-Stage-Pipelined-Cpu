`timescale 1ns/1ps

module tb_control_unit;

    logic [6:0] opcode, funct7;
    logic [2:0] funct3;

    logic reg_write, alu_src, mem_write;
    logic [1:0] result_src;
    logic branch, jump;
    logic [3:0] alu_op;

    integer tests = 0;
    integer errors = 0;

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .result_src(result_src),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );

    task check;
        input [6:0] opc, f7;
        input [2:0] f3;
        input exp_reg, exp_src, exp_mem;
        input [1:0] exp_result;
        input exp_branch, exp_jump;
        input [3:0] exp_alu;

        begin
            opcode = opc;
            funct3 = f3;
            funct7 = f7;
            #10;
            tests = tests + 1;

            if (reg_write !== exp_reg ||
                alu_src !== exp_src ||
                mem_write !== exp_mem ||
                result_src !== exp_result ||
                branch !== exp_branch ||
                jump !== exp_jump ||
                alu_op !== exp_alu) begin
                $display("FAIL: Test=%0d Opcode=%b", tests, opcode);
                errors = errors + 1;
            end
            else
                $display("PASS: Test=%0d Opcode=%b", tests, opcode);
        end
    endtask

    initial begin
        $dumpfile("sim/control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        // ADD
        check(7'b0110011, 7'b0000000, 3'b000,
              1, 0, 0, 0, 0, 0, 4'b0000);

        // SUB
        check(7'b0110011, 7'b0100000, 3'b000,
              1, 0, 0, 0, 0, 0, 4'b0001);

        // AND
        check(7'b0110011, 7'b0000000, 3'b111,
              1, 0, 0, 0, 0, 0, 4'b0010);

        // ADDI
        check(7'b0010011, 7'b0000000, 3'b000,
              1, 1, 0, 0, 0, 0, 4'b0000);

        // LW
        check(7'b0000011, 7'b0000000, 3'b010,
              1, 1, 0, 1, 0, 0, 4'b0000);

        // SW
        check(7'b0100011, 7'b0000000, 3'b010,
              0, 1, 1, 0, 0, 0, 4'b0000);

        // BEQ
        check(7'b1100011, 7'b0000000, 3'b000,
              0, 0, 0, 0, 1, 0, 4'b0001);

        // JAL
        check(7'b1101111, 7'b0000000, 3'b000,
              1, 0, 0, 2, 0, 1, 4'b0000);

        // JALR
        check(7'b1100111, 7'b0000000, 3'b000,
              1, 0, 0, 2, 0, 1, 4'b0000);

        // LUI
        check(7'b0110111, 7'b0000000, 3'b000,
              1, 1, 0, 0, 0, 0, 4'b0000);

        // AUIPC
        check(7'b0010111, 7'b0000000, 3'b000,
              1, 1, 0, 0, 0, 0, 4'b0000);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL CONTROL UNIT TESTS PASSED");
        else
            $fatal(1, "CONTROL UNIT TEST FAILED");

        $finish;
    end

endmodule