module ex_mem_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        flush,

    input  logic [31:0] alu_result_in,
    input  logic [31:0] store_data_in,
    input  logic [31:0] pc_plus4_in,

    input  logic [4:0]  rd_in,
    input  logic [2:0]  funct3_in,

    input  logic        reg_write_in,
    input  logic        mem_write_in,
    input  logic [1:0]  result_src_in,

    output logic [31:0] alu_result_out,
    output logic [31:0] store_data_out,
    output logic [31:0] pc_plus4_out,

    output logic [4:0]  rd_out,
    output logic [2:0]  funct3_out,

    output logic        reg_write_out,
    output logic        mem_write_out,
    output logic [1:0]  result_src_out
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            alu_result_out <= 0;
            store_data_out <= 0;
            pc_plus4_out   <= 0;

            rd_out         <= 0;
            funct3_out     <= 0;

            reg_write_out  <= 0;
            mem_write_out  <= 0;
            result_src_out <= 0;
        end
        else if (!stall) begin
            alu_result_out <= alu_result_in;
            store_data_out <= store_data_in;
            pc_plus4_out   <= pc_plus4_in;

            rd_out         <= rd_in;
            funct3_out     <= funct3_in;

            reg_write_out  <= reg_write_in;
            mem_write_out  <= mem_write_in;
            result_src_out <= result_src_in;
        end
    end

endmodule
