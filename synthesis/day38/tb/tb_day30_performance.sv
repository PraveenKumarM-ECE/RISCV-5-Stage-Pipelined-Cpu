`timescale 1ns/1ps

module tb_day30_performance;
    reg [31:0] test_rom [0:255];
    wire [31:0] instruction_feed;

    assign instruction_feed = test_rom[pc[9:2]];


    logic clk = 0;
    logic reset = 1;

    logic [31:0] pc;
    logic [31:0] instruction;

    reg [8*256-1:0] program_file;

    integer cycles = 0;
    integer stalls = 0;
    integer fwd_mem = 0;
    integer fwd_wb = 0;
    integer redirects = 0;

    riscv_pipeline_cpu dut (
        .instruction_in(instruction_feed),
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file))
            $fatal(1, "Missing +PROGRAM=path");

        #1;
        $readmemh(program_file, test_rom);

        @(negedge clk);
        reset = 0;
    end

    always @(posedge clk) begin
        if (!reset) begin
            cycles = cycles + 1;

            if (dut.load_stall)
                stalls = stalls + 1;

            if (dut.forward_a == 2'b10 ||
                dut.forward_b == 2'b10)
                fwd_mem = fwd_mem + 1;

            if (dut.forward_a == 2'b01 ||
                dut.forward_b == 2'b01)
                fwd_wb = fwd_wb + 1;

            if (dut.pc_src)
                redirects = redirects + 1;

            // Marker reaches the WB stage.
            if (dut.wb_reg_write &&
                dut.wb_rd == 5'd31 &&
                dut.wb_data == 32'd123) begin

                $display("DAY30_BEGIN");
                $display("DAY30_CYCLES %0d", cycles);
                $display("DAY30_STALLS %0d", stalls);
                $display("DAY30_FWD_MEM %0d", fwd_mem);
                $display("DAY30_FWD_WB %0d", fwd_wb);
                $display("DAY30_REDIRECTS %0d", redirects);

                $display("DAY30_X1 %08h",
                         dut.stage_id.regfile.regs[1]);
                $display("DAY30_X3 %08h",
                         dut.stage_id.regfile.regs[3]);
                $display("DAY30_X20 %08h",
                         dut.stage_id.regfile.regs[20]);
                $display("DAY30_X21 %08h",
                         dut.stage_id.regfile.regs[21]);

                $display("DAY30_END");
                $finish;
            end

            if (cycles > 200)
                $fatal(1, "Timeout: marker not reached");
        end
    end

endmodule
