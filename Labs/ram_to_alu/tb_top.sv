`timescale 1ns/1ps

module tb_top;

    localparam CLK_PERIOD = 10;
    localparam ADDR_WIDTH = 8;
    localparam DATA_WIDTH = 20;
    localparam ALU_WIDTH  = 8;

    reg                   clk;
    reg                   rst_n;
    reg                   wr_en;
    reg  [ADDR_WIDTH-1:0] wr_addr;
    reg  [DATA_WIDTH-1:0] din;
    wire [ALU_WIDTH-1:0]  alu_out;
    wire                  a_is_zero;

    reg  [ALU_WIDTH-1:0]  expected_out;
    reg                   expected_zero;

    top #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ALU_WIDTH  (ALU_WIDTH)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (wr_en),
        .wr_addr   (wr_addr),
        .din       (din),
        .alu_out   (alu_out),
        .a_is_zero (a_is_zero)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // Synchronization note:
    // PISO does not load-once-and-hold. As soon as one word finishes
    // shifting out (20 cycles), it loops straight back to S_FETCH and
    // re-reads/re-shifts the same RAM address again. SIPO's parallel_out
    // is therefore only stable for a few cycles right after u_piso.valid
    // falls -- after that it's mid-shift again on the next reload. Rather
    // than guessing a fixed cycle count (fragile, and wrong -- see below),
    // sample right on the falling edge of u_piso.valid, which reliably
    // marks "a full 20-bit word has just landed in SIPO."
    //
    // For a write issued mid-stream (tests 2/3), the *next* valid-falling
    // edge might still belong to a load that already latched the OLD data
    // out of RAM before the write landed. Waiting for the falling edge
    // TWICE guarantees the second one corresponds to a fetch that started
    // strictly after the write, so it reflects the new data.

    initial begin
        clk     = 0;
        rst_n   = 0;
        wr_en   = 0;
        wr_addr = 0;
        din     = 0;

        @(negedge clk);
        @(negedge clk);

        // -----------------------------------------------------------
        // Test 1: ADD, in_a = 10, in_b = 5, alu_en = 1
        // expected: alu_out = 15, a_is_zero = 0
        // -----------------------------------------------------------
        wr_addr       = 8'd0;
        din           = {1'b1, 3'b000, 8'd10, 8'd5};
        expected_out  = 8'd15;
        expected_zero = 1'b0;
        wr_en = 1;
        rst_n = 1;                 // release reset and write on the same edge
        @(negedge clk);
        wr_en = 0;

        // write lands before the very first fetch -> one completed word is enough
        @(negedge dut.u_piso.valid);
        @(negedge clk);            // small settle margin before sampling

        if (alu_out !== expected_out || a_is_zero !== expected_zero) begin
            $display("FAIL Test1: alu_out=%0d (exp %0d) a_is_zero=%0b (exp %0b)",
                       alu_out, expected_out, a_is_zero, expected_zero);
            $stop;
        end
        else
            $display("PASS Test1: alu_out=%0d a_is_zero=%0b", alu_out, a_is_zero);

        // -----------------------------------------------------------
        // Test 2: SUB, in_a = 20, in_b = 12, alu_en = 1
        // expected: alu_out = 8, a_is_zero = 0
        // -----------------------------------------------------------
        wr_addr       = 8'd0;
        din           = {1'b1, 3'b001, 8'd20, 8'd12};
        expected_out  = 8'd8;
        expected_zero = 1'b0;
        wr_en = 1;
        @(negedge clk);
        wr_en = 0;

        // write lands mid-stream -> the very next completed word may still
        // be the old one already in flight, so wait for a second one
        repeat (2) @(negedge dut.u_piso.valid);
        @(negedge clk);

        if (alu_out !== expected_out || a_is_zero !== expected_zero) begin
            $display("FAIL Test2: alu_out=%0d (exp %0d) a_is_zero=%0b (exp %0b)",
                       alu_out, expected_out, a_is_zero, expected_zero);
            $stop;
        end
        else
            $display("PASS Test2: alu_out=%0d a_is_zero=%0b", alu_out, a_is_zero);

        // -----------------------------------------------------------
        // Test 3: alu_en = 0 -> alu_out forced to 0
        //         in_a  = 0 -> a_is_zero = 1 (independent of alu_en/opcode)
        // -----------------------------------------------------------
        wr_addr       = 8'd0;
        din           = {1'b0, 3'b000, 8'd0, 8'd7};
        expected_out  = 8'd0;
        expected_zero = 1'b1;
        wr_en = 1;
        @(negedge clk);
        wr_en = 0;

        repeat (2) @(negedge dut.u_piso.valid);
        @(negedge clk);

        if (alu_out !== expected_out || a_is_zero !== expected_zero) begin
            $display("FAIL Test3: alu_out=%0d (exp %0d) a_is_zero=%0b (exp %0b)",
                       alu_out, expected_out, a_is_zero, expected_zero);
            $stop;
        end
        else
            $display("PASS Test3: alu_out=%0d a_is_zero=%0b", alu_out, a_is_zero);

        $display("All tests completed.");
        $stop;
    end

endmodule