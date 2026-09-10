module uart_rx (
    input clk,
    input arst_n,
    input rst,
    input rx_en,
    input [31:0] baudiv,
    input rx,

    output rx_busy,
    output rx_done,
    output rx_err,
    output reg [7:0] rx_data);

    // State encoding
    localparam [2:0] IDLE = 0,
                     START = 1,
                     DATA = 2,
                     STOP = 3,
                     DONE = 4,
                     ERR = 5;

    reg [2:0] state, next_state;
    reg [2:0] bit_idx;

    // Baud Counter
    reg [31:0] baud_cnt;
    wire baud_done = (baud_cnt == 0);
    reg baud_load;
    reg [31:0] baud_val;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            baud_cnt <= 0;
        else if (rst)
            baud_cnt <= 0;
        else if (baud_load)
            baud_cnt <= baud_val;
        else if (baud_cnt != 0)
            baud_cnt <= baud_cnt - 1;
    end

    // Synchronizer + Edge Detector (via Edge_detector instance)
    reg rx_d1, rx_d2;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rx_d1 <= 1;
            rx_d2 <= 1;
        end else begin
            rx_d1 <= rx;
            rx_d2 <= rx_d1;
        end
    end

    wire ed_Y0;

    Edge_detector u_edge_detector (
        .clk (clk),
        .rst_n (arst_n & ~rst), // reset-folding
        .a (~rx_d1),
        .b (~rx_d2),
        .Y0 (ed_Y0)
    );

    wire falling_edge = ed_Y0;

    // FSM Next-state logic
    reg sipo_en;

    always @(*) begin
        next_state = state;
        baud_load = 0;
        baud_val = 0;
        sipo_en = 0;

        case (state)
            IDLE: begin
                if (rx_en && falling_edge) begin
                    baud_load = 1;
                    baud_val = (baudiv >> 1); // half bit for start center
                    next_state = START;
                end
            end

            START: begin
                if (baud_done) begin
                    if (!rx) begin
                        baud_load = 1;
                        baud_val = baudiv - 1;
                        next_state = DATA;
                    end else begin
                        next_state = IDLE; // false start
                    end
                end
            end

            DATA: begin
                if (baud_done) begin
                    sipo_en = 1;
                    baud_load = 1;
                    baud_val = baudiv - 1;
                    if (bit_idx == 7)
                        next_state = STOP;
                end
            end

            STOP: begin
                if (baud_done) begin
                    if (rx == 1)
                        next_state = DONE;
                    else
                        next_state = ERR;
                end
            end

            DONE: next_state = DONE; // stay until reset
            ERR: next_state = ERR;  // stay until reset
        endcase
    end

    // FSM State register
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            state <= IDLE;
        else if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // SIPO (via serial_to_parallel instance)
    wire [7:0] sipo_parallel_out;
    wire sipo_shift_en = (state == DATA) && sipo_en;

    serial_to_parallel #(
        .WIDTH (8)
    ) u_sipo (
        .clk (clk),
        .rst_n (arst_n & ~rst),  // reset-folding
        .shift_en     (sipo_shift_en),
        .serial_in    (rx),
        .parallel_out (sipo_parallel_out)
    );

    wire [7:0] sipo;
    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : bit_reverse
            assign sipo[gi] = sipo_parallel_out[7-gi];
        end
    endgenerate

    // Outputs
    assign rx_busy = (state != IDLE);
    assign rx_done = (state == DONE);
    assign rx_err  = (state == ERR);

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rx_data <= 0;
            bit_idx <= 0;
        end
        else if (rst) begin
            rx_data <= 0;
            bit_idx <= 0;
        end
        else if (state == DONE)
            rx_data <= sipo;
        else if (state == DATA && baud_done && sipo_en)
            bit_idx <= bit_idx + 1;
        else if (state == IDLE)
            bit_idx <= 0;
end

endmodule