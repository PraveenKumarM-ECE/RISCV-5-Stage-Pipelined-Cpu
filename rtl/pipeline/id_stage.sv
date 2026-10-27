module id_stage (
    input  logic        clk,
    input  logic        reset,

    input  logic [31:0] instruction,

    // Register writeback from a later pipeline stage
    input  logic        wb_reg_write,
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_data,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2,
    output logic [31:0] immediate,

    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    output logic [6:0]  opcode,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,

    output logic        reg_write,
    output logic        alu_src,
    output logic        mem_write,
    output logic [1:0]  result_src,
    output logic        branch,
    output logic        jump,
    output logic [3:0]  alu_op
);

    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

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

    logic [31:0] rf_data1;
    logic [31:0] rf_data2;

    register_file regfile (
        .clk(clk),
        .reg_write(wb_reg_write && !reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(wb_rd),
        .write_data(wb_data),
        .read_data1(rf_data1),
        .read_data2(rf_data2)
    );

    // WB-to-ID bypass.
    // Handles register-file read/write timing hazards.
    assign read_data1 =
        (wb_reg_write && !reset &&
         wb_rd != 5'd0 && wb_rd == rs1)
            ? wb_data : rf_data1;

    assign read_data2 =
        (wb_reg_write && !reset &&
         wb_rd != 5'd0 && wb_rd == rs2)
            ? wb_data : rf_data2;

endmodule
