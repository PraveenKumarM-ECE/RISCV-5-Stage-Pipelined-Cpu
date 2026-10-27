module data_memory (
    input  logic        clk,
    input  logic        mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data,
    input  logic [2:0]  funct3
);

    logic [31:0] memory [0:255];

    logic [31:0] word_data;
    logic [7:0] byte_data;
    logic [15:0] half_data;

    logic [1:0] byte_offset_reg;
    logic [2:0] funct3_reg;

    logic [3:0] byte_enable;
    logic [31:0] aligned_write_data;

    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'd0;
    end

    always @(*) begin
        byte_enable = 4'b0000;
        aligned_write_data = 32'd0;

        if (mem_write) begin
            case (funct3)
                3'b000: begin
                    byte_enable = 4'b0001 << address[1:0];
                    aligned_write_data =
                        {24'd0, write_data[7:0]} << (8 * address[1:0]);
                end

                3'b001: begin
                    byte_enable = address[1] ? 4'b1100 : 4'b0011;
                    aligned_write_data =
                        {16'd0, write_data[15:0]} << (16 * address[1]);
                end

                3'b010: begin
                    byte_enable = 4'b1111;
                    aligned_write_data = write_data;
                end

                default: begin
                    byte_enable = 4'b0000;
                    aligned_write_data = 32'd0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (byte_enable[0])
            memory[address[9:2]][7:0] <= aligned_write_data[7:0];

        if (byte_enable[1])
            memory[address[9:2]][15:8] <= aligned_write_data[15:8];

        if (byte_enable[2])
            memory[address[9:2]][23:16] <= aligned_write_data[23:16];

        if (byte_enable[3])
            memory[address[9:2]][31:24] <= aligned_write_data[31:24];

        word_data <= memory[address[9:2]];

        byte_offset_reg <= address[1:0];
        funct3_reg <= funct3;
    end

    always @(*) begin
        case (byte_offset_reg)
            2'b00: byte_data = word_data[7:0];
            2'b01: byte_data = word_data[15:8];
            2'b10: byte_data = word_data[23:16];
            2'b11: byte_data = word_data[31:24];
        endcase
    end

    assign half_data =
        byte_offset_reg[1] ? word_data[31:16] : word_data[15:0];

    always @(*) begin
        case (funct3_reg)
            3'b000: read_data = {{24{byte_data[7]}}, byte_data};
            3'b001: read_data = {{16{half_data[15]}}, half_data};
            3'b010: read_data = word_data;
            3'b100: read_data = {24'd0, byte_data};
            3'b101: read_data = {16'd0, half_data};
            default: read_data = 32'd0;
        endcase
    end

endmodule
