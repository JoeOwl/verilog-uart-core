module bin_to_7seg (input [3:0] bin_in,output reg  [6:0] segment7_ou);
    always @(*) 
        begin
            case (bin_in)
                            //gfedcba
            0: segment7_ou = ~(7'b1000000); //0
            1: segment7_ou = ~(7'b1111001); //1
            2: segment7_ou = ~(7'b0100100); //2
            3: segment7_ou = ~(7'b0110000); //3
            4: segment7_ou = ~(7'b0011001); //4
            5: segment7_ou = ~(7'b0010010); //5
            6: segment7_ou = ~(7'b0000010); //6
            7: segment7_ou = ~(7'b1111000); //7
            8: segment7_ou = ~(7'b0000000); //8
            9: segment7_ou = ~(7'b0010000); //9
            10: segment7_ou = ~(7'b0001000); //A
            11: segment7_ou = ~(7'b0000011); //B
            12: segment7_ou = ~(7'b1000110); //C
            13: segment7_ou= ~(7'b0100001); //D
            14: segment7_ou = ~(7'b0000110); //E
            15: segment7_ou= ~(7'b0001110); //F
            default: segment7_ou = 7'b1111111; //8
        endcase
    end
endmodule

module clock_divider #(
    parameter CLK_FREQ = 100000000,
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

module top_edge_counter_display #(
    parameter CLK_FREQ = 100000000,
    parameter OUT_FREQ = 1000)
    (
    input clk,
    input rst_n,
    input a,
    input b,
    output [6:0] seg
    );
 
    wire tick;
    clock_divider #(
        .CLK_FREQ (CLK_FREQ),
        .OUT_FREQ (OUT_FREQ)
    ) u_clkdiv (
        .clk (clk),
        .rst_n (rst_n),
        .tick (tick)
    );
 
    reg slow_clk;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            slow_clk <= 1'b0;
        else if (tick)
            slow_clk <= ~slow_clk;
    end
 
    wire edge_pulse;
    wire y1_status;
 
    Edge_detector u_edge (
        .clk (slow_clk),
        .rst_n (rst_n),
        .a (a),
        .b (b),
        .Y0 (edge_pulse),
        .Y1 (y1_status)
    );
 
    reg [3:0] edge_count;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            edge_count <= 0;
        else if (edge_pulse)
            edge_count <= edge_count + 1;
    end
 
    bin_to_7seg u_seg (
        .bin_in (edge_count),
        .segment7_ou (seg)
    );
 
endmodule