`timescale 1ns/1ps

module tb_pipeline_hazards;

    logic clk, reset;
    logic [31:0] pc, instruction;

    integer tests = 0;
    integer errors = 0;
    integer cycles = 0;

    integer stalls = 0;
    integer exmem_forwards = 0;
    integer wb_forwards = 0;
    integer redirects = 0;

    riscv_pipeline_cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*48-1:0] name;
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

    task check_positive;
        input integer actual;
        input [8*48-1:0] name;
        begin
            tests = tests + 1;

            if (actual <= 0) begin
                $display("FAIL: %0s count=%0d", name, actual);
                errors = errors + 1;
            end
            else
                $display("PASS: %0s count=%0d", name, actual);
        end
    endtask

    // Count events at the active clock edge.
    always @(posedge clk) begin
        if (!reset) begin
            if (dut.load_stall)
                stalls = stalls + 1;

            if (dut.forward_a == 2'b10 ||
                dut.forward_b == 2'b10)
                exmem_forwards = exmem_forwards + 1;

            if (dut.forward_a == 2'b01 ||
                dut.forward_b == 2'b01)
                wb_forwards = wb_forwards + 1;

            if (dut.pc_src)
                redirects = redirects + 1;
        end
    end

    initial begin
        $dumpfile("sim/pipeline/day25_hazards.vcd");
        $dumpvars(0, tb_pipeline_hazards);

        reset = 1;
        #12;

        check(pc, 0, "Reset PC");

        @(negedge clk);
        reset = 0;

        for (cycles = 0; cycles < 45; cycles = cycles + 1) begin
            @(posedge clk);
            #1;

            if (cycles < 22)
                $display(
                    "Cycle=%0d PC=%h Stall=%b FwdA=%b FwdB=%b Redirect=%b",
                    cycles + 1, pc, dut.load_stall,
                    dut.forward_a, dut.forward_b, dut.pc_src
                );
        end

        $display("-------------------------");
        $display("Checking final CPU state");
        $display("-------------------------");

        check(dut.stage_id.regfile.regs[1], 10, "x1 = 10");
        check(dut.stage_id.regfile.regs[2], 20, "x2 = 20");
        check(dut.stage_id.regfile.regs[3], 30, "x3 = 30");
        check(dut.stage_id.regfile.regs[4], 40, "x4 = 40");
        check(dut.stage_id.regfile.regs[5], 70, "x5 = 70");

        check(dut.stage_id.regfile.regs[6], 70, "x6 = 70");
        check(dut.stage_id.regfile.regs[7], 80, "x7 = 80");
        check(dut.stage_id.regfile.regs[8], 1, "x8 = 1");
        check(dut.stage_id.regfile.regs[9], 7, "x9 = 7");

        check(dut.stage_id.regfile.regs[10], 52, "JAL link x10");
        check(dut.stage_id.regfile.regs[11], 8, "x11 = 8");
        check(dut.stage_id.regfile.regs[12], 128, "x12 = 128");
        check(dut.stage_id.regfile.regs[13], 68, "JALR link x13");
        check(dut.stage_id.regfile.regs[14], 14, "Jump target x14");

        check(dut.stage_id.regfile.regs[15], 0,
              "Taken BEQ skipped x15");
        check(dut.stage_id.regfile.regs[16], 0,
              "JAL skipped x16");

        check(dut.stage_id.regfile.regs[0], 0,
              "x0 remains zero");

        check(dut.stage_mem.dmem.memory[0], 70,
              "Store/load memory result");

        check(stalls, 1, "Exactly one load-use stall");

        check_positive(exmem_forwards,
                       "EX/MEM forwarding occurred");

        check_positive(wb_forwards,
                       "MEM/WB forwarding occurred");

        check(redirects, 3,
              "BEQ, JAL and JALR redirects");

        $display("-------------------------");
        $display("Load stalls       = %0d", stalls);
        $display("EX/MEM forwards   = %0d", exmem_forwards);
        $display("MEM/WB forwards   = %0d", wb_forwards);
        $display("PC redirects      = %0d", redirects);
        $display("-------------------------");
        $display("Total Tests = %0d", tests);
        $display("Passed      = %0d", tests-errors);
        $display("Failed      = %0d", errors);

        if (errors == 0)
            $display("ALL DAY 25 HAZARD TESTS PASSED");
        else
            $fatal(1, "DAY 25 HAZARD TEST FAILED");

        $finish;
    end

endmodule
