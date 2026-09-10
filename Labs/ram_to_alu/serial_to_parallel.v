module decoder (
    input [19:0] in,
    output alu_en,
    output [2:0] opcode,
    output [7:0] in_a,
    output [7:0] in_b
);
    assign {alu_en, opcode, in_a, in_b} = in;
endmodule

module serial_to_parallel #(parameter WIDTH = 20)
    ( 
    input clk,
    input rst_n,
    input shift_en,
    input serial_in,
    output [WIDTH-1:0] parallel_out
    );
    reg [WIDTH-1:0] counter, counter_s;
    reg [WIDTH-1:0] shift_reg, shift_reg_s;
 
    always @(*) begin
        if (shift_en && counter_s != WIDTH) begin
            shift_reg = {shift_reg_s[WIDTH-2:0], serial_in};
            counter = (counter_s == WIDTH-1) ? 'b0 : counter_s + 1'b1;
        end
        else
            begin
            shift_reg = shift_reg_s;
            counter = counter_s;
            end
    end
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_s <= 'b0;
            shift_reg_s <= 'b0;
        end
        else begin
            counter_s <= counter;
            shift_reg_s <= shift_reg;
        end
    end

    assign parallel_out = shift_reg_s;
endmodule

module sipo_reg (
    input clk,
    input rst_n,
    input shift_en,
    input serial_in,
    output alu_en,
    output [2:0] opcode,
    output [7:0] in_a,
    output [7:0] in_b
    );
    wire [19:0] par;
    serial_to_parallel #(.WIDTH(20)) sipo
    ( 
    .clk(clk),
    .rst_n(rst_n),
    .shift_en(shift_en),
    .serial_in(serial_in),
    .parallel_out(par)
    );
    decoder dec(.in(par), .alu_en(alu_en), .opcode(opcode), .in_a(in_a), .in_b(in_b));

endmodule

module tb_top_serial_to_parallel;
 
    reg clk, rst_n, shift_en, serial_in;
    wire alu_en;
    wire [2:0] opcode;
    wire [7:0] in_a, in_b;
 
    integer i;
    reg [19:0] instr;
 
    sipo_reg dut (.clk(clk), .rst_n(rst_n), .shift_en(shift_en), .serial_in(serial_in),
        .alu_en(alu_en), .opcode(opcode), .in_a(in_a), .in_b(in_b));
 
    always #5 clk = ~clk;
 
    initial begin
        clk = 0; rst_n = 0; shift_en = 0; serial_in = 0;
        @(negedge clk) 
        rst_n = 1;
 
        instr = {1'b1, 3'b101, 8'hA5, 8'h3C};
 
        shift_en = 1;
        for (i = 19; i >= 0; i = i - 1) begin
            serial_in = instr[i];
            @(negedge clk);
        end
        shift_en = 0;
 
        if (alu_en !== instr[19])
            $display("ERROR: alu_en mismatch");
        else
            $display("PASS: alu_en");
 
        if (opcode !== instr[18:16])
            $display("ERROR: opcode mismatch");
        else
            $display("PASS: opcode");
 
        if (in_a !== instr[15:8])
            $display("ERROR: in_a mismatch");
        else
            $display("PASS: in_a");
 
        if (in_b !== instr[7:0])
            $display("ERROR: in_b mismatch");
        else
            $display("PASS: in_b");
 
        serial_in = 1'b1; shift_en = 1;
        repeat (3) @(negedge clk);
        shift_en = 0;
        if (in_b !== instr[7:0])
            $display("ERROR: extra shifts corrupted parallel_out");
        else
            $display("PASS: locked after 20 bits, extra shifts ignored");
 
        $display("All tests done.");
        $stop;
    end
 
endmodule

module ALU #(parameter WIDTH = 8)
    (input [WIDTH-1:0] in_a,
    input [WIDTH-1:0] in_b,
    input [2:0] opcode,
    output reg [WIDTH-1:0] alu_out,
    output a_ia_zero);

    always @(*) begin
        case (opcode)
            3'b000: alu_out = in_a;
            3'b001: alu_out = in_a - in_b;
            3'b010: alu_out = in_a + in_b;
            3'b011: alu_out = in_a & in_b;
            3'b100: alu_out = in_a ^ in_b;
            3'b101: alu_out = in_b;
            3'b110: alu_out = in_a;
            3'b111: alu_out = in_a;
            default: alu_out = 3'b000;
        endcase
    end
    assign a_ia_zero = ~|in_a;
endmodule

module top_sipo #(parameter WIDTH = 20)(
    input clk,
    input rst_n,
    input shift_en,
    input serial_in,
    output [7:0] alu_out,
    output a_ia_zero
    );
    wire [19:0] par;
    serial_to_parallel #(.WIDTH(20)) sipo
    ( 
    .clk(clk),
    .rst_n(rst_n),
    .shift_en(shift_en),
    .serial_in(serial_in),
    .parallel_out(par)
    );
    wire [2:0] opcode;
    wire [7:0] in_a, in_b;
    decoder dec(.in(par), .alu_en(alu_en), .opcode(opcode), .in_a(in_a), .in_b(in_b));
    ALU #(.WIDTH(8)) dut (.opcode(opcode), .in_a (in_a), .in_b(in_b), .alu_out(alu_out), .a_ia_zero(a_ia_zero));
endmodule

module tb_top_sipo;
 
    reg clk, rst_n, shift_en, serial_in;
    wire [7:0] alu_out;
    wire a_ia_zero;
 
    integer i, t;
    reg [19:0] test_vec [0:6];
    reg [7:0] exp_out[0:6];
    reg exp_azero [0:6];
    reg [19:0] instr;
 
    top_sipo dut (
        .clk(clk), .rst_n(rst_n), .shift_en(shift_en), .serial_in(serial_in),
        .alu_out(alu_out), .a_ia_zero(a_ia_zero));
 
    always #5 clk = ~clk;
 
    initial begin
        // test_vec = {alu_en, opcode, in_a, in_b}
        test_vec[0]  = {1'b1, 3'b000, 8'h05, 8'h03}; exp_out[0] = 8'h05; exp_azero[0] = 1'b0; 
        test_vec[1]  = {1'b1, 3'b001, 8'h09, 8'h04}; exp_out[1] = 8'h05; exp_azero[1] = 1'b0;
        test_vec[2]  = {1'b1, 3'b010, 8'h0A, 8'h05}; exp_out[2] = 8'h0F; exp_azero[2] = 1'b0;
        test_vec[3]  = {1'b1, 3'b011, 8'hF0, 8'h0F}; exp_out[3] = 8'h00; exp_azero[3] = 1'b0;
        test_vec[4]  = {1'b1, 3'b100, 8'hAA, 8'h55}; exp_out[4] = 8'hFF; exp_azero[4] = 1'b0;
        test_vec[5]  = {1'b1, 3'b101, 8'h11, 8'h22}; exp_out[5] = 8'h22; exp_azero[5] = 1'b0;
        test_vec[6]  = {1'b1, 3'b110, 8'h00, 8'h00}; exp_out[6] = 8'h00; exp_azero[6] = 1'b1;
 
        clk = 0; rst_n = 0; shift_en = 0; serial_in = 0;
        #12 rst_n = 1;
 
        for (t = 0; t < 7; t = t + 1) begin
            instr = test_vec[t];
            shift_en = 1;
            for (i = 19; i >= 0; i = i - 1) begin
                serial_in = instr[i];
                @(negedge clk);
            end
            shift_en = 0;
 
            if (alu_out !== exp_out[t])
                $display("ERROR: test alu_out mismatch");
            else
                $display("PASS: test");
 
            if (a_ia_zero !== exp_azero[t])
                $display("ERROR: test a_ia_zero mismatch");
            else
                $display("PASS: test");
        end
 
        $display("All tests done.");
        $stop;
    end
 
endmodule