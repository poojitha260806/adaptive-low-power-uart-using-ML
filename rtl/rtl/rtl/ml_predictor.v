module ml_predictor (
    input  wire [4:0] time_of_day,
    input  wire [9:0] last_interval_x10,
    input  wire [9:0] avg_interval_x10,
    input  wire [7:0] recent_size,
    output reg        predict_traffic
);

always @(*) begin
    // Default: predict idle
    predict_traffic = 1'b0;

        if ((last_interval_x10) <= 267) begin
            if ((avg_interval_x10) <= 292) begin
                if ((last_interval_x10) <= 139) begin
                    if ((avg_interval_x10) <= 77) begin
                        if (time_of_day <= 8) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b1;
                        end
                    end else begin
                        if ((avg_interval_x10) <= 102) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b0;
                        end
                    end
                end else begin
                    if ((avg_interval_x10) <= 194) begin
                        if (time_of_day <= 8) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b1;
                        end
                    end else begin
                        if ((last_interval_x10) <= 202) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b1;
                        end
                    end
                end
            end else begin
                if ((avg_interval_x10) <= 296) begin
                    if ((avg_interval_x10) <= 296) begin
                        if ((last_interval_x10) <= 263) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b0;
                        end
                    end else begin
                        if ((last_interval_x10) <= 254) begin
                            predict_traffic = 1'b1;
                        end else begin
                            predict_traffic = 1'b0;
                        end
                    end
                end else begin
                    predict_traffic = 1'b0;
                end
            end
        end else begin
            if ((avg_interval_x10) <= 273) begin
                if (time_of_day <= 8) begin
                    if (recent_size <= 149) begin
                        if ((avg_interval_x10) <= 102) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b0;
                        end
                    end else begin
                        predict_traffic = 1'b1;
                    end
                end else begin
                    if (time_of_day <= 19) begin
                        predict_traffic = 1'b1;
                    end else begin
                        if (recent_size <= 147) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b1;
                        end
                    end
                end
            end else begin
                if ((avg_interval_x10) <= 370) begin
                    if ((last_interval_x10) <= 286) begin
                        if ((avg_interval_x10) <= 309) begin
                            predict_traffic = 1'b1;
                        end else begin
                            predict_traffic = 1'b0;
                        end
                    end else begin
                        if (recent_size <= 71) begin
                            predict_traffic = 1'b1;
                        end else begin
                            predict_traffic = 1'b1;
                        end
                    end
                end else begin
                    if ((last_interval_x10) <= 394) begin
                        if ((avg_interval_x10) <= 413) begin
                            predict_traffic = 1'b0;
                        end else begin
                            predict_traffic = 1'b0;
                        end
                    end else begin
                        if ((last_interval_x10) <= 420) begin
                            predict_traffic = 1'b1;
                        end else begin
                            predict_traffic = 1'b1;
                        end
                    end
                end
            end
        end

end

endmodule
