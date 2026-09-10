module gr2bin (input [3:0] in,output [3:0] bin_out);
    assign bin_out[3] = in[3];
    assign bin_out[2] = bin_out[3] ^ in[2];
    assign bin_out[1] = bin_out[2] ^ in[1];
    assign bin_out[0] = bin_out[1] ^ in[0];
endmodule
 
 
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
 
 
module gr_to_seg7 (
    input  [3:0] grey_in,
    output [6:0] seg
);
    wire [3:0] bin;

    gr2bin gray2bin0 (.in (grey_in), .bin_out (bin));
    bin_to_7seg u_bin_to_7seg (.bin_in (bin), .segment7_ou (seg));
endmodule

module tb_gr_to_7seg;
    reg [3:0] gray_in;
    wire [6:0] segout;

    gr_to_seg7 dut (.grey_in (gray_in), .seg (segout));

    task grey_checker;
        input [3:0] g;
        begin
            gray_in = g;
            #10;
            $display("gray_in = %b | bin (via dut) = %b | seg_out = %b (hex digit %h)",
                      gray_in, dut.bin, segout, dut.bin);
        end
    endtask

    integer i;
    initial begin
        $monitor("%0t\t%b\t%b", $time, gray_in, segout);
        for (i = 0; i < 16; i = i + 1)
            grey_checker(i[3:0]);
        $display("complete");
        $stop;
    end
endmodule