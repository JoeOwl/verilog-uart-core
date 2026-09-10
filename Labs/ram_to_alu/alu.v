module alu #(
    parameter WIDTH = 8
)(
    input      [WIDTH-1:0] in_a,
    input      [WIDTH-1:0] in_b,
    input      [2:0]       opcode,
    input                  alu_en,
    output reg [WIDTH-1:0] alu_out,
    output                 a_is_zero
);
    always @(*) begin
        if (!alu_en) begin
            alu_out = 0;
        end
        else begin
            case (opcode)
                3'b000: alu_out = in_a + in_b;   // ADD
                3'b001: alu_out = in_a - in_b;   // SUB
                3'b010: alu_out = in_a & in_b;   // AND
                3'b011: alu_out = in_a ^ in_b;   // XOR
                3'b100: alu_out = in_a | in_b;   // OR
                3'b101: alu_out = in_a;          // OUT A
                default: alu_out = 0;            // 110, 111 -> no operation
            endcase
        end
    end

    assign a_is_zero = ~|in_a;
endmodule
