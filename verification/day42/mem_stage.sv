module mem_stage (
    input  logic        clk,
    input  logic        reset,

    input  logic        mem_write,
    input  logic [2:0]  funct3,
    input  logic [31:0] alu_result,
    input  logic [31:0] store_data,

    output logic [31:0] memory_data
);

    data_memory dmem (
        .clk(clk),
        .mem_write(mem_write && !reset),
        .address(alu_result),
        .write_data(store_data),
        .read_data(memory_data),
        .funct3(funct3)
    );

endmodule
