`timescale 1ns/1ps

module tb_id_stage;

    logic clk, reset, stall, flush;
    logic [31:0] instruction;
    logic wb_reg_write;
    logic [4:0] wb_rd;
    logic [31:0] wb_data;

    logic [31:0] read_data1, read_data2, immediate;
    logic [4:0] rs1, rs2, rd;
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic reg_write, alu_src, mem_write, branch, jump;
    logic [1:0] result_src;
    logic [3:0] alu_op;

    logic [31:0] ex_pc, ex_pc_plus4;
    logic [31:0] ex_data1, ex_data2, ex_imm;
    logic [4:0] ex_rs1, ex_rs2, ex_rd;
    logic [6:0] ex_opcode;
    logic [2:0] ex_funct3;
    logic ex_reg_write, ex_alu_src, ex_mem_write;
    logic [1:0] ex_result_src;
    logic ex_branch, ex_jump;
    logic [3:0] ex_alu_op;

    logic [31:0] pc_in, pc_plus4_in;

    integer tests = 0;
    integer errors = 0;

    id_stage dut_id (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .immediate(immediate),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
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

    id_ex_reg dut_idex (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_in(pc_in),
        .pc_plus4_in(pc_plus4_in),
        .read_data1_in(read_data1),
        .read_data2_in(read_data2),
        .immediate_in(immediate),
        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),
        .opcode_in(opcode),
        .funct3_in(funct3),
        .reg_write_in(reg_write),
        .alu_src_in(alu_src),
        .mem_write_in(mem_write),
        .result_src_in(result_src),
        .branch_in(branch),
        .jump_in(jump),
        .alu_op_in(alu_op),
        .pc_out(ex_pc),
        .pc_plus4_out(ex_pc_plus4),
        .read_data1_out(ex_data1),
        .read_data2_out(ex_data2),
        .immediate_out(ex_imm),
        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rd_out(ex_rd),
        .opcode_out(ex_opcode),
        .funct3_out(ex_funct3),
        .reg_write_out(ex_reg_write),
        .alu_src_out(ex_alu_src),
        .mem_write_out(ex_mem_write),
        .result_src_out(ex_result_src),
        .branch_out(ex_branch),
        .jump_out(ex_jump),
        .alu_op_out(ex_alu_op)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*40-1:0] name;
        begin
            tests = tests + 1;
            if (actual !== expected) begin
                $display("FAIL: %0s Got=%h Expected=%h",
                         name, actual, expected);
                errors = errors + 1;
            end
            else
                $display("PASS: %0s = %h", name, expected);
        end
    endtask

    task write_register;
        input [4:0] r;
        input [31:0] value;
        begin
            @(negedge clk);
            wb_reg_write = 1;
            wb_rd = r;
            wb_data = value;
            @(posedge clk);
            #1;
            @(negedge clk);
            wb_reg_write = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/pipeline/day20_id.vcd");
        $dumpvars(0, tb_id_stage);

        reset = 1;
        stall = 0;
        flush = 0;
        instruction = 32'h00000013;
        wb_reg_write = 0;
        wb_rd = 0;
        wb_data = 0;
        pc_in = 0;
        pc_plus4_in = 4;

        #12;
        check(ex_reg_write, 0, "Reset RegWrite");
        check(ex_rd, 0, "Reset RD");

        @(negedge clk);
        reset = 0;

        // Initialize register values through WB
        write_register(1, 10);
        write_register(2, 20);

        // Decode ADDI x1, x0, 10
        instruction = 32'h00a00093;
        pc_in = 0;
        pc_plus4_in = 4;
        #1;

        check(opcode, 7'b0010011, "ADDI opcode");
        check(rd, 1, "ADDI RD");
        check(rs1, 0, "ADDI RS1");
        check(immediate, 10, "ADDI immediate");
        check(reg_write, 1, "ADDI RegWrite");
        check(alu_src, 1, "ADDI ALUSrc");

        @(posedge clk);
        #1;

        check(ex_pc, 0, "ID/EX ADDI PC");
        check(ex_rd, 1, "ID/EX ADDI RD");
        check(ex_imm, 10, "ID/EX ADDI immediate");
        check(ex_reg_write, 1, "ID/EX ADDI RegWrite");

        // Decode ADD x3, x1, x2
        @(negedge clk);
        instruction = 32'h002081b3;
        pc_in = 8;
        pc_plus4_in = 12;
        #1;

        check(rs1, 1, "ADD RS1");
        check(rs2, 2, "ADD RS2");
        check(rd, 3, "ADD RD");
        check(read_data1, 10, "Register x1 data");
        check(read_data2, 20, "Register x2 data");
        check(alu_src, 0, "ADD ALUSrc");

        @(posedge clk);
        #1;

        check(ex_pc, 8, "ID/EX ADD PC");
        check(ex_pc_plus4, 12, "ID/EX ADD PC+4");
        check(ex_data1, 10, "ID/EX RS1 data");
        check(ex_data2, 20, "ID/EX RS2 data");
        check(ex_rd, 3, "ID/EX ADD RD");

        // Stall: keep previous ID/EX values
        @(negedge clk);
        stall = 1;
        instruction = 32'h00a00093;
        pc_in = 16;

        @(posedge clk);
        #1;

        check(ex_pc, 8, "Stall holds PC");
        check(ex_rd, 3, "Stall holds RD");

        // Flush must override stall
        @(negedge clk);
        flush = 1;

        @(posedge clk);
        #1;

        check(ex_reg_write, 0, "Flush clears RegWrite");
        check(ex_mem_write, 0, "Flush clears MemWrite");
        check(ex_rd, 0, "Flush clears RD");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 20 ID STAGE TESTS PASSED");
        else
            $fatal(1, "DAY 20 ID STAGE TEST FAILED");

        $finish;
    end

endmodule
