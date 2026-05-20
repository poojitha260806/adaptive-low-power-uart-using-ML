`timescale 1ns / 1ps
// ============================================================
// FULL VERIFICATION TESTBENCH
// Shows:
//   ACTIVE -> SLEEP -> WAKEUP -> ACTIVE
// ============================================================
module tb_adaptive_uart_top;

    reg         clk;
    reg         rst_n;
    reg         RX;
    reg  [7:0]  tx_data;
    reg         tx_start;
    reg         sec_tick;

    wire        TX;
    wire [7:0]  rx_data;
    wire        rx_valid;
    wire        rx_error;
    wire        tx_busy;
    wire        tx_done;
    wire [1:0]  power_state;
    wire        rx_enable_out;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    adaptive_uart_top DUT (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .sec_tick(sec_tick),
        .TX(TX),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .power_state(power_state),
        .rx_enable_out(rx_enable_out)
    );

    // --------------------------------------------------------
    // 100 MHz clock
    // --------------------------------------------------------
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // Connect TX loopback to RX
    // --------------------------------------------------------
    always @(TX)
        RX = TX;

    // --------------------------------------------------------
    // Task: generate simulated 1-second tick
    // --------------------------------------------------------
    task tick_second;
    begin
        #1000000;
        sec_tick = 1;
        #10;
        sec_tick = 0;
    end
    endtask

    // --------------------------------------------------------
    // Task: send one UART byte
    // --------------------------------------------------------
    task send_byte(input [7:0] data);
    begin
        tx_data  = data;
        tx_start = 1;
        #10;
        tx_start = 0;

        // wait until TX completes
        wait(tx_done);
        #100;
    end
    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------
    initial begin
        clk      = 0;
        rst_n    = 0;
        RX       = 1;
        tx_data  = 8'h00;
        tx_start = 0;
        sec_tick = 0;

        // Reset
        #100;
        rst_n = 1;

        // ============================================
        // PHASE 1: idle -> should go to SLEEP
        // ============================================
        repeat (20)
            tick_second();

        // ============================================
        // PHASE 2: burst traffic -> WAKEUP
        // ============================================
        send_byte(8'hA5);
        tick_second();

        send_byte(8'h3C);
        tick_second();

        send_byte(8'hF0);
        tick_second();

        // ============================================
        // PHASE 3: idle again -> SLEEP
        // ============================================
        repeat (20)
            tick_second();

        // ============================================
        // PHASE 4: more traffic -> ACTIVE
        // ============================================
        send_byte(8'h55);
        tick_second();

        send_byte(8'hAA);
        tick_second();
        // ============================================
        // PHASE 5: force wakeup after sleep
        // ============================================
        repeat (25)
            tick_second();

        send_byte(8'hCC);
        tick_second();

        send_byte(8'hDD);
        tick_second();

        repeat (5)
            tick_second();

        #5000;
        $finish;
    end

endmodule
