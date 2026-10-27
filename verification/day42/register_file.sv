module register_file (
    input  logic        clk,
    input  logic        reg_write,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] regs [0:31];

    integer i;

    // Initialize registers for simulation
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    // Synchronous write
    always_ff @(posedge clk) begin
        if (reg_write && rd != 5'd0)
            regs[rd] <= write_data;
    end

    // Asynchronous reads
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

endmodule