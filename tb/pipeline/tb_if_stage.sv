`timescale 1ns/1ps

module tb_if_stage;

    logic clk, reset, stall, flush, pc_src;
    logic [31:0] pc_target;

    logic [31:0] pc, instruction, pc_plus4;
    logic [31:0] id_pc, id_instruction, id_pc_plus4;

    integer tests = 0;
    integer errors = 0;

    if_stage dut_if (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .pc(pc),
        .instruction(instruction),
        .pc_plus4(pc_plus4)
    );

    if_id_reg dut_ifid (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_in(pc),
        .instruction_in(instruction),
        .pc_plus4_in(pc_plus4),
        .pc_out(id_pc),
        .instruction_out(id_instruction),
        .pc_plus4_out(id_pc_plus4)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*32-1:0] name;
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
        $dumpfile("sim/pipeline/day19_if.vcd");
        $dumpvars(0, tb_if_stage);

        reset = 1;
        stall = 0;
        flush = 0;
        pc_src = 0;
        pc_target = 0;

        #12;
        check(pc, 0, "Reset PC");
        check(id_instruction, 32'h00000013, "Reset NOP");

        @(negedge clk);
        reset = 0;

        // Fetch instruction at PC=0
        #1;
        check(instruction, 32'h00a00093, "Fetch instruction 0");

        @(posedge clk);
        #1;
        check(id_pc, 0, "IF/ID PC 0");
        check(id_instruction, 32'h00a00093, "IF/ID instruction 0");
        check(pc, 4, "PC after first fetch");

        @(posedge clk);
        #1;
        check(id_pc, 4, "IF/ID PC 4");
        check(id_instruction, 32'h01400113, "IF/ID instruction 4");
        check(pc, 8, "PC after second fetch");

        // Stall the pipeline
        @(negedge clk);
        stall = 1;

        @(posedge clk);
        #1;
        check(pc, 8, "PC held during stall");
        check(id_pc, 4, "IF/ID held during stall");

        // Resume
        @(negedge clk);
        stall = 0;

        @(posedge clk);
        #1;
        check(id_pc, 8, "IF/ID PC after resume");
        check(id_instruction, 32'h002081b3, "IF/ID ADD instruction");
        check(pc, 12, "PC after resume");

        // Flush IF/ID
        @(negedge clk);
        flush = 1;
        stall = 1;

        @(posedge clk);
        #1;
        check(id_instruction, 32'h00000013, "Flush inserts NOP");
        check(pc, 12, "PC held during flush test");

        // Redirect PC to address 4
        @(negedge clk);
        flush = 0;
        stall = 0;
        pc_src = 1;
        pc_target = 4;

        @(posedge clk);
        #1;
        check(pc, 4, "PC redirect to 4");

        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 19 IF STAGE TESTS PASSED");
        else
            $fatal(1, "DAY 19 TEST FAILED");

        $finish;
    end

endmodule
