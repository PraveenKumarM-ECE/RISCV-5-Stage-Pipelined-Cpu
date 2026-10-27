`timescale 1ns/1ps

module tb_decoder_extended;

    logic [31:0] instruction;
    logic [6:0] opcode, funct7;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
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
        input [4:0] exp_rs2;
        input [2:0] exp_funct3;
        input [31:0] exp_imm;

        begin
            instruction = instr;
            #10;
            tests = tests + 1;

            if (opcode !== exp_opcode ||
                rd !== exp_rd ||
                rs1 !== exp_rs1 ||
                rs2 !== exp_rs2 ||
                funct3 !== exp_funct3 ||
                immediate !== exp_imm) begin

                $display("FAIL: Test=%0d Instr=%h", tests, instr);
                $display("  Opcode=%h RD=%0d RS1=%0d RS2=%0d F3=%h IMM=%h",
                         opcode, rd, rs1, rs2, funct3, immediate);
                $display("  Expected: Opcode=%h RD=%0d RS1=%0d RS2=%0d F3=%h IMM=%h",
                         exp_opcode, exp_rd, exp_rs1, exp_rs2,
                         exp_funct3, exp_imm);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Test=%0d Instr=%h IMM=%h",
                         tests, instr, immediate);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/decoder_extended.vcd");
        $dumpvars(0, tb_decoder_extended);

        // I-type: ADDI x5, x0, -1
        check(32'hFFF00293, 7'h13, 5, 0, 31, 0, 32'hFFFFFFFF);

        // I-type: ADDI x1, x2, 100
        check(32'h06410093, 7'h13, 1, 2, 4, 0, 100);

        // I-type: LW x6, 8(x1)
        check(32'h0080A303, 7'h03, 6, 1, 8, 2, 8);

        // I-type: JALR x0, 0(x1)
        check(32'h00008067, 7'h67, 0, 1, 0, 0, 0);

        // S-type: SW x2, 12(x1)
        check(32'h0020A623, 7'h23, 12, 1, 2, 2, 12);

        // S-type: SW x5, -4(x2)
        check(32'hFE512E23, 7'h23, 28, 2, 5, 2, 32'hFFFFFFFC);

        // B-type: BEQ x1, x2, +8
        check(32'h00208463, 7'h63, 8, 1, 2, 0, 8);

        // B-type: BNE x1, x2, -4
        check(32'hFE209EE3, 7'h63, 29, 1, 2, 1, 32'hFFFFFFFC);

        // U-type: LUI x3, 0x12345
        check(32'h123451B7, 7'h37, 3, 8, 3, 5, 32'h12345000);

        // U-type: AUIPC x4, 0x00010
        check(32'h00010217, 7'h17, 4, 2, 0, 0, 32'h00010000);

        // J-type: JAL x1, +8
        check(32'h008000EF, 7'h6F, 1, 0, 8, 0, 8);

        // J-type: JAL x1, -4
        check(32'hFFDFF0EF, 7'h6F, 1, 31, 29, 7, 32'hFFFFFFFC);

        // R-type: ADD x3, x1, x2
        check(32'h002081B3, 7'h33, 3, 1, 2, 0, 0);

        // R-type: SUB x4, x2, x1
        check(32'h40110233, 7'h33, 4, 2, 1, 0, 0);

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL EXTENDED DECODER TESTS PASSED");
        else
            $fatal(1, "EXTENDED DECODER TEST FAILED");

        $finish;
    end

endmodule