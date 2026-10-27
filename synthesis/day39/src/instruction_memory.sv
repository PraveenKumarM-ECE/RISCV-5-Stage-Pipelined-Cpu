module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:255];

    // Load machine code from file
    initial begin
        $readmemh("programs/program.hex", memory);
    end

    // Convert byte address to word index
    assign instruction = memory[address[9:2]];

endmodule