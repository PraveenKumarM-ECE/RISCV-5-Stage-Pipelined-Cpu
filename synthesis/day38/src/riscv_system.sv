module riscv_system (
    input logic clk,
    input logic reset,

    output logic [31:0] pc,
    output logic [31:0] instruction
);

    logic [31:0] rom_instruction;

    instruction_rom rom (
        .address(pc),
        .instruction(rom_instruction)
    );

    riscv_pipeline_cpu cpu (
        .clk(clk),
        .reset(reset),
        .instruction_in(rom_instruction),
        .pc(pc),
        .instruction(instruction)
    );

endmodule
