`timescale 1ns/1ps

module tb_wb_stage;

    logic clk, reset, stall, flush;

    logic [31:0] alu_result_in;
    logic [31:0] memory_data_in;
    logic [31:0] pc_plus4_in;

    logic [4:0] rd_in;
    logic reg_write_in;
    logic [1:0] result_src_in;

    logic [31:0] alu_result;
    logic [31:0] memory_data;
    logic [31:0] pc_plus4;

    logic [4:0] rd;
    logic reg_write;
    logic [1:0] result_src;

    logic [31:0] wb_data;
    logic [4:0] wb_rd;
    logic wb_reg_write;

    logic [4:0] rs1, rs2;
    logic [31:0] read_data1, read_data2;

    integer tests = 0;
    integer errors = 0;

    // Pipeline register from Day 22
    mem_wb_reg dut_memwb (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),

        .alu_result_in(alu_result_in),
        .memory_data_in(memory_data_in),
        .pc_plus4_in(pc_plus4_in),
        .rd_in(rd_in),
        .reg_write_in(reg_write_in),
        .result_src_in(result_src_in),

        .alu_result_out(alu_result),
        .memory_data_out(memory_data),
        .pc_plus4_out(pc_plus4),
        .rd_out(rd),
        .reg_write_out(reg_write),
        .result_src_out(result_src)
    );

    // New Writeback stage
    wb_stage dut_wb (
        .reset(reset),
        .alu_result(alu_result),
        .memory_data(memory_data),
        .pc_plus4(pc_plus4),
        .rd(rd),
        .reg_write(reg_write),
        .result_src(result_src),
        .wb_data(wb_data),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write)
    );

    // Existing register file
    register_file dut_regfile (
        .clk(clk),
        .reg_write(wb_reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(wb_rd),
        .write_data(wb_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
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

    // Present a result to MEM/WB on a falling edge.
    // It is captured on the next rising edge.
    task send_result;
        input [31:0] a;
        input [31:0] m;
        input [31:0] p;
        input [4:0]  r;
        input        w;
        input [1:0]  src;
        begin
            @(negedge clk);
            alu_result_in = a;
            memory_data_in = m;
            pc_plus4_in = p;
            rd_in = r;
            reg_write_in = w;
            result_src_in = src;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("sim/pipeline/day23_wb.vcd");
        $dumpvars(0, tb_wb_stage);

        reset = 1;
        stall = 0;
        flush = 0;

        alu_result_in = 0;
        memory_data_in = 0;
        pc_plus4_in = 0;

        rd_in = 0;
        reg_write_in = 0;
        result_src_in = 0;

        rs1 = 0;
        rs2 = 0;

        #12;

        check(wb_reg_write, 0, "Reset disables writeback");
        check(wb_rd, 0, "Reset RD");
        check(wb_data, 0, "Reset WB data");

        @(negedge clk);
        reset = 0;

        // TEST 1: ALU result -> x5
        send_result(30, 999, 4, 5, 1, 2'b00);

        check(wb_data, 30, "ALU result selected");
        check(wb_rd, 5, "ALU destination x5");
        check(wb_reg_write, 1, "ALU RegWrite enabled");

        // Register file writes at the NEXT rising edge
        @(posedge clk);
        #1;

        rs1 = 5;
        #1;
        check(read_data1, 30, "Register x5 written");

        // TEST 2: Memory result -> x6
        send_result(100, 55, 12, 6, 1, 2'b01);

        check(wb_data, 55, "Memory result selected");
        check(wb_rd, 6, "Memory destination x6");
        check(wb_reg_write, 1, "Memory RegWrite enabled");

        @(posedge clk);
        #1;

        rs1 = 6;
        #1;
        check(read_data1, 55, "Register x6 written");

        // TEST 3: PC+4 -> x7
        send_result(200, 300, 44, 7, 1, 2'b10);

        check(wb_data, 44, "PC+4 selected");
        check(wb_rd, 7, "Jump destination x7");
        check(wb_reg_write, 1, "Jump RegWrite enabled");

        @(posedge clk);
        #1;

        rs1 = 7;
        #1;
        check(read_data1, 44, "Register x7 written");

        // TEST 4: Store/branch must not write
        send_result(500, 600, 700, 8, 0, 2'b00);

        check(wb_reg_write, 0, "Store disables RegWrite");

        @(posedge clk);
        #1;

        rs1 = 8;
        #1;
        check(read_data1, 0, "Register x8 unchanged");

        // TEST 5: x0 cannot be written
        send_result(123, 0, 0, 0, 1, 2'b00);

        check(wb_reg_write, 0, "x0 write blocked");

        @(posedge clk);
        #1;

        rs1 = 0;
        #1;
        check(read_data1, 0, "Register x0 stays zero");

        // TEST 6: Flush clears pending write
        send_result(77, 0, 0, 9, 1, 2'b00);

        check(wb_reg_write, 1, "Pending x9 write");

        @(negedge clk);
        flush = 1;

        @(posedge clk);
        #1;

        check(wb_reg_write, 0, "Flush disables writeback");

        @(negedge clk);
        flush = 0;

        // TEST 7: Stall holds MEM/WB
        send_result(88, 0, 0, 10, 1, 2'b00);

        check(wb_data, 88, "Before stall WB data");

        @(negedge clk);
        stall = 1;
        alu_result_in = 999;
        rd_in = 11;

        @(posedge clk);
        #1;

        check(wb_data, 88, "Stall holds WB data");
        check(wb_rd, 10, "Stall holds destination");

        @(negedge clk);
        stall = 0;

        // TEST 8: Invalid ResultSrc
        send_result(10, 20, 30, 12, 1, 2'b11);

        check(wb_data, 0, "Invalid ResultSrc returns zero");

        // TEST 9: Reset protection
        @(negedge clk);
        reset = 1;
        #1;

        check(wb_reg_write, 0, "Reset blocks RegWrite");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 23 WB STAGE TESTS PASSED");
        else
            $fatal(1, "DAY 23 WB STAGE TEST FAILED");

        $finish;
    end

endmodule
