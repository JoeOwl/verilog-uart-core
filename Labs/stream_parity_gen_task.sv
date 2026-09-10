module stream_parity_gen_task (input clk,reset,serial_in,
    output reg parity_out);
 
    reg [7:0] shift_reg;
    reg [7:0] next_window;
    reg par_result;
 
    task cal_par;
        input  [7:0] data;
        output parity;
        begin
            parity = ^data;
        end
    endtask
 
    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 0;
            parity_out <= 0;
        end
        else begin
            next_window = {shift_reg[6:0], serial_in};
            cal_par(next_window, par_result);
 
            shift_reg <= next_window;
            parity_out <= par_result;
        end
    end
 
endmodule

module tb_stream_parity_gen_task;
 
    reg clk;
    reg reset;
    reg serial_in;
    wire parity_out;
 
    reg [7:0] test_byte;
    reg [7:0] window;
    reg expectd_par;
 
    integer i;
 
    stream_parity_gen dut (
        .clk (clk),
        .reset (reset),
        .serial_in (serial_in),
        .parity_out (parity_out)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        reset = 1;
        serial_in = 0;
        window = 0;
 
        @(negedge clk);
        @(negedge clk);
        reset = 0;
 
        test_byte = 8'b10110110;
        for (i = 7; i >= 0; i = i - 1) begin
            serial_in = test_byte[i];
            window = {window[6:0], test_byte[i]};
            expectd_par = ^window;
            @(posedge clk);
            #1;
            if (parity_out == expectd_par)
                $display("Success: bit=%b window=%b expected=%b got=%b",
                          test_byte[i], window, expectd_par, parity_out);
            else
                $display("FAIL: bit=%b window=%b expected=%b got=%b",
                          test_byte[i], window, expectd_par, parity_out);
        end
 
        $display("Test complete.");
        $stop;
    end
 
endmodule