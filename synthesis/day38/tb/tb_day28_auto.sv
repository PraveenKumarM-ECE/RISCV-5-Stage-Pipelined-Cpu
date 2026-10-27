`timescale 1ns/1ps

module tb_day28_auto;
    reg [31:0] test_rom [0:255];
    wire [31:0] instruction_feed;

    assign instruction_feed = test_rom[pc[9:2]];


    logic clk = 0;
    logic reset = 1;

    logic [31:0] pc;
    logic [31:0] instruction;

    reg [8*256-1:0] program_file;

    integer i;
    integer cycles = 0;
    integer stalls = 0;
    integer forwards_mem = 0;
    integer forwards_wb = 0;
    integer redirects = 0;

    riscv_pipeline_cpu dut (
        .instruction_in(instruction_feed),
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            cycles = cycles + 1;

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

        // Override the default instruction memory contents
        // while the processor is held in reset.
        #1;
        $readmemh(program_file, test_rom);

        @(negedge clk);
        reset = 0;

        // 80 program instructions plus enough cycles
        // to drain the five-stage pipeline.
        repeat (90) @(negedge clk);

        $display("DAY28_BEGIN");

        for (i = 0; i < 32; i = i + 1)
            $display("DAY28_REG %0d %08h",
                     i, dut.stage_id.regfile.regs[i]);

        $display("DAY28_STATS %0d %0d %0d %0d",
                 stalls, forwards_mem,
                 forwards_wb, redirects);

        $display("DAY28_END");

        $finish;
    end

endmodule
