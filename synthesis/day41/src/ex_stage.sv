module ex_stage (
    input  logic [31:0] pc,
    input  logic [31:0] pc_plus4,
    input  logic [31:0] read_data1,
    input  logic [31:0] read_data2,
    input  logic [31:0] immediate,

    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [3:0]  alu_op,

    input  logic        alu_src,
    input  logic        branch,
    input  logic        jump,

    output logic [31:0] alu_result,
    output logic [31:0] store_data,
    output logic [31:0] pc_target,
    output logic        pc_src
);

    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic zero;

    // Select first ALU operand
    always @(*) begin
        case (opcode)
            7'b0110111: alu_a = 32'd0; // LUI
            7'b0010111: alu_a = pc;    // AUIPC
            default:    alu_a = read_data1;
        endcase
    end

    // Select second ALU operand
    assign alu_b = alu_src ? immediate : read_data2;

    // Reuse existing ALU
    alu alu_unit (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .y(alu_result),
        .zero(zero)
    );

    // Store data must be original rs2 value
    assign store_data = read_data2;

    // Branch and jump decision
    always @(*) begin
        pc_src = 1'b0;

        if (jump) begin
            pc_src = 1'b1;
        end
        else if (branch) begin
            case (funct3)
                3'b000: pc_src = (read_data1 == read_data2); // BEQ
                3'b001: pc_src = (read_data1 != read_data2); // BNE
                3'b100: pc_src = ($signed(read_data1) < $signed(read_data2)); // BLT
                3'b101: pc_src = ($signed(read_data1) >= $signed(read_data2)); // BGE
                3'b110: pc_src = (read_data1 < read_data2); // BLTU
                3'b111: pc_src = (read_data1 >= read_data2); // BGEU
                default: pc_src = 1'b0;
            endcase
        end
    end

    // Branch/JAL: PC + immediate
    // JALR: (rs1 + immediate) with bit 0 cleared
    assign pc_target =
        (jump && opcode == 7'b1100111)
            ? {alu_result[31:1], 1'b0}
            : pc + immediate;

endmodule
