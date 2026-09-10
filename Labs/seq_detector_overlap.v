module seq_detector_overlap (
    input clk,
    input rst,
    input in_bit,
    output reg detected);

    localparam [2:0] S0 = 0,
                    S1 = 1,
                    S2 = 2,
                    S3 = 3,
                    S4 = 4,
                    S5 = 5,
                    S6 = 6;

    reg [2:0] state, next_state;

    // State register
    always @(posedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    // Next-state and Mealy output logic
    always @(*) begin
        next_state = S0;
        detected = 0;

        case (state)
            S0: next_state = in_bit ? S1 : S0;
            S1: next_state = in_bit ? S2 : S0;
            S2: next_state = in_bit ? S2 : S3;
            S3: next_state = in_bit ? S4 : S0;
            S4: next_state = in_bit ? S2 : S5;
            S5: begin
                if (in_bit) begin
                    next_state = S6;
                    detected = 1;
                end else begin
                    next_state = S0;
                end
            end
            S6: next_state = in_bit ? S2 : S0;
            default: next_state = S0;
        endcase
    end

endmodule
