module mem_wb_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        flush,

    input  logic [31:0] alu_result_in,
    input  logic [31:0] memory_data_in,
    input  logic [31:0] pc_plus4_in,

    input  logic [4:0]  rd_in,
    input  logic        reg_write_in,
    input  logic [1:0]  result_src_in,

    output logic [31:0] alu_result_out,
    output logic [31:0] memory_data_out,
    output logic [31:0] pc_plus4_out,

    output logic [4:0]  rd_out,
    output logic        reg_write_out,
    output logic [1:0]  result_src_out
);

    assign memory_data_out = memory_data_in;

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            alu_result_out <= 0;

            pc_plus4_out <= 0;

            rd_out <= 0;
            reg_write_out <= 0;
            result_src_out <= 0;
        end
        else if (!stall) begin
            alu_result_out <= alu_result_in;

            pc_plus4_out <= pc_plus4_in;

            rd_out <= rd_in;
            reg_write_out <= reg_write_in;
            result_src_out <= result_src_in;
        end
    end

endmodule
