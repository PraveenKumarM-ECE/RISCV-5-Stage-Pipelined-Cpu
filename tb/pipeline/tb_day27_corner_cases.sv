`timescale 1ns/1ps

module tb_day27_corner_cases;

    logic clk = 0;
    logic reset = 1;

    logic [31:0] pc;
    logic [31:0] instruction;

    reg [8*256-1:0] program_file;

    integer case_id;
    integer tests = 0;
    integer errors = 0;
    integer cycle;

    integer stalls = 0;
    integer forward_mem = 0;
    integer forward_wb = 0;
    integer redirects = 0;

    riscv_pipeline_cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*48-1:0] name;
        begin
            tests = tests + 1;

            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s got=%h expected=%h",
                         name, actual, expected);
            end
            else begin
                $display("PASS: %0s = %h", name, actual);
            end
        end
    endtask

    task check_positive;
        input integer value;
        input [8*48-1:0] name;
        begin
            tests = tests + 1;

            if (value <= 0) begin
                errors = errors + 1;
                $display("FAIL: %0s count=%0d", name, value);
            end
            else begin
                $display("PASS: %0s count=%0d", name, value);
            end
        end
    endtask

    // Monitor hazard activity before each rising edge
    // updates the pipeline registers.
    always @(posedge clk) begin
        if (!reset) begin
            if (dut.load_stall)
                stalls = stalls + 1;

            if (dut.forward_a == 2'b10 ||
                dut.forward_b == 2'b10)
                forward_mem = forward_mem + 1;

            if (dut.forward_a == 2'b01 ||
                dut.forward_b == 2'b01)
                forward_wb = forward_wb + 1;

            if (dut.pc_src)
                redirects = redirects + 1;
        end
    end

    initial begin
        if (!$value$plusargs("CASE=%d", case_id))
            $fatal(1, "Missing +CASE=N");

        if (!$value$plusargs("PROGRAM=%s", program_file))
            $fatal(1, "Missing +PROGRAM=path");

        $dumpfile("sim/pipeline/day27_corner_cases.vcd");
        $dumpvars(0, tb_day27_corner_cases);

        // Instruction memory also loads its default file at
        // time zero. Override it after a short delay.
        #1;
        $readmemh(program_file, dut.stage_if.imem.memory);

        // Reset remains active until the next falling edge.
        @(negedge clk);
        reset = 0;

        $display("===============================");
        $display("DAY 27 REGRESSION CASE %0d", case_id);
        $display("===============================");

        // All test programs are short. Extra NOPs allow
        // the pipeline to drain completely.
        for (cycle = 0; cycle < 65; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
        end


        case (case_id)

            1: begin
                check(dut.stage_id.regfile.regs[2], 5, "x2");
                check(dut.stage_id.regfile.regs[3], 10, "x3");
                check(dut.stage_id.regfile.regs[4], 10, "x4");
                check(dut.stage_id.regfile.regs[5], 20, "x5");
                check(dut.stage_id.regfile.regs[6], 20, "x6");
                check(dut.stage_id.regfile.regs[7], 40, "x7");
                check(dut.stage_mem.dmem.memory[0], 5, "mem[0]");
                check(dut.stage_mem.dmem.memory[1], 10, "mem[1]");
                check(dut.stage_mem.dmem.memory[2], 20, "mem[2]");
                check(stalls, 3, "Three load stalls");
            end

            2: begin
                check(dut.stage_id.regfile.regs[1], 20, "x1");
                check(dut.stage_id.regfile.regs[2], 30, "x2");
                check(dut.stage_id.regfile.regs[3], 50, "x3");
                check(dut.stage_id.regfile.regs[4], 70, "x4");
                check(stalls, 0, "No load stalls");
                check_positive(forward_mem, "EX/MEM forwarding");
                check_positive(forward_wb, "MEM/WB forwarding");
            end

            3: begin
                check(dut.stage_id.regfile.regs[2], 9, "Loaded x2");
                check(dut.stage_id.regfile.regs[3], 0, "Flushed x3");
                check(dut.stage_id.regfile.regs[4], 4, "x4");
                check(dut.stage_id.regfile.regs[5], 9, "Loaded x5");
                check(dut.stage_id.regfile.regs[6], 6, "x6");
                check(dut.stage_id.regfile.regs[7], 7, "x7");
                check(stalls, 2, "Two load stalls");
                check(redirects, 1, "One taken branch");
            end

            4: begin
                check(dut.stage_id.regfile.regs[3], 42, "x3");
                check(dut.stage_id.regfile.regs[4], 42, "x4");
                check(dut.stage_id.regfile.regs[5], 50, "x5");
                check(dut.stage_id.regfile.regs[6], 50, "x6");
                check(dut.stage_id.regfile.regs[7], 51, "x7");
                check(dut.stage_id.regfile.regs[9], 42, "x9");
                check(dut.stage_mem.dmem.memory[4], 42, "mem[16]");
                check(dut.stage_mem.dmem.memory[5], 42, "mem[20]");
                check(dut.stage_mem.dmem.memory[6], 50, "mem[24]");
                check(stalls, 4, "Four load stalls");
            end

            5: begin
                check(dut.stage_mem.dmem.memory[0], 0,
                      "Wrong-path store address 0 suppressed");
                check(dut.stage_mem.dmem.memory[1], 0,
                      "Wrong-path store address 4 suppressed");
                check(dut.stage_mem.dmem.memory[2], 33,
                      "Correct-path store address 8");
                check(dut.stage_id.regfile.regs[3], 33, "x3");
                check(dut.stage_id.regfile.regs[4], 33, "x4");
                check(dut.stage_id.regfile.regs[5], 34, "x5");
                check(redirects, 1, "One taken branch");
            end

            6: begin
                check(dut.stage_id.regfile.regs[1], 0,
                      "Loop counter ends at zero");
                check(dut.stage_id.regfile.regs[2], 15,
                      "Loop sum");
                check(dut.stage_id.regfile.regs[3], 15,
                      "Final sum copy");
                check(dut.stage_id.regfile.regs[4], 15,
                      "Reloaded sum");
                check(dut.stage_mem.dmem.memory[0], 15,
                      "Stored sum");
                check(redirects, 4,
                      "Four backward branches");
            end

            default: $fatal(1, "Unknown Day 27 case");

        endcase

        $display("-------------------------------");
        $display("Stalls          = %0d", stalls);
        $display("EX/MEM forwards = %0d", forward_mem);
        $display("MEM/WB forwards = %0d", forward_wb);
        $display("Redirects       = %0d", redirects);
        $display("-------------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests - errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("DAY 27 CASE %0d PASSED", case_id);
        else
            $fatal(1, "DAY 27 CASE %0d FAILED", case_id);

        $finish;
    end

endmodule
