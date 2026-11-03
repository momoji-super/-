`timescale 1ns/1ps

module target_smoothing_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [95:0] data = 96'd0;
    reg valid = 1'b0;
    reg user = 1'b0;
    reg last = 1'b0;
    wire frame_toggle;
    wire target_valid;
    wire [9:0] x_min, y_min, x_max, y_max, center_x, center_y;
    wire [11:0] motion_count;
    integer beat_index;

    always #5 clk = ~clk;

    target_detect_track #(
        .IMG_WIDTH(16),
        .IMG_HEIGHT(1)
    ) dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_tdata(data),
        .I_red_tdata(data),
        .I_tvalid(valid),
        .I_tuser(user),
        .I_tlast(last),
        .O_frame_toggle(frame_toggle),
        .O_target_valid(target_valid),
        .O_x_min(x_min),
        .O_y_min(y_min),
        .O_x_max(x_max),
        .O_y_max(y_max),
        .O_center_x(center_x),
        .O_center_y(center_y),
        .O_motion_count(motion_count),
        .O_motion_valid(),
        .O_motion_x_min(),
        .O_motion_y_min(),
        .O_motion_x_max(),
        .O_motion_y_max()
    );

    function [23:0] pixel;
        input [15:0] red_mask;
        input integer pixel_index;
        begin
            pixel = red_mask[pixel_index] ? 24'hff0000 : 24'h000000;
        end
    endfunction

    task send_frame;
        input [15:0] red_mask;
        begin
            for (beat_index = 0; beat_index < 4; beat_index = beat_index + 1) begin
                @(negedge clk);
                data = {
                    pixel(red_mask, beat_index * 4 + 3),
                    pixel(red_mask, beat_index * 4 + 2),
                    pixel(red_mask, beat_index * 4 + 1),
                    pixel(red_mask, beat_index * 4)
                };
                valid = 1'b1;
                user = (beat_index == 0);
                last = (beat_index == 3);
                @(posedge clk);
                #1;
            end
            @(negedge clk);
            valid = 1'b0;
            user = 1'b0;
            last = 1'b0;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        send_frame(16'h00ff);
        send_frame(16'h0ff0);
        if (!target_valid || center_x !== 10'd3 ||
            x_min !== 10'd0 || x_max !== 10'd7)
            $fatal(1, "initial target detection mismatch");

        send_frame(16'h0ff0);
        if (!target_valid || center_x !== 10'd7 ||
            x_min !== 10'd4 || x_max !== 10'd11)
            $fatal(1, "target box must contain current frame extrema: x=%0d..%0d center=%0d",
                   x_min, x_max, center_x);

        $display("PASS target_detect_track complete, current-frame bounding box");
        $finish;
    end
endmodule
