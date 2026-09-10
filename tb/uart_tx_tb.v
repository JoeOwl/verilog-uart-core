module uart_tx_tb;
 
    reg clk;
    reg arst_n;
    reg rst;
    reg tx_en;
    reg [7:0] tx_data;
    reg [31:0] baudiv;
    wire tx;
    wire tx_busy;
    wire tx_done;
 
    localparam BIT_PERIOD_NS = 100;
 
    uart_tx dut (
        .clk (clk),
        .arst_n (arst_n),
        .rst (rst),
        .tx_en (tx_en),
        .tx_data (tx_data),
        .baudiv (baudiv),
        .tx (tx),
        .tx_busy (tx_busy),
        .tx_done (tx_done)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    time bit_time;
    initial bit_time = (baudiv * 10.0);
 
    initial begin
        arst_n = 1;
        rst = 0;
        tx_en = 0;
        tx_data = 0;
        baudiv  = 32'd10; // Small for simulation speed
 
        // Apply async reset
        apply_async_reset;
 
        // 1. Send one frame
        apply_sync_reset;
        #100;
        send_frame(8'h00);
 
        apply_sync_reset;
        #500;
        send_frame(8'h81);
 
        #500;
        apply_sync_reset;
        send_frame(8'hAA);
 
        // send multiple frames
        apply_sync_reset;
        send_frame(8'hA0);
        send_frame(8'hB1);
        send_frame(8'hC2);
 
        // Send a frame but apply synchronous reset in the middle
        fork
            // Task 1: Trigger UART send
            begin
                apply_sync_reset;
                send_frame(8'hE2);
            end
 
            // Task 2: Wait into the middle of the frame, then apply reset
            begin
                #( (baudiv * 5) * 10 ); // wait ~3 bit periods
                apply_sync_reset;
            end
        join
 
        #1000;
        $finish;
    end
 
    // Tasks 
    // Asynchronous reset
    task apply_async_reset;
        begin
            arst_n = 0;
            #(3*10); // 3 cycles
            arst_n = 1;
            @(posedge clk);
        end
    endtask
 
    // Synchronous reset
    task apply_sync_reset;
        begin
            rst = 1;
            #200;
            @(posedge clk);
            rst = 0;
        end
    endtask
 
    // Send a single frame and check it with the RX monitor task in parallel
    task send_frame(input [7:0] byte);
        begin
            tx_data = byte;
            tx_en   = 1;
            fork
                begin
                    @(posedge clk);
                    wait(tx_busy == 0);
                    tx_en = 0;
                end
                uart_rx_mon(byte);
            join
            @(posedge clk);   // let tx_en=0 actually get sampled before the next send_frame
        end
    endtask
 
    // Send multiple frames back-to-back
    task send_multiple_frames(input [7:0] b0, input [7:0] b1, input [7:0] b2);
        begin
            send_frame(b0);
            send_frame(b1);
            send_frame(b2);
        end
    endtask
 
    task uart_rx_mon(input [7:0] expected_byte);
        reg [7:0] rx_shift;
        integer   i;
        begin
            // Wait for start bit
            @(negedge tx);
            $display("[%0t] FOUND A START CONDITION", $time);
            // Wait to sample in the middle of the start bit
            #(BIT_PERIOD_NS/2.0);
            // Check start bit still low
            if (tx !== 0) begin
                $display("[%0t] ERROR: Start bit invalid!", $time);
            end
            // Sample 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                #(BIT_PERIOD_NS);
                rx_shift[i] = tx;
            end
            // Sample stop bit
            #(BIT_PERIOD_NS);
            if (tx !== 1) begin
                $display("[%0t] ERROR: Stop bit invalid!", $time);
            end
            // Compare with expected byte
            if (rx_shift !== expected_byte) begin
                $display("[%0t] ERROR: RX mismatch! Expected 0x%02h, got 0x%02h",
                         $time, expected_byte, rx_shift);
            end else begin
                $display("[%0t] INFO: RX OK: 0x%02h", $time, rx_shift);
            end
        end
    endtask
 
endmodule