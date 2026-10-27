module data_memory_bram (
    input  logic        clk,
    input  logic        read_enable,
    input  logic [3:0]  write_enable,
    input  logic [7:0]  address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [31:0] memory [0:255];

    always @(posedge clk) begin

        if (write_enable[0])
            memory[address][7:0] <= write_data[7:0];

        if (write_enable[1])
            memory[address][15:8] <= write_data[15:8];

        if (write_enable[2])
            memory[address][23:16] <= write_data[23:16];

        if (write_enable[3])
            memory[address][31:24] <= write_data[31:24];

        if (read_enable)
            read_data <= memory[address];

    end

endmodule
