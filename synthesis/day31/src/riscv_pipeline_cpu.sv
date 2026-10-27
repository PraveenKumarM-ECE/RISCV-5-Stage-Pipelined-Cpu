module riscv_pipeline_cpu (
    input  logic        clk,
    input  logic        reset,

    output logic [31:0] pc,
    output logic [31:0] instruction
);

    // ==========================================
    // 1. INSTRUCTION FETCH (IF)
    // ==========================================

    logic [31:0] if_pc_plus4;

    logic [31:0] id_pc;
    logic [31:0] id_instruction;
    logic [31:0] id_pc_plus4;

    logic pc_src;
    logic load_stall;
    logic [31:0] pc_target;

    if_stage stage_if (
        .clk(clk),
        .reset(reset),
        .stall(load_stall && !pc_src),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .pc(pc),
        .instruction(instruction),
        .pc_plus4(if_pc_plus4)
    );

    if_id_reg reg_if_id (
        .clk(clk),
        .reset(reset),
        .stall(load_stall && !pc_src),
        .flush(pc_src),
        .pc_in(pc),
        .instruction_in(instruction),
        .pc_plus4_in(if_pc_plus4),
        .pc_out(id_pc),
        .instruction_out(id_instruction),
        .pc_plus4_out(id_pc_plus4)
    );

    // ==========================================
    // 2. INSTRUCTION DECODE (ID)
    // ==========================================

    logic [31:0] id_data1, id_data2;
    logic [31:0] id_immediate;

    logic [4:0] id_rs1, id_rs2, id_rd;
    logic [6:0] id_opcode, id_funct7;
    logic [2:0] id_funct3;

    logic id_reg_write;
    logic id_alu_src;
    logic id_mem_write;
    logic [1:0] id_result_src;
    logic id_branch, id_jump;
    logic [3:0] id_alu_op;

    // Writeback signals from the WB stage
    logic [31:0] wb_data;
    logic [4:0] wb_rd;
    logic wb_reg_write;

    id_stage stage_id (
        .clk(clk),
        .reset(reset),
        .instruction(id_instruction),

        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data),

        .read_data1(id_data1),
        .read_data2(id_data2),
        .immediate(id_immediate),

        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),

        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),

        .reg_write(id_reg_write),
        .alu_src(id_alu_src),
        .mem_write(id_mem_write),
        .result_src(id_result_src),
        .branch(id_branch),
        .jump(id_jump),
        .alu_op(id_alu_op)
    );

    // ==========================================
    // 3. ID/EX PIPELINE REGISTER
    // ==========================================

    logic [31:0] ex_pc, ex_pc_plus4;
    logic [31:0] ex_data1, ex_data2, ex_immediate;

    logic [4:0] ex_rs1, ex_rs2, ex_rd;
    logic [6:0] ex_opcode;
    logic [2:0] ex_funct3;

    logic ex_reg_write;
    logic ex_alu_src;
    logic ex_mem_write;
    logic [1:0] ex_result_src;
    logic ex_branch, ex_jump;
    logic [3:0] ex_alu_op;

    id_ex_reg reg_id_ex (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(pc_src || load_stall),

        .pc_in(id_pc),
        .pc_plus4_in(id_pc_plus4),
        .read_data1_in(id_data1),
        .read_data2_in(id_data2),
        .immediate_in(id_immediate),

        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .opcode_in(id_opcode),
        .funct3_in(id_funct3),

        .reg_write_in(id_reg_write),
        .alu_src_in(id_alu_src),
        .mem_write_in(id_mem_write),
        .result_src_in(id_result_src),
        .branch_in(id_branch),
        .jump_in(id_jump),
        .alu_op_in(id_alu_op),

        .pc_out(ex_pc),
        .pc_plus4_out(ex_pc_plus4),
        .read_data1_out(ex_data1),
        .read_data2_out(ex_data2),
        .immediate_out(ex_immediate),

        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rd_out(ex_rd),
        .opcode_out(ex_opcode),
        .funct3_out(ex_funct3),

        .reg_write_out(ex_reg_write),
        .alu_src_out(ex_alu_src),
        .mem_write_out(ex_mem_write),
        .result_src_out(ex_result_src),
        .branch_out(ex_branch),
        .jump_out(ex_jump),
        .alu_op_out(ex_alu_op)
    );

    // ==========================================
    // 4. EXECUTE (EX)
    // ==========================================

    logic [31:0] ex_alu_result;
    logic [31:0] ex_store_data;

    logic [1:0] forward_a, forward_b;
    logic [31:0] forwarded_a, forwarded_b;
    logic [31:0] mem_forward_data;

    // JAL/JALR forward PC+4; other supported
    // non-load instructions forward the ALU result.
    assign mem_forward_data =
        (mem_result_src == 2'b10)
            ? mem_pc_plus4 : mem_alu_result;

    forwarding_unit forwarding (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .mem_rd(mem_rd),
        .mem_reg_write(mem_reg_write),
        .mem_result_src(mem_result_src),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    hazard_detection_unit hazards (
        .ex_rd(ex_rd),
        .ex_reg_write(ex_reg_write),
        .ex_result_src(ex_result_src),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_opcode(id_opcode),
        .load_stall(load_stall)
    );

    always @(*) begin
        case (forward_a)
            2'b10: forwarded_a = mem_forward_data;
            2'b01: forwarded_a = wb_data;
            default: forwarded_a = ex_data1;
        endcase

        case (forward_b)
            2'b10: forwarded_b = mem_forward_data;
            2'b01: forwarded_b = wb_data;
            default: forwarded_b = ex_data2;
        endcase
    end

    ex_stage stage_ex (
        .pc(ex_pc),
        .pc_plus4(ex_pc_plus4),

        .read_data1(forwarded_a),
        .read_data2(forwarded_b),
        .immediate(ex_immediate),

        .opcode(ex_opcode),
        .funct3(ex_funct3),
        .alu_op(ex_alu_op),

        .alu_src(ex_alu_src),
        .branch(ex_branch),
        .jump(ex_jump),

        .alu_result(ex_alu_result),
        .store_data(ex_store_data),
        .pc_target(pc_target),
        .pc_src(pc_src)
    );

    // ==========================================
    // 5. EX/MEM PIPELINE REGISTER
    // ==========================================

    logic [31:0] mem_alu_result;
    logic [31:0] mem_store_data;
    logic [31:0] mem_pc_plus4;

    logic [4:0] mem_rd;
    logic [2:0] mem_funct3;

    logic mem_reg_write;
    logic mem_mem_write;
    logic [1:0] mem_result_src;

    ex_mem_reg reg_ex_mem (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),

        .alu_result_in(ex_alu_result),
        .store_data_in(ex_store_data),
        .pc_plus4_in(ex_pc_plus4),

        .rd_in(ex_rd),
        .funct3_in(ex_funct3),

        .reg_write_in(ex_reg_write),
        .mem_write_in(ex_mem_write),
        .result_src_in(ex_result_src),

        .alu_result_out(mem_alu_result),
        .store_data_out(mem_store_data),
        .pc_plus4_out(mem_pc_plus4),

        .rd_out(mem_rd),
        .funct3_out(mem_funct3),

        .reg_write_out(mem_reg_write),
        .mem_write_out(mem_mem_write),
        .result_src_out(mem_result_src)
    );

    // ==========================================
    // 6. MEMORY (MEM)
    // ==========================================

    logic [31:0] mem_read_data;

    mem_stage stage_mem (
        .clk(clk),
        .reset(reset),

        .mem_write(mem_mem_write),
        .funct3(mem_funct3),
        .alu_result(mem_alu_result),
        .store_data(mem_store_data),

        .memory_data(mem_read_data)
    );

    // ==========================================
    // 7. MEM/WB PIPELINE REGISTER
    // ==========================================

    logic [31:0] wb_alu_result;
    logic [31:0] wb_memory_data;
    logic [31:0] wb_pc_plus4;

    logic [4:0] wb_pipeline_rd;
    logic wb_pipeline_reg_write;
    logic [1:0] wb_result_src;

    mem_wb_reg reg_mem_wb (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),

        .alu_result_in(mem_alu_result),
        .memory_data_in(mem_read_data),
        .pc_plus4_in(mem_pc_plus4),

        .rd_in(mem_rd),
        .reg_write_in(mem_reg_write),
        .result_src_in(mem_result_src),

        .alu_result_out(wb_alu_result),
        .memory_data_out(wb_memory_data),
        .pc_plus4_out(wb_pc_plus4),

        .rd_out(wb_pipeline_rd),
        .reg_write_out(wb_pipeline_reg_write),
        .result_src_out(wb_result_src)
    );

    // ==========================================
    // 8. WRITEBACK (WB)
    // ==========================================

    wb_stage stage_wb (
        .reset(reset),

        .alu_result(wb_alu_result),
        .memory_data(wb_memory_data),
        .pc_plus4(wb_pc_plus4),

        .rd(wb_pipeline_rd),
        .reg_write(wb_pipeline_reg_write),
        .result_src(wb_result_src),

        .wb_data(wb_data),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write)
    );

endmodule
