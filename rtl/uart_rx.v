`timescale 1ns / 1ps
// ================================================================
//  uart_rx.v  -  UART Receiver with power gating
//  Supports baud rates: 9600 / 57600 / 115200
//  System clock: 100 MHz
//  8-N-1 format
//  rx_enable = 0 → receiver ignores input
// ================================================================
module uart_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_enable,
    input  wire [1:0]  baud_sel,
    input  wire        RX,
    output reg  [7:0]  rx_data,
    output reg         rx_valid,
    output reg         rx_error
);

    // ----------------------------------------------------------
    // Baud divisors
    // ----------------------------------------------------------
    localparam DIV_9600   = 13'd10417;
    localparam DIV_57600  = 13'd1736;
    localparam DIV_115200 = 13'd868;

    // ----------------------------------------------------------
    // Internal signals
    // ----------------------------------------------------------
    reg [12:0] baud_div;
    reg [12:0] baud_cnt;
    reg        baud_tick;
    reg [12:0] half_div;

    reg [3:0] bit_idx;
    reg [7:0] shift_reg;

    reg RX_s1, RX_s2;

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;

    // ----------------------------------------------------------
    // Baud divisor select
    // ----------------------------------------------------------
    always @(*) begin
        case (baud_sel)
            2'b00: baud_div = DIV_9600;
            2'b01: baud_div = DIV_57600;
            default: baud_div = DIV_115200;
        endcase
        half_div = baud_div >> 1;
    end

    // ----------------------------------------------------------
    // RX synchronizer
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RX_s1 <= 1'b1;
            RX_s2 <= 1'b1;
        end else begin
            RX_s1 <= RX;
            RX_s2 <= RX_s1;
        end
    end

    // ----------------------------------------------------------
    // Baud counter (ONLY DRIVER of baud_cnt)
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt  <= 13'd0;
            baud_tick <= 1'b0;
        end else begin
            if (state == IDLE) begin
                baud_cnt  <= 13'd0;
                baud_tick <= 1'b0;
            end else begin
                if (baud_cnt >= baud_div - 1) begin
                    baud_cnt  <= 13'd0;
                    baud_tick <= 1'b1;
                end else begin
                    baud_cnt  <= baud_cnt + 1'b1;
                    baud_tick <= 1'b0;
                end
            end
        end
    end

    // ----------------------------------------------------------
    // RX FSM
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data   <= 8'h00;
            rx_valid  <= 1'b0;
            rx_error  <= 1'b0;
            bit_idx   <= 4'd0;
            shift_reg <= 8'h00;
            state     <= IDLE;
        end else begin
            rx_valid <= 1'b0;

            if (!rx_enable) begin
                state    <= IDLE;
                rx_error <= 1'b0;
            end else begin
                case (state)

                    IDLE: begin
                        rx_error <= 1'b0;
                        if (!RX_s2)
                            state <= START;
                    end

                    START: begin
                        if (baud_cnt >= half_div) begin
                            if (!RX_s2) begin
                                bit_idx <= 4'd0;
                                state   <= DATA;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end

                    DATA: begin
                        if (baud_tick) begin
                            shift_reg <= {RX_s2, shift_reg[7:1]};
                            bit_idx   <= bit_idx + 1'b1;
                            if (bit_idx == 4'd7)
                                state <= STOP;
                        end
                    end

                    STOP: begin
                        if (baud_tick) begin
                            if (RX_s2) begin
                                rx_data  <= shift_reg;
                                rx_valid <= 1'b1;
                                rx_error <= 1'b0;
                            end else begin
                                rx_error <= 1'b1;
                            end
                            state <= IDLE;
                        end
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule
