module uart_top(
    input clk,
    input arst_n,

    input [31:0] baudiv,

    input tx_rst,
    input tx_en,
    input [7:0] tx_data,
    output tx,
    output tx_busy,
    output tx_done,

    input rx_rst,
    input rx_en,
    input rx,
    output rx_busy,
    output rx_done,
    output rx_err,
    output [7:0] rx_data);

    uart_tx  uart_tx_inst (
        .clk(clk),
        .arst_n(arst_n),
        .rst(tx_rst),
        .tx_en(tx_en),
        .tx_data(tx_data),
        .baudiv(baudiv),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
      );


    uart_rx  uart_rx_i (
        .clk(clk),
        .arst_n(arst_n),
        .rst(rx_rst),
        .rx_en(rx_en),
        .baudiv(baudiv),
        .rx(rx),
        .rx_busy(rx_busy),
        .rx_done(rx_done),
        .rx_err(rx_err),
        .rx_data(rx_data)
      );



endmodule