`timescale 1ns/1ps

module hdmi_mixer_osd_switch_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg osd_enable = 1'b0;
    reg [23:0] video_pixel = 24'h123456;
    wire video_rd_en;
    wire hdmi_vsync, hdmi_hsync, hdmi_de;
    wire [23:0] hdmi_data;

    always #5 clk = ~clk;

    hdmi_mixer #(.ENABLE_OSD(1), .PIXEL_CLOCK_HZ(1000)) dut (
        .I_clk(clk), .I_rst_n(rst_n), .I_video_vsync(1'b0),
        .I_video_hsync(1'b0), .I_video_de(1'b0), .I_video_user(1'b0),
        .I_video_last(1'b0), .I_debug_status(4'd0), .I_algo_mode(3'd0),
        .I_edge_threshold(8'd48), .I_ae_target_level(3'd3),
        .I_ae_value(16'd1800), .I_ae_mode(1'b1), .I_tracking_mode(1'b0),
        .I_osd_enable(osd_enable), .I_capture_frame_id(16'd0),
        .I_display_frame_id(16'd0), .I_target_valid(1'b0),
        .I_target_x_min(11'd0), .I_target_y_min(11'd0),
        .I_target_x_max(11'd0), .I_target_y_max(11'd0),
        .I_target_center_x(11'd0), .I_target_center_y(11'd0),
        .I_motion_count(12'd0), .I_motion_valid(1'b0),
        .I_motion_x_min(11'd0), .I_motion_y_min(11'd0),
        .I_motion_x_max(11'd0), .I_motion_y_max(11'd0),
        .I_hand_enable(1'b0), .I_hand_count(4'd0),
        .I_hand_valid(1'b0), .I_hand_error(4'd0),
        .O_video_rd_en(video_rd_en), .I_video_rd_data(video_pixel),
        .O_hdmi_vsync(hdmi_vsync), .O_hdmi_hsync(hdmi_hsync),
        .O_hdmi_de(hdmi_de), .O_hdmi_data(hdmi_data));

    task check_pixel;
        input [23:0] expected;
        input [255:0] label;
        begin
            #1;
            if (dut.S_pixel !== expected)
                $fatal(1, "%0s: got %h expected %h", label, dut.S_pixel, expected);
            $display("PASS %0s: %h", label, dut.S_pixel);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        force dut.S_x_2d = 12'd500;
        force dut.S_y_2d = 12'd10;
        check_pixel(video_pixel, "SW4 low passes top video");
        osd_enable = 1'b1;
        check_pixel(24'h101820, "SW4 high draws top OSD bar");
        force dut.S_y_2d = 12'd100;
        check_pixel(video_pixel, "OSD leaves central video visible");
        force dut.S_x_2d = 12'd18;
        force dut.S_y_2d = 12'd82;
        check_pixel(video_pixel, "OSD has no fixed cyan corner mark");
        force dut.S_tracking_mode_display = 1'b1;
        force dut.S_motion_valid_display = 1'b1;
        force dut.S_motion_x_min_display = 11'd18;
        force dut.S_motion_x_max_display = 11'd80;
        force dut.S_motion_y_min_display = 11'd80;
        force dut.S_motion_y_max_display = 11'd120;
        check_pixel(24'h00ff00, "motion outline is bright green");
        force dut.S_x_2d = 12'd19;
        check_pixel(24'h00ff00, "motion outline is two pixels wide");
        force dut.S_x_2d = 12'd20;
        check_pixel(video_pixel, "motion outline stops after two pixels");
        force dut.S_x_2d = 12'd18;
        release dut.S_tracking_mode_display;
        release dut.S_motion_valid_display;
        release dut.S_motion_x_min_display;
        release dut.S_motion_x_max_display;
        release dut.S_motion_y_min_display;
        release dut.S_motion_y_max_display;
        force dut.S_y_2d = 12'd600;
        check_pixel(video_pixel, "compact footer preserves picture above footer");
        force dut.S_y_2d = 12'd718;
        force dut.S_x_2d = 12'd640;
        check_pixel(24'h101820, "SW4 high draws compact footer");
        force dut.S_x_2d = 12'd1200;
        check_pixel(24'h101820, "compact footer black background spans full width");
        force dut.S_y_2d = 12'd710;
        force dut.S_x_2d = 12'd230;
        #1;
        if (dut.S_text_group != 4'd9 || dut.S_text_index != 0)
            $fatal(1, "AE footer field is not at its distributed position");
        force dut.S_x_2d = 12'd1095;
        force dut.S_y_2d = 12'd711;
        force dut.S_y_2d = 12'd710;
        #1;
        if (dut.S_text_group != 4'd5 || dut.S_text_index != 0)
            $fatal(1, "HDMI footer field is not at its distributed position");
        if (dut.ui_char(4'd5, 5'd5, 3'd0, 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0, 0) != "1" ||
            dut.ui_char(4'd5, 5'd7, 3'd0, 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0, 0) != "8" ||
            dut.ui_char(4'd5, 5'd10, 3'd0, 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0, 0) != "7" ||
            dut.ui_char(4'd5, 5'd12, 3'd0, 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0, 0) != "0")
            $fatal(1, "HDMI footer resolution is not 1280X720");
        osd_enable = 1'b0;
        check_pixel(video_pixel, "SW4 low restores bottom video");
        release dut.S_x_2d;
        release dut.S_y_2d;
        $display("PASS hdmi_mixer_osd_switch_tb");
        $finish;
    end
endmodule
