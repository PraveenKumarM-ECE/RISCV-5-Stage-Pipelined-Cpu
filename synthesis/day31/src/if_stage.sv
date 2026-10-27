module if_stage (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        pc_src,
    input  logic [31:0] pc_target,

    output logic [31:0] pc,
    output logic [31:0] instruction,
    output logic [31:0] pc_plus4
);

    program_counter pc_unit (
        .clk(clk),
        .reset(reset),
        .enable(!stall),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .pc(pc)
    );

    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );

    assign pc_plus4 = pc + 32'd4;

endmodule
