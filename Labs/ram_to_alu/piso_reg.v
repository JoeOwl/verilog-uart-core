module piso_reg #(
    parameter WIDTH      = 20,
    parameter ADDR_WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input      [WIDTH-1:0]  parallel_in,
    output reg              en,
    output reg              serial_out,
    output reg              valid
);
    localparam S_FETCH = 2'd0;
    localparam S_WAIT  = 2'd1;
    localparam S_LOAD  = 2'd2;
    localparam S_SHIFT = 2'd3;

    reg [1:0]                state;
    reg [WIDTH-1:0]           shift_reg;
    reg [$clog2(WIDTH)-1:0]   bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_FETCH;
            en         <= 0;
            serial_out <= 0;
            valid      <= 0;
            shift_reg  <= 0;
            bit_cnt    <= 0;
        end
        else begin
            case (state)
                S_FETCH: begin
                    en         <= 1;
                    serial_out <= 0;
                    valid      <= 0;
                    state      <= S_WAIT;
                end
                S_WAIT: begin
                    en    <= 0;
                    state <= S_LOAD;
                end
                S_LOAD: begin
                    shift_reg <= parallel_in;
                    bit_cnt   <= 0;
                    state     <= S_SHIFT;
                end
                S_SHIFT: begin
                    valid      <= 1;
                    serial_out <= shift_reg[WIDTH-1];
                    shift_reg  <= {shift_reg[WIDTH-2:0], 1'b0};
                    bit_cnt    <= bit_cnt + 1'b1;
                    if (bit_cnt == WIDTH-1)
                        state <= S_FETCH;
                end
                default: state <= S_FETCH;
            endcase
        end
    end
endmodule
