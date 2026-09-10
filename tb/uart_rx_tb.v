module uart_rx_tb;
    parameter CLKPER = 10 ;

    reg clk;
    reg arst_n;
    reg rst;

    reg rx_en;
    reg rx;
    reg [31:0] baudiv;
    wire rx_busy;
    wire rx_done;
    wire rx_err;
    wire [7:0] rx_data;

    uart_rx dut (
        .clk (clk),
        .arst_n (arst_n),
        .rst (rst),
        .rx_en (rx_en),
        .baudiv (baudiv),
        .rx (rx),
        .rx_busy (rx_busy),
        .rx_done (rx_done),
        .rx_err (rx_err),
        .rx_data (rx_data));

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLKPER/2) clk = ~clk;
    end

    // Reset tasks
    task apply_async_reset;
        begin
            arst_n = 0;
            #(3*10); // 3 cycles
            arst_n = 1;
            @(posedge clk);
        end
    endtask

    task apply_sync_reset;
        begin
            rst = 1;
            #200;
            @(posedge clk);
            rst = 0;
        end
    endtask

    // UART bit-bang task
    task uart_tx_driver(input [7:0] tx_data, input integer bit_time);
    integer i;
    begin
        // START bit
        rx = 1'b0;
        #(bit_time);

        // DATA bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx = tx_data[i];
            #(bit_time);
        end

        // STOP bit
        rx = 1'b1;
        #(bit_time);

        // Idle (gap between frames)
        #(bit_time);
        $display("TX sent 0x%0H" , tx_data);
    end
    endtask

    // Transmit a byte but corrupt the STOP bit (framing error)
    task uart_tx_driver_bad_stop(input [7:0] tx_data, input integer bit_time);
        integer i;
        begin
            // START bit
            rx = 1'b0;
            #(bit_time);

            // DATA bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = tx_data[i];
                #(bit_time);
            end

            // BAD STOP bit (should be 1, we drive 0 instead)
            rx = 1'b0;
            #(bit_time);

            // Return to idle high
            rx = 1'b1;
            #(bit_time);
        end
    endtask

    // Inject a short low glitch on the RX line (false start candidate)
    task uart_tx_glitch(input integer bit_time);
    begin
        // Line idle high initially
        rx = 1'b1;

        // Short low pulse (less than half bit_time, so not a valid start)
        rx = 1'b0;
        #(bit_time/4);   // quarter of a bit time

        // Back to idle
        rx = 1'b1;
        #(bit_time);     // leave some gap before next event
    end
    endtask

    // Checker task
    task check_expect_data(input [7:0] exp_data, input exp_err);
        begin
            wait (rx_done || rx_err);
            @(posedge clk);

            if (rx_done && !exp_err) begin
                if (rx_data !== exp_data) begin
                    $display("[%0t] ERROR: expected 0x%0h got 0x%0h", $time, exp_data, rx_data);
                end else begin
                    $display("[%0t] PASS: received 0x%0h", $time, rx_data);
                end
            end else if (rx_err && exp_err) begin
                $display("[%0t] PASS: framing error detected", $time);
            end else begin
                $display("[%0t] FAIL: wrong RX status. rx_done=%b rx_err=%b", $time, rx_done, rx_err);
            end
        end
    endtask

    // Stimulus
    initial begin
        rx = 1'b1;   // idle
        rx_en = 0;
        arst_n = 1;
        rst = 0;
        baudiv = 10;  

    
        // 1) Apply resets
        apply_async_reset;
        apply_sync_reset;
    
        // 2) Enable RX
        rx_en = 1;
    
        // Test 1: Normal frame
        $display("\n[TEST 1] Normal UART RX");
        uart_tx_driver(8'h3C, baudiv*CLKPER);   // send 0x3C
        check_expect_data(8'h3C, 0);       // expect 0x3C, no error
    
        // Reset after transaction
        apply_sync_reset;

        uart_tx_driver(8'h00, baudiv*CLKPER);   
        check_expect_data(8'h00, 0);       
    
        // Reset after transaction
        apply_sync_reset;


        uart_tx_driver(8'h81, baudiv*CLKPER);   
        check_expect_data(8'h81, 0);            
    
        // Reset after transaction
        apply_sync_reset;

        uart_tx_driver(8'hFF, baudiv*CLKPER);   
        check_expect_data(8'hFF, 0);       

        // Reset after transaction
        apply_sync_reset;
    
        // Test 2: Frame with bad stop bit
        $display("\n[TEST 2] Framing error");
        uart_tx_driver_bad_stop(8'hA5, baudiv*CLKPER); // send 0xA5 with bad stop
        check_expect_data(8'hA5, 1);              // expect error flag set
    
        // Reset after transaction
        apply_sync_reset;
    
        // Test 3: Glitch (false start candidate)
        $display("\n[TEST 3] RX glitch injection");
        uart_tx_glitch(baudiv*CLKPER);  // short low pulse
    
        // Check no reception triggered
        @(posedge clk);
        if (rx_done || rx_busy) begin
            $error("Glitch incorrectly triggered reception!");
        end else begin
            $display("Glitch ignored correctly");
        end
    
        // Test 4: Valid frame after glitch
        $display("\n[TEST 4] Normal RX after glitch");
        uart_tx_driver(8'hC3, baudiv*CLKPER);   // send 0xC3
        check_expect_data(8'hC3, 0);       // expect 0xC3, no error
    
        $display("\nAll tests finished");
        $finish;
    end
    
endmodule
