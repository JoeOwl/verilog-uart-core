module uart_tx (
    input clk,
    input arst_n,
    input rst,
    input tx_en,
    input [7:0] tx_data,
    input [31:0] baudiv,
    
    output reg tx,
    output tx_busy,
    output tx_done);


    reg [31:0] counter;
    reg [3:0] bit_num;
    reg [0:9] frame;
    reg [7:0] data_rev;

    integer i;

    always@(*)
        begin
            for (i=0; i < 8; i=i+1) begin 
                data_rev[7-i] = tx_data[i]; 
            end
        end

    always @(posedge clk or negedge arst_n)
        begin
            if(!arst_n)
                begin
                    counter <= 0;
                    bit_num <= 0;
                    tx <= 0;
                    frame <= 0;
                end
            else if (rst)
                begin
                    counter <= 0;
                    bit_num <= 0;
                    tx <= 1;
                    frame <= 0;
                end
            else if (!tx_en)
                begin
                    counter <= 0;
                    bit_num <= 0;
                    tx <= 1;
                    frame <= {1'b0, data_rev, 1'b1};
                end
            else if (counter == baudiv-1 & bit_num != 9)
                begin
                    counter <= 0;
                    bit_num <= bit_num + 1;
                    frame <= {1'b0, data_rev, 1'b1};
                end
            else if (counter == baudiv-1)
                begin
                    counter <= counter;
                end
            else if (tx_en)
                begin
                    counter <= counter + 1;
                    tx <= frame[bit_num];
                    frame <= {1'b0, data_rev, 1'b1};
                end
        end   

    assign tx_busy = !(bit_num == 9 & counter == baudiv-1);
    assign tx_done = (bit_num == 9 & counter == baudiv-1); 

endmodule : uart_tx