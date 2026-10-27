module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic       reg_write,
    output logic       alu_src,
    output logic       mem_write,
    output logic [1:0] result_src,
    output logic       branch,
    output logic       jump,
    output logic [3:0] alu_op
);

    always @(*) begin
        reg_write  = 0;
        alu_src    = 0;
        mem_write  = 0;
        result_src = 0;
        branch     = 0;
        jump       = 0;
        alu_op     = 4'b0000;

        case (opcode)

            // R-type
            7'b0110011: begin
                reg_write = 1;
                case (funct3)
                    3'b000: alu_op = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000;
                    3'b111: alu_op = 4'b0010;
                    3'b110: alu_op = 4'b0011;
                    3'b100: alu_op = 4'b0100;
                    3'b010: alu_op = 4'b0101;
                    3'b011: alu_op = 4'b0110;
                    3'b001: alu_op = 4'b0111;
                    3'b101: alu_op = (funct7 == 7'b0100000) ? 4'b1001 : 4'b1000;
                    default: alu_op = 4'b0000;
                endcase
            end

            // I-type arithmetic
            7'b0010011: begin
                reg_write = 1;
                alu_src = 1;
                case (funct3)
                    3'b000: alu_op = 4'b0000;
                    3'b111: alu_op = 4'b0010;
                    3'b110: alu_op = 4'b0011;
                    3'b100: alu_op = 4'b0100;
                    3'b010: alu_op = 4'b0101;
                    3'b011: alu_op = 4'b0110;
                    3'b001: alu_op = 4'b0111;
                    3'b101: alu_op = (funct7 == 7'b0100000) ? 4'b1001 : 4'b1000;
                    default: alu_op = 4'b0000;
                endcase
            end

            // Load
            7'b0000011: begin
                reg_write = 1;
                alu_src = 1;
                result_src = 2'b01;
            end

            // Store
            7'b0100011: begin
                alu_src = 1;
                mem_write = 1;
            end

            // Branch
            7'b1100011: begin
                branch = 1;
                alu_op = 4'b0001;
            end

            // JAL
            7'b1101111: begin
                reg_write = 1;
                jump = 1;
                result_src = 2'b10;
            end

            // JALR
            7'b1100111: begin
                reg_write = 1;
                alu_src = 1;
                alu_op = 4'b0000;
                jump = 1;
                result_src = 2'b10;
            end

            // LUI
            7'b0110111: begin
                reg_write = 1;
                alu_src = 1;
            end

            // AUIPC
            7'b0010111: begin
                reg_write = 1;
                alu_src = 1;
            end

            default: begin
                // Defaults already set
            end

        endcase
    end

endmodule