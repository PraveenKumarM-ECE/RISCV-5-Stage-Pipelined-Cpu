`timescale 1ns/1ps

module tb_mem_stage;

    logic clk, reset, stall, flush;
    logic mem_write;
    logic [2:0] funct3;
    logic [31:0] alu_result, store_data;
    logic [31:0] memory_data;

    logic [31:0] pc_plus4;
    logic [4:0] rd;
    logic reg_write;
    logic [1:0] result_src;

    logic [31:0] wb_alu_result;
    logic [31:0] wb_memory_data;
    logic [31:0] wb_pc_plus4;
    logic [4:0] wb_rd;
    logic wb_reg_write;
    logic [1:0] wb_result_src;

    integer tests = 0;
    integer errors = 0;

    mem_stage dut_mem (
        .clk(clk),
        .reset(reset),
        .mem_write(mem_write),
        .funct3(funct3),
        .alu_result(alu_result),
        .store_data(store_data),
        .memory_data(memory_data)
    );

    mem_wb_reg dut_memwb (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .alu_result_in(alu_result),
        .memory_data_in(memory_data),
        .pc_plus4_in(pc_plus4),
        .rd_in(rd),
        .reg_write_in(reg_write),
        .result_src_in(result_src),
        .alu_result_out(wb_alu_result),
        .memory_data_out(wb_memory_data),
        .pc_plus4_out(wb_pc_plus4),
        .rd_out(wb_rd),
        .reg_write_out(wb_reg_write),
        .result_src_out(wb_result_src)
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
        $dumpfile("sim/pipeline/day22_mem.vcd");
        $dumpvars(0, tb_mem_stage);

        reset = 1;
        stall = 0;
        flush = 0;
        mem_write = 0;
        funct3 = 3'b010;
        alu_result = 100;
        store_data = 0;
        pc_plus4 = 4;
        rd = 0;
        reg_write = 0;
        result_src = 0;

        #12;
        check(wb_reg_write, 0, "Reset RegWrite");
        check(wb_rd, 0, "Reset RD");
        check(wb_memory_data, 0, "Reset memory data");

        @(negedge clk);
        reset = 0;

        // TEST 1: SW stores a complete word
        mem_write = 1;
        funct3 = 3'b010;
        alu_result = 100;
        store_data = 32'h12345678;
        pc_plus4 = 8;
        rd = 0;
        reg_write = 0;
        result_src = 0;

        @(posedge clk);
        #1;
        check(dut_mem.dmem.memory[25],
              32'h12345678, "SW memory word");
        check(wb_alu_result, 100, "SW MEM/WB address");
        check(wb_pc_plus4, 8, "SW MEM/WB PC+4");

        // TEST 2: LW reads the stored word
        @(negedge clk);
        mem_write = 0;
        funct3 = 3'b010;
        alu_result = 100;
        pc_plus4 = 12;
        rd = 5;
        reg_write = 1;
        result_src = 2'b01;

        #1;
        check(memory_data, 32'h12345678, "LW read data");

        @(posedge clk);
        #1;
        check(wb_memory_data, 32'h12345678,
              "LW MEM/WB data");
        check(wb_rd, 5, "LW MEM/WB RD");
        check(wb_reg_write, 1, "LW MEM/WB RegWrite");
        check(wb_result_src, 1, "LW MEM/WB ResultSrc");

        // TEST 3: SB modifies only byte at address 103
        @(negedge clk);
        mem_write = 1;
        funct3 = 3'b000;
        alu_result = 103;
        store_data = 32'hFFFFFF80;
        reg_write = 0;

        @(posedge clk);
        #1;
        check(dut_mem.dmem.memory[25],
              32'h80345678, "SB preserves other bytes");

        // TEST 4: LB sign-extends 0x80
        @(negedge clk);
        mem_write = 0;
        funct3 = 3'b000;
        alu_result = 103;

        #1;
        check(memory_data, 32'hFFFFFF80,
              "LB sign extension");

        @(posedge clk);
        #1;
        check(wb_memory_data, 32'hFFFFFF80,
              "LB MEM/WB data");

        // TEST 5: LBU zero-extends 0x80
        @(negedge clk);
        funct3 = 3'b100;

        #1;
        check(memory_data, 32'h00000080,
              "LBU zero extension");

        // TEST 6: SH modifies only lower halfword
        @(negedge clk);
        mem_write = 1;
        funct3 = 3'b001;
        alu_result = 100;
        store_data = 32'h0000FFFF;

        @(posedge clk);
        #1;
        check(dut_mem.dmem.memory[25],
              32'h8034FFFF, "SH preserves upper half");

        // TEST 7: LH reads signed upper halfword
        @(negedge clk);
        mem_write = 0;
        funct3 = 3'b001;
        alu_result = 102;

        #1;
        check(memory_data, 32'hFFFF8034,
              "LH sign extension");

        // TEST 8: LHU reads unsigned upper halfword
        @(negedge clk);
        funct3 = 3'b101;

        #1;
        check(memory_data, 32'h00008034,
              "LHU zero extension");

        // TEST 9: MEM/WB stall
        @(negedge clk);
        stall = 1;
        alu_result = 200;
        rd = 9;
        reg_write = 1;
        pc_plus4 = 100;

        @(posedge clk);
        #1;
        check(wb_alu_result, 102,
              "Stall holds ALU result");
        check(wb_rd, 5,
              "Stall holds RD");

        // TEST 10: Flush overrides stall
        @(negedge clk);
        flush = 1;

        @(posedge clk);
        #1;
        check(wb_reg_write, 0,
              "Flush clears RegWrite");
        check(wb_rd, 0,
              "Flush clears RD");
        check(wb_alu_result, 0,
              "Flush clears ALU result");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 22 MEM STAGE TESTS PASSED");
        else
            $fatal(1, "DAY 22 MEM STAGE TEST FAILED");

        $finish;
    end

endmodule
