`timescale 1ns/1ps

module target_detect_track_tb;
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
    wire motion_valid;
    wire [9:0] motion_x_min, motion_y_min, motion_x_max, motion_y_max;
    integer y;

    always #5 clk = ~clk;

    target_detect_track #(
        .IMG_WIDTH(8),
        .IMG_HEIGHT(4),
        .MOTION_THRESHOLD(8'd20)
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
        .O_motion_valid(motion_valid),
        .O_motion_x_min(motion_x_min),
        .O_motion_y_min(motion_y_min),
        .O_motion_x_max(motion_x_max),
        .O_motion_y_max(motion_y_max)
    );

    task beat;
        input [95:0] pixels;
        input frame_start;
        input line_end;
        begin
            @(negedge clk);
            data = pixels;
            valid = 1'b1;
            user = frame_start;
            last = line_end;
            @(posedge clk);
            #1;
        end
    endtask

    task frame_black;
        integer row;
        begin
            beat({4{24'h000000}}, 1'b1, 1'b0);
            beat({4{24'h000000}}, 1'b0, 1'b1);
            for (row = 1; row < 4; row = row + 1) begin
                beat({4{24'h000000}}, 1'b0, 1'b0);
                beat({4{24'h000000}}, 1'b0, 1'b1);
            end
        end
    endtask

    initial begin
        if (dut.is_red_pixel(24'hffffff) ||
            dut.is_red_pixel(24'hfff0e0) ||
            dut.is_red_pixel(24'hd0c0c0) ||
            dut.is_red_pixel(24'hfff0c0) ||
            dut.is_red_pixel(24'hffcfb4) ||
            dut.is_red_pixel(24'hff8000) ||
            dut.is_red_pixel(24'hc87820))
            $fatal(1, "white, warm-white, and orange pixels must not classify as red");
        if (!dut.is_red_pixel(24'hff0000) ||
            !dut.is_red_pixel(24'hff3030) ||
            !dut.is_red_pixel(24'h966450) ||
            !dut.is_red_pixel(24'h5a1e14))
            $fatal(1, "bright, moderate, and dim red pixels must classify as red");

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        frame_black();
        if (motion_count !== 12'd0)
            $fatal(1, "first frame must not report motion");

        beat({4{24'hff0000}}, 1'b1, 1'b0);
        beat({4{24'hff0000}}, 1'b0, 1'b1);
        beat({24'h000000, 24'h000000, 24'h000000, 24'h000000}, 1'b0, 1'b0);
        beat({24'h000000, 24'h000000, 24'h000000, 24'h000000}, 1'b0, 1'b1);
        beat({4{24'h000000}}, 1'b0, 1'b0);
        beat({4{24'h000000}}, 1'b0, 1'b1);
        beat({4{24'h000000}}, 1'b0, 1'b0);
        beat({4{24'h000000}}, 1'b0, 1'b1);
        beat({24'hffffff, 24'h000000, 24'h000000, 24'h000000}, 1'b1, 1'b0);
        if (!target_valid || x_min !== 10'd0 || x_max !== 10'd7 ||
            y_min !== 10'd0 || y_max !== 10'd0 ||
            center_x !== 10'd3 || center_y !== 10'd0) begin
            $display("bbox valid=%b x=%0d..%0d y=%0d..%0d center=%0d,%0d",
                     target_valid, x_min, x_max, y_min, y_max,
                     center_x, center_y);
            $fatal(1, "target bounding box/center mismatch");
        end

        beat({4{24'h000000}}, 1'b0, 1'b1);
        for (y = 1; y < 4; y = y + 1) begin
            beat({4{24'h000000}}, 1'b0, 1'b0);
            beat({4{24'h000000}}, 1'b0, 1'b1);
        end
        beat({4{24'h000000}}, 1'b1, 1'b0);
        if (motion_count == 12'd0)
            $fatal(1, "frame difference did not detect a changed sample");
        if (!motion_valid || motion_x_min !== 10'd0 ||
            motion_y_min !== 10'd0 || motion_x_max !== 10'd7 ||
            motion_y_max !== 10'd3)
            $fatal(1, "motion bounding box mismatch: valid=%b x=%0d..%0d y=%0d..%0d",
                   motion_valid, motion_x_min, motion_x_max,
                   motion_y_min, motion_y_max);

        beat({4{24'h000000}}, 1'b0, 1'b1);
        beat({4{24'h000000}}, 1'b0, 1'b0);
        beat({4{24'h000000}}, 1'b0, 1'b1);
        beat({4{24'h000000}}, 1'b0, 1'b0);
        beat({4{24'h000000}}, 1'b0, 1'b1);
        beat({4{24'hff0000}}, 1'b0, 1'b0);
        beat({4{24'hff0000}}, 1'b0, 1'b1);
        beat({4{24'hff0000}}, 1'b1, 1'b0);
        if (!target_valid || y_min !== 10'd3 || y_max !== 10'd3 ||
            x_min !== 10'd0 || x_max !== 10'd7 || center_y !== 10'd3)
            $fatal(1, "bottom-edge target box was clipped or wrapped");

        $display("PASS target_detect_track target bbox, frame difference and motion region");
        $finish;
    end
endmodule
