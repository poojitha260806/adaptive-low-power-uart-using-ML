`timescale 1ns / 1ps
// ================================================================
//  adaptive_uart_top.v  -  Top-level Integration
//
//  Connects:
//    uart_tx          → transmitter
//    uart_rx          → power-gatable receiver
//    traffic_monitor  → pattern tracker
//    ml_predictor     → Decision Tree predictor
//    power_controller → FSM power manager
// ================================================================
module adaptive_uart_top (
    input  wire        clk,
    input  wire        rst_n,

    // External IO
    input  wire        RX,
    output wire        TX,

    // Testbench / system controls
    input  wire        sec_tick,     // simulated 1-second tick
    input  wire [7:0]  tx_data,
    input  wire        tx_start,

    // Outputs visible to testbench
    output wire [7:0]  rx_data,
    output wire        rx_valid,
    output wire        rx_error,
    output wire        tx_busy,
    output wire        tx_done,
    output wire [1:0]  power_state,
    output wire        rx_enable_out
);

    // ----------------------------------------------------------
    // Internal wires
    // ----------------------------------------------------------
    wire [1:0]  baud_sel;
    wire        rx_enable;

    // Traffic monitor outputs
    wire [4:0]  time_of_day;
    wire [9:0]  last_interval_x10;
    wire [9:0]  avg_interval_x10;
    wire [7:0]  recent_size;

    // ML predictor output
    wire        predict_traffic;

    // RX busy (a frame is being received)
    // We derive this from rx_valid being high (single-cycle)
    // and add a 1-frame hold register
    reg         rx_busy_hold;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_busy_hold <= 1'b0;
        else if (rx_valid)
            rx_busy_hold <= 1'b1;
        else
            rx_busy_hold <= 1'b0;
    end

    // ----------------------------------------------------------
    // Instantiate: UART TX
    // ----------------------------------------------------------
    uart_tx u_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .baud_sel (baud_sel),
        .tx_data  (tx_data),
        .tx_start (tx_start),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done),
        .TX       (TX)
    );

    // ----------------------------------------------------------
    // Instantiate: UART RX
    // ----------------------------------------------------------
    uart_rx u_rx (
        .clk       (clk),
        .rst_n     (rst_n),
        .rx_enable (rx_enable),
        .baud_sel  (baud_sel),
        .RX        (RX),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid),
        .rx_error  (rx_error)
    );

    // ----------------------------------------------------------
    // Instantiate: Traffic Monitor
    // ----------------------------------------------------------
    traffic_monitor u_mon (
        .clk                (clk),
        .rst_n              (rst_n),
        .sec_tick           (sec_tick),
        .pkt_received       (rx_valid),
        .pkt_size           (rx_data),
        .time_of_day        (time_of_day),
        .last_interval_x10  (last_interval_x10),
        .avg_interval_x10   (avg_interval_x10),
        .recent_size        (recent_size)
    );

    // ----------------------------------------------------------
    // Instantiate: ML Predictor
    // ----------------------------------------------------------
    ml_predictor u_pred (
        .time_of_day        (time_of_day),
        .last_interval_x10  (last_interval_x10),
        .avg_interval_x10   (avg_interval_x10),
        .recent_size        (recent_size),
        .predict_traffic    (predict_traffic)
    );

    // ----------------------------------------------------------
    // Instantiate: Power Controller
    // ----------------------------------------------------------
    power_controller u_pwr (
        .clk             (clk),
        .rst_n           (rst_n),
        .predict_traffic (predict_traffic),
        .rx_busy         (rx_busy_hold),
        .sec_tick        (sec_tick),
        .rx_enable       (rx_enable),
        .baud_sel        (baud_sel),
        .power_state     (power_state)
    );

    assign rx_enable_out = rx_enable;

endmodule
