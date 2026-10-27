`timescale 1ns/1ps

module tb_ex_stage;

    logic clk, reset, stall, flush;

    logic [31:0] pc, pc_plus4;
    logic [31:0] read_data1, read_data2, immediate;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [3:0] alu_op;
    logic alu_src, branch, jump;

    logic [31:0] alu_result, store_data, pc_target;
    logic pc_src;

    logic [31:0] mem_alu_result, mem_store_data, mem_pc_plus4;
    logic [4:0] mem_rd;
    logic [2:0] mem_funct3;
    logic mem_reg_write, mem_mem_write;
    logic [1:0] mem_result_src;

    logic [4:0] rd_in;
    logic reg_write_in, mem_write_in;
    logic [1:0] result_src_in;

    integer tests = 0;
    integer errors = 0;

    ex_stage dut_ex (
        .pc(pc),
        .pc_plus4(pc_plus4),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .immediate(immediate),
        .opcode(opcode),
        .funct3(funct3),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_result(alu_result),
        .store_data(store_data),
        .pc_target(pc_target),
        .pc_src(pc_src)
    );

    ex_mem_reg dut_exmem (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .alu_result_in(alu_result),
        .store_data_in(store_data),
        .pc_plus4_in(pc_plus4),
        .rd_in(rd_in),
        .funct3_in(funct3),
        .reg_write_in(reg_write_in),
        .mem_write_in(mem_write_in),
        .result_src_in(result_src_in),
        .alu_result_out(mem_alu_result),
        .store_data_out(mem_store_data),
        .pc_plus4_out(mem_pc_plus4),
        .rd_out(mem_rd),
        .funct3_out(mem_funct3),
        .reg_write_out(mem_reg_write),
        .mem_write_out(mem_mem_write),
        .result_src_out(mem_result_src)
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

    initial begin
        $dumpfile("sim/pipeline/day21_ex.vcd");
        $dumpvars(0, tb_ex_stage);

        reset = 1;
        stall = 0;
        flush = 0;

        pc = 0;
        pc_plus4 = 4;
        read_data1 = 0;
        read_data2 = 0;
        immediate = 0;
        opcode = 7'b0110011;
        funct3 = 0;
        alu_op = 0;
        alu_src = 0;
        branch = 0;
        jump = 0;

        rd_in = 0;
        reg_write_in = 0;
        mem_write_in = 0;
        result_src_in = 0;

        #12;
        check(mem_reg_write, 0, "Reset RegWrite");
        check(mem_mem_write, 0, "Reset MemWrite");

        @(negedge clk);
        reset = 0;

        // ADD
        read_data1 = 10;
        read_data2 = 20;
        alu_op = 0;
        #1;
        check(alu_result, 30, "ADD result");

        // SUB
        alu_op = 1;
        #1;
        check(alu_result, 32'hFFFFFFF6, "SUB result");

        // Memory address calculation
        opcode = 7'b0100011;
        read_data1 = 100;
        read_data2 = 55;
        immediate = 8;
        alu_src = 1;
        alu_op = 0;
        #1;
        check(alu_result, 108, "Store address");
        check(store_data, 55, "Store data");

        // LUI
        opcode = 7'b0110111;
        immediate = 32'h12345000;
        #1;
        check(alu_result, 32'h12345000, "LUI result");

        // AUIPC
        opcode = 7'b0010111;
        pc = 32;
        immediate = 32'h1000;
        #1;
        check(alu_result, 32'h1020, "AUIPC result");

        // BEQ taken
        opcode = 7'b1100011;
        pc = 40;
        read_data1 = 10;
        read_data2 = 10;
        immediate = 16;
        branch = 1;
        jump = 0;
        funct3 = 3'b000;
        #1;
        check(pc_src, 1, "BEQ taken");
        check(pc_target, 56, "BEQ target");

        // BNE not taken
        funct3 = 3'b001;
        #1;
        check(pc_src, 0, "BNE not taken");

        // BLT signed comparison
        read_data1 = 32'hFFFFFFFF;
        read_data2 = 1;
        funct3 = 3'b100;
        #1;
        check(pc_src, 1, "BLT signed taken");

        // BLTU unsigned comparison
        funct3 = 3'b110;
        #1;
        check(pc_src, 0, "BLTU unsigned not taken");

        // JAL
        opcode = 7'b1101111;
        pc = 100;
        immediate = 20;
        branch = 0;
        jump = 1;
        #1;
        check(pc_src, 1, "JAL redirect");
        check(pc_target, 120, "JAL target");

        // JALR
        opcode = 7'b1100111;
        read_data1 = 101;
        immediate = 4;
        alu_src = 1;
        alu_op = 0;
        #1;
        check(pc_target, 104, "JALR target bit 0 cleared");

        // EX/MEM capture test
        opcode = 7'b0100011;
        read_data1 = 100;
        read_data2 = 55;
        immediate = 8;
        alu_src = 1;
        branch = 0;
        jump = 0;
        funct3 = 3'b010;

        pc_plus4 = 44;
        rd_in = 5;
        reg_write_in = 1;
        mem_write_in = 1;
        result_src_in = 2'b01;

        @(posedge clk);
        #1;

        check(mem_alu_result, 108, "EX/MEM ALU result");
        check(mem_store_data, 55, "EX/MEM store data");
        check(mem_pc_plus4, 44, "EX/MEM PC+4");
        check(mem_rd, 5, "EX/MEM RD");
        check(mem_funct3, 2, "EX/MEM funct3");
        check(mem_reg_write, 1, "EX/MEM RegWrite");
        check(mem_mem_write, 1, "EX/MEM MemWrite");
        check(mem_result_src, 1, "EX/MEM ResultSrc");

        // Stall test
        @(negedge clk);
        stall = 1;
        read_data1 = 200;
        read_data2 = 99;
        rd_in = 8;

        @(posedge clk);
        #1;

        check(mem_alu_result, 108, "Stall holds ALU result");
        check(mem_rd, 5, "Stall holds RD");

        // Flush test
        @(negedge clk);
        flush = 1;

        @(posedge clk);
        #1;

        check(mem_reg_write, 0, "Flush clears RegWrite");
        check(mem_mem_write, 0, "Flush clears MemWrite");
        check(mem_rd, 0, "Flush clears RD");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 21 EX STAGE TESTS PASSED");
        else
            $fatal(1, "DAY 21 EX STAGE TEST FAILED");

        $finish;
    end

endmodule
