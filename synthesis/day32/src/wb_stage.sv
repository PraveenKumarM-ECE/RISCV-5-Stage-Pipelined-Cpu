module wb_stage (
    input  logic        reset,

    input  logic [31:0] alu_result,
    input  logic [31:0] memory_data,
    input  logic [31:0] pc_plus4,

    input  logic [4:0]  rd,
    input  logic        reg_write,
    input  logic [1:0]  result_src,

    output logic [31:0] wb_data,
    output logic [4:0]  wb_rd,
    output logic        wb_reg_write
);

    // Select the value to write back
    always @(*) begin
        case (result_src)
            2'b00: wb_data = alu_result;
            2'b01: wb_data = memory_data;
            2'b10: wb_data = pc_plus4;
            default: wb_data = 32'd0;
        endcase
    end

    // Destination register
    assign wb_rd = rd;

    // Disable writes during reset and prevent x0 writes
    assign wb_reg_write = reg_write && !reset && (rd != 5'd0);

endmodule
