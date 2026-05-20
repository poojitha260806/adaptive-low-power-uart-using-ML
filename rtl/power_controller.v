`timescale 1ns / 1ps
// ================================================================
//  power_controller.v  -  Adaptive Power Management FSM
//
//  States:
//    ACTIVE  : RX fully on, normal operation
//    SLEEP   : RX clock-gated, minimal power
//    WAKEUP  : Stabilisation delay before going ACTIVE
//
//  Transitions:
//    ACTIVE  → SLEEP  : predictor says idle AND no ongoing RX
//    SLEEP   → WAKEUP : predictor says imminent OR watchdog expired
//    WAKEUP  → ACTIVE : after WAKEUP_CYCLES stabilisation
//
//  Hysteresis: must see SLEEP_THRESH consecutive "idle" predictions
//              before entering SLEEP (avoids flapping)
// ================================================================
module power_controller (
    input  wire        clk,
    input  wire        rst_n,

    // From ML predictor
    input  wire        predict_traffic,   // 1=imminent, 0=idle
    // From UART RX: asserted while a frame is being received
    input  wire        rx_busy,

    // Simulated sec_tick for watchdog
    input  wire        sec_tick,

    // Outputs
    output reg         rx_enable,    // 1 = power on RX
    output reg  [1:0]  baud_sel,     // dynamic baud select
    output reg  [1:0]  power_state   // for observability
);

    // ----------------------------------------------------------
    // Parameters
    // ----------------------------------------------------------
    // Hysteresis: 3 consecutive idle predictions to sleep
    localparam SLEEP_THRESH  = 4'd3;
    // Max sleep time in seconds before forced wake (safety)
    localparam WATCHDOG_MAX  = 8'd60;
    // Wake-up stabilisation: 250 000 cycles @ 100 MHz ≈ 2.5 ms
    localparam WAKEUP_CYCLES = 18'd250_000;

    // ----------------------------------------------------------
    // State encoding
    // ----------------------------------------------------------
    localparam ACTIVE = 2'd0;
    localparam SLEEP  = 2'd1;
    localparam WAKEUP = 2'd2;

    // ----------------------------------------------------------
    // Internal registers
    // ----------------------------------------------------------
    reg [3:0]  idle_cnt;       // consecutive idle predictions
    reg [7:0]  watchdog_cnt;   // seconds in SLEEP
    reg [17:0] wakeup_cnt;     // cycles in WAKEUP state

    reg [1:0]  state;

    // ----------------------------------------------------------
    // FSM
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= ACTIVE;
            rx_enable   <= 1'b1;
            baud_sel    <= 2'b10;     // default 115200
            power_state <= ACTIVE;
            idle_cnt    <= 4'd0;
            watchdog_cnt<= 8'd0;
            wakeup_cnt  <= 18'd0;
        end else begin

            case (state)
                // ─────────────────────────────────────────────
                ACTIVE: begin
                    rx_enable   <= 1'b1;
                    power_state <= ACTIVE;

                    if (!predict_traffic && !rx_busy) begin
                        idle_cnt <= idle_cnt + 1'b1;
                        if (idle_cnt >= SLEEP_THRESH) begin
                            idle_cnt     <= 4'd0;
                            watchdog_cnt <= 8'd0;
                            state        <= SLEEP;
                        end
                    end else begin
                        idle_cnt <= 4'd0;
                    end

                    // Dynamic baud rate based on traffic prediction
                    // (packet size info comes from traffic monitor via
                    //  the top-level; kept simple here with prediction)
                    baud_sel <= predict_traffic ? 2'b10 : 2'b00;
                end

                // ─────────────────────────────────────────────
                SLEEP: begin
                    rx_enable   <= 1'b0;
                    power_state <= SLEEP;
                    wakeup_cnt  <= 18'd0;

                    // Watchdog counter
                    if (sec_tick) begin
                        if (watchdog_cnt < WATCHDOG_MAX)
                            watchdog_cnt <= watchdog_cnt + 1'b1;
                    end

                    // Wake conditions
                    if (predict_traffic ||
                        (watchdog_cnt >= WATCHDOG_MAX)) begin
                        state <= WAKEUP;
                    end
                end

                // ─────────────────────────────────────────────
                WAKEUP: begin
                    rx_enable   <= 1'b0;   // still off during stabilise
                    power_state <= WAKEUP;

                    wakeup_cnt <= wakeup_cnt + 1'b1;
                    if (wakeup_cnt >= WAKEUP_CYCLES) begin
                        idle_cnt <= 4'd0;
                        state    <= ACTIVE;
                    end
                end

                default: state <= ACTIVE;
            endcase
        end
    end

endmodule
