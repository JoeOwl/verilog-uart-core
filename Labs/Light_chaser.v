module clock_divider #(
    parameter CLK_FREQ = 100_000_000,
    parameter OUT_FREQ = 5
    )(
    input clk,
    input rst_n,
    output tick
    );
 
    localparam DIV_MAX = CLK_FREQ / OUT_FREQ;
    localparam CNT_W = $clog2(DIV_MAX);
 
    reg [CNT_W-1:0] div_cnt;
 
    assign tick = (div_cnt == DIV_MAX - 1);
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            div_cnt <= 0;
        else if (tick)
            div_cnt <= 0;
        else
            div_cnt <= div_cnt + 1;
    end
 
endmodule

module light_chaser (
    input clk,
    input rst_n,
    input tick,
    input dir,
    output reg [9:0] leds
);
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            leds <= 10'b1;
        else if (tick) begin
            if (dir)
                leds <= {leds[0], leds[9:1]};   // rotate right
            else
                leds <= {leds[8:0], leds[9]};   // rotate left
        end
    end
 
endmodule
 
 module light_chaser_top #(
    parameter integer CLK_FREQ   = 100_000_000, // board clock frequency (Hz)
    parameter integer CHASE_FREQ = 5             // LED step rate (Hz)
)(
    input clk,
    input rst_n,
    input dir,
    output [9:0] leds
);
 
    wire tick;
 
    clock_divider #(
        .CLK_FREQ (CLK_FREQ),
        .OUT_FREQ (CHASE_FREQ)) u_clock_divider (
        .clk (clk),
        .rst_n (rst_n),
        .tick (tick)
    );
 
    light_chaser u_light_chaser (
        .clk (clk),
        .rst_n(rst_n),
        .tick (tick),
        .dir (dir),
        .leds (leds));
 
endmodule

module light_chaser_tb;
 
    reg clk;
    reg rst_n;
    reg dir;
    wire [9:0] leds;

    light_chaser_top #(
        .CLK_FREQ (1000),
        .CHASE_FREQ (100)
    ) dut (
        .clk (clk),
        .rst_n (rst_n),
        .dir (dir),
        .leds (leds));
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        $monitor("t=%0t rst_n=%b dir=%b leds=%b", $time, rst_n, dir, leds);
        rst_n = 0;
        dir = 0;
        #23 rst_n = 1;
 
        repeat (25) @(posedge clk);
 
        dir = 1;
        repeat (25) @(posedge clk);
        $stop;
    end
 
endmodule