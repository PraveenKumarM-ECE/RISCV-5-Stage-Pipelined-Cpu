module riscv_cpu (
    input logic clk,
    input logic reset,
    output logic [31:0] pc,
    output logic [31:0] instruction
);

    logic [6:0] opcode, funct7;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;

    logic [31:0] immediate;
    logic [31:0] read_data1, read_data2;
    logic [31:0] alu_input2, alu_result;
    logic [31:0] memory_data, writeback_data;
    logic zero;

    logic reg_write, alu_src, mem_write;
    logic [1:0] result_src;
    logic branch, jump;
    logic [3:0] alu_op;

    // Branch control
    logic branch_taken;
    logic pc_src;
    logic [31:0] pc_target;

    always @(*) begin
    branch_taken = 1'b0;

    if (branch) begin
    case (funct3)
    3'b000: branch_taken = (read_data1 == read_data2); // BEQ
    3'b001: branch_taken = (read_data1 != read_data2); // BNE
    3'b100: branch_taken = ($signed(read_data1) < $signed(read_data2)); // BLT
    3'b101: branch_taken = ($signed(read_data1) >= $signed(read_data2)); // BGE
    3'b110: branch_taken = (read_data1 < read_data2); // BLTU
    3'b111: branch_taken = (read_data1 >= read_data2); // BGEU
    default: branch_taken = 1'b0;
    endcase
    end
    end

    assign pc_src = branch_taken | jump;

    assign pc_target =
        jump && (opcode == 7'b1100111)
            ? {alu_result[31:1], 1'b0}
            : pc + immediate;

    // Program Counter
    program_counter pc_unit (
    .clk(clk),
    .reset(reset),
    .enable(1'b1),
    .pc_src(pc_src),
    .pc_target(pc_target),
    .pc(pc)
    );

    // Instruction Memory
    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );

    // Instruction Decoder
    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    // Immediate Generator
    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

    // Control Unit
    control_unit control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .result_src(result_src),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );

    // Register File
    register_file regfile (
        .clk(clk),
        .reg_write(reg_write && !reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(writeback_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // ALU Input Multiplexer
    assign alu_input2 = alu_src ? immediate : read_data2;

    // ALU
    alu alu_unit (
        .a(
        (opcode == 7'b0110111) ? 32'd0 :
        (opcode == 7'b0010111) ? pc :
        read_data1
    ),
        .b(alu_input2),
        .op(alu_op),
        .y(alu_result),
        .zero(zero)
    );

    // Data Memory
    data_memory dmem (
        .clk(clk),
        .mem_write(mem_write && !reset),
        .address(alu_result),
        .write_data(read_data2),
        .read_data(memory_data), .funct3(funct3)
    );

    // Writeback Multiplexer
    always @(*) begin
        case (result_src)
            2'b00: writeback_data = alu_result;
            2'b01: writeback_data = memory_data;
            2'b10: writeback_data = pc + 32'd4;
            default: writeback_data = 32'd0;
        endcase
    end

endmodule