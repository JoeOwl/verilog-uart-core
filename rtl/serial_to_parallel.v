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

