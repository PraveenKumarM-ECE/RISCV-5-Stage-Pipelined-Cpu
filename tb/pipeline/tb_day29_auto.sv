`timescale 1ns/1ps

module tb_day29_auto;

    logic clk = 0;
    logic reset = 1;

    logic [31:0] pc;
    logic [31:0] instruction;

    reg [8*256-1:0] program_file;

    integer i;
    integer cycles;
    integer stalls = 0;
    integer forwards_mem = 0;
    integer forwards_wb = 0;
    integer redirects = 0;

    riscv_pipeline_cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            if (dut.load_stall)
                stalls = stalls + 1;

            if (dut.forward_a == 2'b10 ||
                dut.forward_b == 2'b10)
                forwards_mem = forwards_mem + 1;

            if (dut.forward_a == 2'b01 ||
                dut.forward_b == 2'b01)
                forwards_wb = forwards_wb + 1;

            if (dut.pc_src)
                redirects = redirects + 1;
        end
    end

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file))
            $fatal(1, "Missing +PROGRAM=path");

        if (!$value$plusargs("CYCLES=%d", cycles))
            cycles = 120;

        #1;
        $readmemh(program_file, dut.stage_if.imem.memory);

        @(negedge clk);
        reset = 0;

        repeat (cycles) @(negedge clk);

        $display("DAY29_BEGIN");

        for (i = 0; i < 32; i = i + 1)
            $display("DAY29_REG %0d %08h",
                     i, dut.stage_id.regfile.regs[i]);

        for (i = 0; i < 64; i = i + 1)
            $display("DAY29_MEM %0d %08h",
                     i, dut.stage_mem.dmem.memory[i]);

        $display("DAY29_STATS %0d %0d %0d %0d",
                 stalls, forwards_mem,
                 forwards_wb, redirects);

        $display("DAY29_END");

        $finish;
    end

endmodule
