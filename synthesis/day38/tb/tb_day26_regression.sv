`timescale 1ns/1ps

module tb_day26_regression;
    reg [31:0] test_rom [0:255];
    wire [31:0] instruction_feed;

    assign instruction_feed = test_rom[pc[9:2]];


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
        .instruction_in(instruction_feed),
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

        $dumpfile("sim/pipeline/day26_regression.vcd");
        $dumpvars(0, tb_day26_regression);

        // Instruction memory also loads its default file at
        // time zero. Override it after a short delay.
        #1;
        $readmemh(program_file, test_rom);

        // Reset remains active until the next falling edge.
        @(negedge clk);
        reset = 0;

        $display("===============================");
        $display("DAY 26 REGRESSION CASE %0d", case_id);
        $display("===============================");

        // All test programs are short. Extra NOPs allow
        // the pipeline to drain completely.
        for (cycle = 0; cycle < 65; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
        end

        case (case_id)

            1: begin
                check(dut.stage_id.regfile.regs[1], 3, "x1");
                check(dut.stage_id.regfile.regs[2], 6, "x2");
                check(dut.stage_id.regfile.regs[3], 9, "x3");
                check(dut.stage_id.regfile.regs[4], 10, "x4");
                check(dut.stage_id.regfile.regs[5], 16, "x5");
                check(dut.stage_id.regfile.regs[6], 19, "x6");

                check_positive(forward_mem, "EX/MEM forwarding");
                check_positive(forward_wb, "MEM/WB forwarding");
            end

            2: begin
                check(dut.stage_id.regfile.regs[1],
                      32'hfffffff8, "x1");
                check(dut.stage_id.regfile.regs[2], 3, "x2");
                check(dut.stage_id.regfile.regs[3],
                      32'hfffffffb, "x3");
                check(dut.stage_id.regfile.regs[4],
                      32'hfffffff8, "x4");
                check(dut.stage_id.regfile.regs[5],
                      32'hfffffff0, "x5");
                check(dut.stage_id.regfile.regs[6],
                      32'hfffffff3, "x6");
                check(dut.stage_id.regfile.regs[7],
                      32'hfffffff6, "x7");

                check_positive(forward_mem, "ALU forwarding");
            end

            3: begin
                check(dut.stage_id.regfile.regs[1], 55, "x1");
                check(dut.stage_id.regfile.regs[2], 55, "x2");
                check(dut.stage_id.regfile.regs[3], 110, "x3");
                check(dut.stage_id.regfile.regs[4], 55, "x4");
                check(dut.stage_id.regfile.regs[5], 55, "x5");
                check(dut.stage_id.regfile.regs[6], 165, "x6");

                check(dut.stage_mem.dmem.memory[0],
                      55, "Memory address 0");
                check(dut.stage_mem.dmem.memory[1],
                      55, "Memory address 4");

                check(stalls, 3, "Three load-use stalls");
            end

            4: begin
                check(dut.stage_id.regfile.regs[1], 16, "x1");
                check(dut.stage_id.regfile.regs[2], 127, "x2");
                check(dut.stage_id.regfile.regs[3], 127, "x3");
                check(dut.stage_id.regfile.regs[4], 128, "x4");
                check(dut.stage_id.regfile.regs[5], 128, "x5");

                check(dut.stage_id.regfile.regs[6],
                      32'hffff807f, "x6 signed halfword");
                check(dut.stage_id.regfile.regs[7],
                      32'h0000807f, "x7 unsigned halfword");

                check(dut.stage_mem.dmem.memory[4],
                      32'h0000807f, "Memory word");
            end

            5: begin
                check(dut.stage_id.regfile.regs[1],
                      32'hffffffff, "x1");
                check(dut.stage_id.regfile.regs[2], 1, "x2");
                check(dut.stage_id.regfile.regs[3], 1, "SLT");
                check(dut.stage_id.regfile.regs[4], 0, "SLTU");
                check(dut.stage_id.regfile.regs[5], 2, "SLL");

                check(dut.stage_id.regfile.regs[6],
                      32'h7fffffff, "SRL");
                check(dut.stage_id.regfile.regs[7],
                      32'hffffffff, "SRA");
                check(dut.stage_id.regfile.regs[8], 1, "SLTI");
                check(dut.stage_id.regfile.regs[9], 0, "SLTIU");
            end

            6: begin
                check(dut.stage_id.regfile.regs[3], 0,
                      "BEQ flush x3");
                check(dut.stage_id.regfile.regs[4], 4,
                      "BNE not taken x4");
                check(dut.stage_id.regfile.regs[5], 28,
                      "JAL link x5");
                check(dut.stage_id.regfile.regs[6], 0,
                      "JAL flush x6");
                check(dut.stage_id.regfile.regs[7], 7,
                      "Jump target x7");
                check(dut.stage_id.regfile.regs[9], 44,
                      "JALR link x9");
                check(dut.stage_id.regfile.regs[10], 0,
                      "JALR flush x10");
                check(dut.stage_id.regfile.regs[11], 11,
                      "JALR target x11");

                check(redirects, 3,
                      "BEQ JAL JALR redirects");
            end

            default: $fatal(1, "Unknown case number");
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
            $display("DAY 26 CASE %0d PASSED", case_id);
        else
            $fatal(1, "DAY 26 CASE %0d FAILED", case_id);

        $finish;
    end

endmodule
