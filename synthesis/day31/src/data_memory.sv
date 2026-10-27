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
    logic [7:0]  byte_data;
    logic [15:0] half_data;

    logic [7:0]  write_byte;
    logic [15:0] write_half;

    logic [1:0] byte_offset;

    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'd0;
    end

    assign byte_offset = address[1:0];

    assign word_data = memory[address[9:2]];

    // Select one byte from the 32-bit word
    always @(*) begin
        case (byte_offset)
            2'b00: byte_data = word_data[7:0];
            2'b01: byte_data = word_data[15:8];
            2'b10: byte_data = word_data[23:16];
            2'b11: byte_data = word_data[31:24];
        endcase
    end

    // Select one 16-bit halfword
    assign half_data =
        byte_offset[1] ? word_data[31:16] : word_data[15:0];

    // Load operations
    always @(*) begin
        case (funct3)
            3'b000: read_data = {{24{byte_data[7]}}, byte_data}; // LB
            3'b001: read_data = {{16{half_data[15]}}, half_data}; // LH
            3'b010: read_data = word_data;                       // LW
            3'b100: read_data = {24'd0, byte_data};              // LBU
            3'b101: read_data = {16'd0, half_data};              // LHU
            default: read_data = 32'd0;
        endcase
    end

    assign write_byte = write_data[7:0];
    assign write_half = write_data[15:0];

    // Store operations
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                // SB
                3'b000: begin
                    case (byte_offset)
                        2'b00: memory[address[9:2]][7:0]   <= write_byte;
                        2'b01: memory[address[9:2]][15:8]  <= write_byte;
                        2'b10: memory[address[9:2]][23:16] <= write_byte;
                        2'b11: memory[address[9:2]][31:24] <= write_byte;
                    endcase
                end

                // SH
                3'b001: begin
                    if (byte_offset[1])
                        memory[address[9:2]][31:16] <= write_half;
                    else
                        memory[address[9:2]][15:0] <= write_half;
                end

                // SW
                3'b010: begin
                    memory[address[9:2]] <= write_data;
                end
            endcase
        end
    end

endmodule
