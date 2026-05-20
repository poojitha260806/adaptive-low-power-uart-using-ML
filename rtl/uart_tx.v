`timescale 1ns / 1ps
// ================================================================
//  uart_tx.v  -  UART Transmitter
//  Supports baud rates: 9600 / 57600 / 115200
//  System clock: 100 MHz
//  8-N-1 format (8 data bits, no parity, 1 stop bit)
// ================================================================
module uart_tx (
    input  wire        clk,
    input  wire        rst_n,
    // Baud rate select: 00=9600  01=57600  10=115200
    input  wire [1:0]  baud_sel,
    // Data interface
    input  wire [7:0]  tx_data,
    input  wire        tx_start,
    output reg         tx_busy,
    output reg         tx_done,
    // Serial output
    output reg         TX
);

    // ----------------------------------------------------------
    // Baud rate divisors for 100 MHz clock
    //   divisor = 100_000_000 / baud_rate
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

    reg [3:0]  bit_idx;    // 0-9  (start + 8 data + stop)
    reg [9:0]  shift_reg;  // {stop, data[7:0], start}

    // FSM states
    localparam IDLE  = 2'd0;
    localparam LOAD  = 2'd1;
    localparam SHIFT = 2'd2;
    localparam DONE  = 2'd3;

    reg [1:0] state;

    // ----------------------------------------------------------
    // Select baud divisor
    // ----------------------------------------------------------
    always @(*) begin
        case (baud_sel)
            2'b00  : baud_div = DIV_9600;
            2'b01  : baud_div = DIV_57600;
            default: baud_div = DIV_115200;
        endcase
    end

    // ----------------------------------------------------------
    // Baud tick generator
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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

    // ----------------------------------------------------------
    // TX FSM
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            TX        <= 1'b1;   // idle high
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            bit_idx   <= 4'd0;
            shift_reg <= 10'h3FF;
            state     <= IDLE;
        end else begin
            tx_done <= 1'b0;     // pulse for one clock

            case (state)
                IDLE: begin
                    TX      <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    // Frame: [stop=1][data7..0][start=0]
                    shift_reg <= {1'b1, tx_data, 1'b0};
                    bit_idx   <= 4'd0;
                    tx_busy   <= 1'b1;
                    state     <= SHIFT;
                end

                SHIFT: begin
                    if (baud_tick) begin
                        TX        <= shift_reg[0];
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        bit_idx   <= bit_idx + 1'b1;
                        if (bit_idx == 4'd9) begin
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    if (baud_tick) begin
                        TX      <= 1'b1;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                        state   <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
