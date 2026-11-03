`timescale 1ns/1ps

module hdmi_mixer_age_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg video_user = 1'b0;
    reg [15:0] capture_frame_id = 16'd0;
    reg [15:0] display_frame_id = 16'd0;
    reg [15:0] ae_value = 16'd1800;
    reg ae_mode = 1'b1;
    reg [2:0] ae_level = 3'd3;
    reg tracking_mode = 1'b0;
    reg target_valid = 1'b0;
    reg motion_valid = 1'b0;
    wire video_rd_en;
    wire hdmi_vsync;
    wire hdmi_hsync;
    wire hdmi_de;
    wire [23:0] hdmi_data;

    always #5 clk = ~clk;

    hdmi_mixer #(
        .PIXEL_CLOCK_HZ(1000)
    ) dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_video_vsync(1'b0),
        .I_video_hsync(1'b0),
        .I_video_de(1'b0),
        .I_video_user(video_user),
        .I_video_last(1'b0),
        .I_debug_status(4'd0),
        .I_algo_mode(3'd0),
        .I_edge_threshold(8'd48),
        .I_ae_target_level(ae_level),
        .I_ae_value(ae_value),
        .I_ae_mode(ae_mode),
        .I_tracking_mode(tracking_mode),
        .I_osd_enable(1'b0),
        .I_capture_frame_id(capture_frame_id),
        .I_display_frame_id(display_frame_id),
        .I_target_valid(target_valid),
        .I_target_x_min(11'd0),
        .I_target_y_min(11'd0),
        .I_target_x_max(11'd0),
        .I_target_y_max(11'd0),
        .I_target_center_x(11'd0),
        .I_target_center_y(11'd0),
        .I_motion_count(12'd0),
        .I_motion_valid(motion_valid),
        .I_motion_x_min(11'd0),
        .I_motion_y_min(11'd0),
        .I_motion_x_max(11'd0),
        .I_motion_y_max(11'd0),
        .I_hand_enable(1'b0),
        .I_hand_count(4'd0),
        .I_hand_valid(1'b0),
        .I_hand_error(4'd0),
        .O_video_rd_en(video_rd_en),
        .I_video_rd_data(24'd0),
        .O_hdmi_vsync(hdmi_vsync),
        .O_hdmi_hsync(hdmi_hsync),
        .O_hdmi_de(hdmi_de),
        .O_hdmi_data(hdmi_data)
    );

    task frame_start;
        begin
            @(negedge clk);
            video_user = 1'b1;
            @(negedge clk);
            video_user = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
        #1;

        target_valid = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        if (dut.S_frame_age !== 7'd0)
            $fatal(1, "AGE did not stay zero while target was present");

        frame_start();
        if (dut.S_frame_age !== 7'd0)
            $fatal(1, "AGE did not reset at frame start");

        target_valid = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (dut.S_frame_age !== 7'd0)
            $fatal(1, "AGE changed in the middle of a frame");

        frame_start();
        if (dut.S_frame_age !== 7'd1)
            $fatal(1, "AGE did not increment once at frame start");

        repeat (3) @(posedge clk);
        #1;
        if (dut.S_frame_age !== 7'd1)
            $fatal(1, "AGE did not remain stable within a frame");

        target_valid = 1'b1;
        repeat (2) @(posedge clk);
        #1;
        if (dut.S_frame_age !== 7'd1)
            $fatal(1, "AGE changed before the next frame boundary");
        frame_start();
        if (dut.S_frame_age !== 7'd0)
            $fatal(1, "AGE did not clear after target reacquisition");

        @(negedge clk);
        capture_frame_id = 16'd10;
        display_frame_id = 16'd7;
        frame_start();
        if (dut.S_latency_frames !== 7'd3)
            $fatal(1, "LAT did not report buffered frame age");

        ae_value = 16'd2244;
        repeat (3) @(posedge clk);
        #1;
        if (dut.S_ae_value_display !== 16'd1800)
            $fatal(1, "AE display changed before frame boundary");
        frame_start();
        frame_start();
        if (dut.S_ae_value_display !== 16'd2244 ||
            dut.ui_char(4'd9, 5'd3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "2" ||
            dut.ui_char(4'd9, 5'd4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "2" ||
            dut.ui_char(4'd9, 5'd5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "4" ||
            dut.ui_char(4'd9, 5'd6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "4" ||
            dut.ui_char(4'd9, 5'd8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "1" ||
            dut.ui_char(4'd9, 5'd9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "5" ||
            dut.ui_char(4'd9, 5'd10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "0" ||
            dut.ui_char(4'd9, 5'd11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "-" ||
            dut.ui_char(4'd9, 5'd12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "2" ||
            dut.ui_char(4'd9, 5'd13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "0" ||
            dut.ui_char(4'd9, 5'd14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) !== "0")
            $fatal(1, "AE display value/range digits are incorrect");

        motion_valid = 1'b1;
        frame_start();
        if (!dut.S_motion_valid_display)
            $fatal(1, "motion box did not appear");
        motion_valid = 1'b0;
        // Detector owns missed-frame hold. Display must not retain an expired
        // box for another eight HDMI frames, or flash rejection is delayed.
        frame_start();
        if (dut.S_motion_valid_display)
            $fatal(1, "motion display retained an expired detector box");

        target_valid = 1'b1;
        motion_valid = 1'b1;
        dut.S_target_x_min_display = 10'd10;
        dut.S_target_y_min_display = 10'd10;
        dut.S_target_x_max_display = 10'd20;
        dut.S_target_y_max_display = 10'd20;
        dut.S_motion_x_min_display = 10'd10;
        dut.S_motion_y_min_display = 10'd10;
        dut.S_motion_x_max_display = 10'd20;
        dut.S_motion_y_max_display = 10'd20;
        dut.S_x_2d = 12'd10;
        dut.S_y_2d = 12'd10;

        tracking_mode = 1'b1;
        repeat (3) @(posedge clk);
        frame_start();
        #1;
        if (!dut.S_tracking_mode_display || dut.S_target_outline ||
            !dut.S_motion_outline || dut.S_target_cross)
            $fatal(1, "motion mode must show only motion detection overlay");
        tracking_mode = 1'b0;
        repeat (3) @(posedge clk);
        frame_start();
        #1;
        if (dut.S_tracking_mode_display || !dut.S_target_outline ||
            dut.S_motion_outline || !dut.S_target_cross)
            $fatal(1, "red mode must show only red target overlay");

        if (dut.font5x7("C",0) !== 5'd14 || dut.font5x7("C",3) !== 5'd16)
            $fatal(1,"Missing C glyph");
        if (dut.font5x7("Q",0) !== 5'd14 || dut.font5x7("Q",6) !== 5'd13)
            $fatal(1,"Missing Q glyph");
        if (dut.ui_char(4'd2,5'd6,3'd6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) !== "C")
            $fatal(1,"CARTOON first character");
        $display("PASS C glyph and CARTOON first character");
        $display("PASS hdmi_mixer AGE stability and LAT measurement");
        $finish;
    end
endmodule
