module top #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 20,
    parameter ALU_WIDTH = 8
)(
    input clk,
    input rst_n,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] din,
    output [ALU_WIDTH-1:0] alu_out,
    output a_is_zero
);
    wire [DATA_WIDTH-1:0] ram_dout;
    wire ram_valid;
    wire piso_en;
    wire piso_serial_out;
    wire piso_valid;
    wire [DATA_WIDTH-1:0] sipo_out;

    ram #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_ram (
        .clk (clk),
        .rst_n (rst_n),
        .wr_en (wr_en),
        .addr (wr_addr),
        .din (din),
        .rd_en (piso_en),
        .dout (ram_dout),
        .valid (ram_valid)
    );

    piso_reg #(
        .WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_piso (
        .clk (clk),
        .rst_n (rst_n),
        .parallel_in (ram_dout),
        .en (piso_en),
        .serial_out (piso_serial_out),
        .valid (piso_valid)
    );

    wire alu_en;
    wire [2:0] opcode;
    wire [7:0] in_a;
    wire [7:0] in_b;

    sipo_reg u_sipo (
        .clk (clk),
        .rst_n (rst_n),
        .shift_en (piso_valid),
        .serial_in (piso_serial_out),
        .alu_en(alu_en), 
        .opcode(opcode), 
        .in_a(in_a), 
        .in_b(in_b)
    );
    alu #(
        .WIDTH (ALU_WIDTH)
    ) u_alu (
        .in_a (in_a),
        .in_b (in_b),
        .opcode (opcode),
        .alu_en (alu_en),
        .alu_out (alu_out),
        .a_is_zero (a_is_zero)
    );
endmodule
