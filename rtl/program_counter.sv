module program_counter (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic        pc_src,
    input  logic [31:0] pc_target,
    output logic [31:0] pc
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'd0;
        else if (enable) begin
            if (pc_src)
                pc <= pc_target;
            else
                pc <= pc + 32'd4;
        end
    end

endmodule