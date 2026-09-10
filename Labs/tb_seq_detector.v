module tb_seq_detector;

    reg clk = 0;
    reg rst = 1;
    reg in_bit = 0;

    wire hit_overlap, hit_nonoverlap;

    seq_detector_overlap    dut_ov  (.clk(clk), .rst(rst), .in_bit(in_bit), .detected(hit_overlap));
    seq_detector_nonoverlap dut_nov (.clk(clk), .rst(rst), .in_bit(in_bit), .detected(hit_nonoverlap));

    always #5 clk = ~clk;

    // Sequence: 1 1 0 1 0 1 1 0 1 0 1
    // Bit 6 completes the first "110101"
    // Bits 6-11 produce "110101" (sharing bit 6), overlap should fire twice
    reg [10:0] stream = 11'b110101_10101; // MSB first, drain from bit 10 down to 0
    integer i;

    initial begin
        $display(" time | bit | overlap | nonoverlap");
        @(negedge clk); rst = 0;

        for (i = 10; i >= 0; i = i - 1) begin
            in_bit = stream[i];
            #1;
            $display(" %4t| %b | %b | %b", $time, in_bit, hit_overlap, hit_nonoverlap);
            @(posedge clk);
        end

        $finish;
    end

endmodule
