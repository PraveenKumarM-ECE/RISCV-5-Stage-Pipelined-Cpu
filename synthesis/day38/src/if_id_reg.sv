module if_id_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        flush,

    input  logic [31:0] pc_in,
    input  logic [31:0] instruction_in,
    input  logic [31:0] pc_plus4_in,

    output logic [31:0] pc_out,
    output logic [31:0] instruction_out,
    output logic [31:0] pc_plus4_out
);

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin
            pc_out          <= 32'd0;
            instruction_out <= 32'h00000013; // NOP
            pc_plus4_out    <= 32'd0;
        end

        else if (flush) begin
            pc_out          <= 32'd0;
            instruction_out <= 32'h00000013; // NOP
            pc_plus4_out    <= 32'd0;
        end

        else if (!stall) begin
            pc_out          <= pc_in;
            instruction_out <= instruction_in;
            pc_plus4_out    <= pc_plus4_in;
        end

    end

endmodule
