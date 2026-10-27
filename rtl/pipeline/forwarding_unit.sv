module forwarding_unit (
    input  logic [4:0] ex_rs1,
    input  logic [4:0] ex_rs2,

    input  logic [4:0] mem_rd,
    input  logic       mem_reg_write,
    input  logic [1:0] mem_result_src,

    input  logic [4:0] wb_rd,
    input  logic       wb_reg_write,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // Forward from MEM/WB
        if (wb_reg_write && wb_rd != 0) begin
            if (wb_rd == ex_rs1)
                forward_a = 2'b01;

            if (wb_rd == ex_rs2)
                forward_b = 2'b01;
        end

        // Forward from EX/MEM, with higher priority.
        // Load data is not ready in EX/MEM.
        if (mem_reg_write && mem_rd != 0 &&
            mem_result_src != 2'b01) begin

            if (mem_rd == ex_rs1)
                forward_a = 2'b10;

            if (mem_rd == ex_rs2)
                forward_b = 2'b10;
        end
    end

endmodule
