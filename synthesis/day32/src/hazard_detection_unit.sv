module hazard_detection_unit (
    input  logic [4:0] ex_rd,
    input  logic       ex_reg_write,
    input  logic [1:0] ex_result_src,

    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,
    input  logic [6:0] id_opcode,

    output logic       load_stall
);

    logic uses_rs1;
    logic uses_rs2;

    always @(*) begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        case (id_opcode)
            7'b0110011: begin // R-type
                uses_rs1 = 1;
                uses_rs2 = 1;
            end

            7'b1100011: begin // Branch
                uses_rs1 = 1;
                uses_rs2 = 1;
            end

            7'b0100011: begin // Store
                uses_rs1 = 1;
                uses_rs2 = 1;
            end

            7'b0010011,     // I-type arithmetic
            7'b0000011,     // Load
            7'b1100111: begin // JALR
                uses_rs1 = 1;
            end

            default: begin
                uses_rs1 = 0;
                uses_rs2 = 0;
            end
        endcase
    end

    always @(*) begin
        load_stall = 1'b0;

        if (ex_reg_write &&
            ex_result_src == 2'b01 &&
            ex_rd != 0) begin

            if ((uses_rs1 && id_rs1 == ex_rd) ||
                (uses_rs2 && id_rs2 == ex_rd))
                load_stall = 1'b1;
        end
    end

endmodule
