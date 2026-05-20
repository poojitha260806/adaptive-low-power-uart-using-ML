`timescale 1ns / 1ps
// ================================================================
//  traffic_monitor.v  -  Communication Pattern Tracker
// ================================================================
module traffic_monitor (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sec_tick,
    input  wire        pkt_received,
    input  wire [7:0]  pkt_size,

    output reg  [4:0]  time_of_day,
    output reg  [9:0]  last_interval_x10,
    output reg  [9:0]  avg_interval_x10,
    output reg  [7:0]  recent_size
);

    // ----------------------------------------------------------
    // Internal registers
    // ----------------------------------------------------------
    reg [9:0]  second_cnt;
    reg [5:0]  hour_cnt;
    reg [9:0]  elapsed;

    reg [9:0]  interval_hist [0:7];
    reg [2:0]  hist_ptr;
    reg [13:0] interval_sum;

    integer i;

    // ----------------------------------------------------------
    // Simulated real-time clock
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            second_cnt  <= 10'd0;
            hour_cnt    <= 6'd0;
            time_of_day <= 5'd0;
        end
        else if (sec_tick) begin
            if (second_cnt >= 10'd3599) begin
                second_cnt <= 10'd0;

                if (hour_cnt >= 6'd23)
                    hour_cnt <= 6'd0;
                else
                    hour_cnt <= hour_cnt + 1'b1;

                time_of_day <= hour_cnt[4:0];
            end
            else begin
                second_cnt <= second_cnt + 1'b1;
            end
        end
    end

    // ----------------------------------------------------------
    // Elapsed interval tracker
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            elapsed <= 10'd0;
        else if (pkt_received)
            elapsed <= 10'd0;
        else if (sec_tick) begin
            if (elapsed < 10'd60)
                elapsed <= elapsed + 1'b1;
        end
    end

    // ----------------------------------------------------------
    // Moving average update
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hist_ptr     <= 3'd0;
            interval_sum <= 14'd240;
            for (i = 0; i < 8; i = i + 1)
                interval_hist[i] <= 10'd30;
        end
        else if (pkt_received) begin
            interval_sum <= interval_sum
                          - interval_hist[hist_ptr]
                          + elapsed;

            interval_hist[hist_ptr] <= elapsed;
            hist_ptr <= hist_ptr + 1'b1;
        end
    end

    // ----------------------------------------------------------
    // Output scaling
    // ----------------------------------------------------------
    always @(*) begin
        last_interval_x10 = elapsed * 10;
        avg_interval_x10  = (interval_sum * 10) >> 3;
    end

    // ----------------------------------------------------------
    // recent_size register (ONLY DRIVER)
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            recent_size <= 8'd50;
        else if (pkt_received)
            recent_size <= pkt_size;
    end

endmodule
