`timescale 1ns/1ps

module tb_decoder;

    logic [31:0] instruction;
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] immediate;

    integer tests = 0;
    integer errors = 0;

    instruction_decoder dut1 (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    immediate_generator dut2 (
        .instruction(instruction),
        .immediate(immediate)
    );

    task check;
        input [31:0] instr;
        input [6:0] exp_opcode;
        input [4:0] exp_rd;
        input [4:0] exp_rs1;
        input [31:0] exp_imm;

        begin
            instruction = instr;
            #10;
            tests = tests + 1;

            if (opcode !== exp_opcode ||
                rd !== exp_rd ||
                rs1 !== exp_rs1 ||
                immediate !== exp_imm) begin

                $display("FAIL: instr=%h opcode=%b rd=%0d rs1=%0d imm=%h",
                         instruction, opcode, rd, rs1, immediate);
                errors = errors + 1;
            end
            else begin
                $display("PASS: instr=%h imm=%h",
                         instruction, immediate);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/decoder.vcd");
        $dumpvars(0, tb_decoder);

        // ADDI x1, x0, 10
        check(32'h00A00093, 7'b0010011, 1, 0, 10);

        // ADDI x2, x0, 20
        check(32'h01400113, 7'b0010011, 2, 0, 20);

        // ADD x3, x1, x2
        check(32'h002081B3, 7'b0110011, 3, 1, 0);

        // SUB x4, x2, x1
        check(32'h40110233, 7'b0110011, 4, 2, 0);

        // ADDI x5, x0, -1
        check(32'hFFF00293, 7'b0010011, 5, 0, 32'hFFFFFFFF);

        // LUI x6, 0x12345
        check(32'h12345337, 7'b0110111, 6, 8, 32'h12345000);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DECODER TESTS PASSED");
        else
            $fatal(1, "DECODER TEST FAILED");

        $finish;
    end

endmodule