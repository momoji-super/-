module hdmi_mixer #(
    parameter H_OFFSET = 0,
    parameter V_OFFSET = 0,
    parameter IMG_WIDTH = 1280,
    parameter IMG_HEIGHT = 720,
    parameter integer DEBUG_MODE = 0,
    parameter integer ENABLE_OSD = 0,
    parameter integer PIXEL_CLOCK_HZ = 74250000
)(
    input wire        I_clk,
    input wire        I_rst_n,
    input wire        I_video_vsync,
    input wire        I_video_hsync,
    input wire        I_video_de,
    input wire        I_video_user,
    input wire        I_video_last,
    input wire [3:0]  I_debug_status,
    input wire [2:0]  I_algo_mode,
    input wire [7:0]  I_edge_threshold,
    input wire [2:0]  I_ae_target_level,
    input wire [15:0] I_ae_value,
    input wire        I_ae_mode,
    input wire        I_tracking_mode,
    input wire        I_osd_enable,
    input wire [15:0] I_capture_frame_id,
    input wire [15:0] I_display_frame_id,
    input wire        I_target_valid,
    input wire [10:0]  I_target_x_min,
    input wire [10:0]  I_target_y_min,
    input wire [10:0]  I_target_x_max,
    input wire [10:0]  I_target_y_max,
    input wire [10:0]  I_target_center_x,
    input wire [10:0]  I_target_center_y,
    input wire [11:0] I_motion_count,
    input wire        I_motion_valid,
    input wire [10:0]  I_motion_x_min,
    input wire [10:0]  I_motion_y_min,
    input wire [10:0]  I_motion_x_max,
    input wire [10:0]  I_motion_y_max,
    input wire        I_hand_enable,
    input wire [3:0]  I_hand_count,
    input wire        I_hand_valid,
    input wire [3:0]  I_hand_error,
    output wire       O_video_rd_en,
    input wire [23:0] I_video_rd_data,
    output reg        O_hdmi_vsync,
    output reg        O_hdmi_hsync,
    output reg        O_hdmi_de,
    output reg [23:0] O_hdmi_data
);

    localparam [23:0] C_TOP_BG = 24'h101820;
    localparam [23:0] C_BOTTOM_BG = 24'h101820;
    localparam [23:0] C_WHITE = 24'hf2f5f7;
    localparam [23:0] C_MUTED = 24'h9aa8b2;
    localparam [23:0] C_CYAN = 24'h26d7c5;
    localparam [23:0] C_RED = 24'he83e45;
    localparam [23:0] C_MOTION_GREEN = 24'h00ff00;
    localparam [23:0] C_NAVY = 24'h1b2b4d;
    // One 14-pixel text row with four pixels of vertical padding.
    // The footer background spans the full image width in the bottom 22 rows.
    localparam [11:0] FOOTER_Y = IMG_HEIGHT - 22;
    localparam [11:0] FOOTER_TEXT_Y = IMG_HEIGHT - 18;

    reg        S_video_vsync_1d, S_video_vsync_2d;
    reg        S_video_hsync_1d, S_video_hsync_2d;
    reg        S_video_de_1d, S_video_de_2d;
    reg [23:0] S_video_data_1d, S_video_data_2d;
    reg [11:0] S_x, S_x_1d, S_x_2d;
    reg [11:0] S_y, S_y_1d, S_y_2d;
    reg [2:0]  S_mode_sync1, S_mode_sync2, S_mode_display;
    reg [7:0] S_edge_sync1, S_edge_sync2, S_edge_display;
    reg [2:0] S_ae_level_sync1, S_ae_level_sync2, S_ae_level_display;
    reg S_ae_mode_sync1, S_ae_mode_sync2, S_ae_mode_display;
    reg S_tracking_mode_sync1, S_tracking_mode_sync2;
    reg S_tracking_mode_display;
    reg [15:0] S_ae_value_sync1, S_ae_value_sync2, S_ae_value_display;
    reg [26:0] S_fps_clock_count;
    reg [7:0]  S_fps_frame_count, S_fps_value;
    reg [7:0]  S_fps_tens, S_fps_ones;
    reg [6:0]  S_frame_age;
    reg [7:0]  S_motion_hundreds, S_motion_tens, S_motion_ones;
    reg [7:0]  S_age_tens, S_age_ones;
    reg        S_target_valid_display;
    reg [10:0]  S_target_x_min_display, S_target_y_min_display;
    reg [10:0]  S_target_x_max_display, S_target_y_max_display;
    reg [10:0]  S_target_x_display, S_target_y_display;
    reg        S_motion_valid_display;
    reg [3:0]  S_motion_hold_frames;
    reg [10:0]  S_motion_x_min_display, S_motion_y_min_display;
    reg [10:0]  S_motion_x_max_display, S_motion_y_max_display;
    reg [7:0]  S_target_x_thousands, S_target_x_hundreds;
    reg [7:0]  S_target_x_tens, S_target_x_ones;
    reg [7:0]  S_target_y_hundreds, S_target_y_tens, S_target_y_ones;
    reg [6:0]  S_latency_frames;
    wire [15:0] S_latency_frame_diff = I_capture_frame_id - I_display_frame_id;
    reg [7:0]  S_latency_tens, S_latency_ones;
    reg [7:0]  S_ae_thousands, S_ae_hundreds, S_ae_tens, S_ae_ones;
    reg [7:0]  S_text_char;
    reg [4:0]  S_text_row;
    reg [3:0]  S_text_group;
    reg [4:0]  S_text_index;
    reg [11:0] S_text_x0;
    reg [11:0] S_text_y0;
    reg        S_text_pixel;
    reg [23:0] S_pixel;
    reg [3:0] S_logo_pixel;
    reg S_target_outline;
    reg S_target_cross;
    reg S_motion_outline;
    reg [3:0]  S_hand_count_display;
    reg        S_hand_valid_display;
    reg [3:0]  S_hand_error_display;
    reg        S_hand_enable_display;

    assign O_video_rd_en = I_video_de;

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_x <= 12'd0;
            S_y <= 12'd0;
            S_x_1d <= 12'd0;
            S_x_2d <= 12'd0;
            S_y_1d <= 12'd0;
            S_y_2d <= 12'd0;
        end else begin
            S_x_1d <= S_x;
            S_x_2d <= S_x_1d;
            S_y_1d <= S_y;
            S_y_2d <= S_y_1d;
            if (I_video_user) begin
                S_x <= I_video_de ? 12'd1 : 12'd0;
                S_y <= 12'd0;
            end else if (I_video_de) begin
                if (I_video_last) begin
                    S_x <= 12'd0;
                    S_y <= S_y + 12'd1;
                end else begin
                    S_x <= S_x + 12'd1;
                end
            end
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_frame_age <= 7'd0;
            S_target_valid_display <= 1'b0;
            S_target_x_min_display <= 10'd0;
            S_target_y_min_display <= 10'd0;
            S_target_x_max_display <= 10'd0;
            S_target_y_max_display <= 10'd0;
            S_target_x_display <= 10'd0;
            S_target_y_display <= 10'd0;
            S_motion_valid_display <= 1'b0;
            S_motion_hold_frames <= 4'd0;
            S_motion_x_min_display <= 10'd0;
            S_motion_y_min_display <= 10'd0;
            S_motion_x_max_display <= 10'd0;
            S_motion_y_max_display <= 10'd0;
            S_latency_frames <= 7'd0;
            S_hand_count_display <= 4'd0;
            S_hand_valid_display <= 1'b0;
            S_hand_error_display <= 4'd0;
            S_hand_enable_display <= 1'b0;
        end else if (I_video_user) begin
            S_target_valid_display <= I_target_valid;
            S_target_x_min_display <= I_target_x_min;
            S_target_y_min_display <= I_target_y_min;
            S_target_x_max_display <= I_target_x_max;
            S_target_y_max_display <= I_target_y_max;
            S_target_x_display <= I_target_center_x;
            S_target_y_display <= I_target_center_y;
            if (I_motion_valid) begin
                S_motion_valid_display <= 1'b1;
                S_motion_hold_frames <= 4'd0;
                S_motion_x_min_display <= I_motion_x_min;
                S_motion_y_min_display <= I_motion_y_min;
                S_motion_x_max_display <= I_motion_x_max;
                S_motion_y_max_display <= I_motion_y_max;
            end else if (S_motion_hold_frames != 4'd0) begin
                S_motion_valid_display <= 1'b1;
                S_motion_hold_frames <= S_motion_hold_frames - 4'd1;
            end else begin
                S_motion_valid_display <= 1'b0;
            end
            S_latency_frames <= (S_latency_frame_diff > 16'd99) ?
                                7'd99 : S_latency_frame_diff[6:0];
            S_hand_count_display <= I_hand_count;
            S_hand_valid_display <= I_hand_valid;
            S_hand_error_display <= I_hand_error;
            S_hand_enable_display <= I_hand_enable;
            if (I_target_valid)
                S_frame_age <= 7'd0;
            else if (S_frame_age < 7'd99)
                S_frame_age <= S_frame_age + 7'd1;
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_mode_sync1 <= 3'd0;
            S_mode_sync2 <= 3'd0;
            S_mode_display <= 3'd0;
            S_edge_sync1 <= 48; S_edge_sync2 <= 48; S_edge_display <= 48;
            S_ae_level_sync1 <= 3; S_ae_level_sync2 <= 3; S_ae_level_display <= 3;
            S_ae_value_sync1 <= 16'd1800;
            S_ae_value_sync2 <= 16'd1800;
            S_ae_value_display <= 16'd1800;
            S_ae_mode_sync1 <= 1'b1;
            S_ae_mode_sync2 <= 1'b1;
            S_ae_mode_display <= 1'b1;
            S_tracking_mode_sync1 <= 1'b0;
            S_tracking_mode_sync2 <= 1'b0;
            S_tracking_mode_display <= 1'b0;
        end else begin
            S_mode_sync1 <= I_algo_mode;
            S_ae_level_sync1 <= I_ae_target_level;
            S_ae_level_sync2 <= S_ae_level_sync1;
            S_ae_value_sync1 <= I_ae_value;
            S_ae_value_sync2 <= S_ae_value_sync1;
            S_ae_mode_sync1 <= I_ae_mode;
            S_ae_mode_sync2 <= S_ae_mode_sync1;
            S_tracking_mode_sync1 <= I_tracking_mode;
            S_tracking_mode_sync2 <= S_tracking_mode_sync1;
            S_edge_sync1 <= I_edge_threshold;
            S_edge_sync2 <= S_edge_sync1;
            if (I_video_user) S_edge_display <= S_edge_sync2;
            S_mode_sync2 <= S_mode_sync1;
            if (I_video_user)
                S_mode_display <= S_mode_sync2;
            if (I_video_user)
                S_ae_level_display <= S_ae_level_sync2;
            if (I_video_user)
                S_ae_value_display <= S_ae_value_sync2;
            if (I_video_user)
                S_ae_mode_display <= S_ae_mode_sync2;
            if (I_video_user)
                S_tracking_mode_display <= S_tracking_mode_sync2;
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_fps_clock_count <= 27'd0;
            S_fps_frame_count <= 8'd0;
            S_fps_value <= 8'd0;
        end else if (S_fps_clock_count == PIXEL_CLOCK_HZ - 1) begin
            S_fps_clock_count <= 27'd0;
            S_fps_value <= ((S_fps_frame_count + I_video_user) > 8'd99) ?
                           8'd99 : (S_fps_frame_count + I_video_user);
            S_fps_frame_count <= 8'd0;
        end else begin
            S_fps_clock_count <= S_fps_clock_count + 27'd1;
            if (I_video_user && S_fps_frame_count != 8'hff)
                S_fps_frame_count <= S_fps_frame_count + 8'd1;
        end
    end

    always @* begin
        S_logo_pixel = logo_pixel((S_x_2d - 12'd16) >> 1,
                                  (S_y_2d - 12'd2) >> 1);
        S_fps_tens = S_fps_value / 8'd10;
        S_fps_ones = S_fps_value % 8'd10;
        S_motion_hundreds = (I_motion_count / 12'd100) % 12'd10;
        S_motion_tens = (I_motion_count / 12'd10) % 12'd10;
        S_motion_ones = I_motion_count % 12'd10;
        S_age_tens = (S_frame_age / 7'd10) % 7'd10;
        S_age_ones = S_frame_age % 7'd10;
        S_latency_tens = (S_latency_frames / 7'd10) % 7'd10;
        S_latency_ones = S_latency_frames % 7'd10;
        S_ae_thousands = (S_ae_value_display / 16'd1000) % 16'd10;
        S_ae_hundreds = (S_ae_value_display / 16'd100) % 16'd10;
        S_ae_tens = (S_ae_value_display / 16'd10) % 16'd10;
        S_ae_ones = S_ae_value_display % 16'd10;
        S_target_x_thousands = S_target_x_display / 10'd1000;
        S_target_x_hundreds = (S_target_x_display / 10'd100) % 10'd10;
        S_target_x_tens = (S_target_x_display / 10'd10) % 10'd10;
        S_target_x_ones = S_target_x_display % 10'd10;
        S_target_y_hundreds = (S_target_y_display / 10'd100) % 10'd10;
        S_target_y_tens = (S_target_y_display / 10'd10) % 10'd10;
        S_target_y_ones = S_target_y_display % 10'd10;
        S_target_outline = !S_tracking_mode_display && S_target_valid_display &&
            (((S_x_2d == S_target_x_min_display) ||
              (S_x_2d == S_target_x_max_display)) &&
             (S_y_2d >= S_target_y_min_display) &&
             (S_y_2d <= S_target_y_max_display) ||
             ((S_y_2d == S_target_y_min_display) ||
              (S_y_2d == S_target_y_max_display)) &&
             (S_x_2d >= S_target_x_min_display) &&
             (S_x_2d <= S_target_x_max_display));
        S_target_cross = !S_tracking_mode_display && S_target_valid_display &&
            (((S_x_2d + 12'd5 >= S_target_x_display) &&
              (S_x_2d <= S_target_x_display + 12'd5) &&
              ((S_y_2d + 12'd1 >= S_target_y_display) &&
               (S_y_2d <= S_target_y_display + 12'd1))) ||
             ((S_y_2d + 12'd5 >= S_target_y_display) &&
              (S_y_2d <= S_target_y_display + 12'd5) &&
              ((S_x_2d + 12'd1 >= S_target_x_display) &&
               (S_x_2d <= S_target_x_display + 12'd1))));
        S_motion_outline = S_tracking_mode_display && S_motion_valid_display &&
            ((((S_x_2d >= S_motion_x_min_display) &&
               (S_x_2d <= S_motion_x_min_display + 12'd1)) ||
              ((S_x_2d + 12'd1 >= S_motion_x_max_display) &&
               (S_x_2d <= S_motion_x_max_display)) ||
              (((S_y_2d >= S_motion_y_min_display) &&
                (S_y_2d <= S_motion_y_min_display + 12'd1)) ||
               ((S_y_2d + 12'd1 >= S_motion_y_max_display) &&
                (S_y_2d <= S_motion_y_max_display)))) &&
             (S_x_2d >= S_motion_x_min_display) &&
             (S_x_2d <= S_motion_x_max_display) &&
             (S_y_2d >= S_motion_y_min_display) &&
             (S_y_2d <= S_motion_y_max_display));
        S_text_group = 4'd15;
        S_text_index = 5'd0;
        S_text_x0 = 12'd0;
        S_text_y0 = 12'd0;

        if ((S_y_2d >= 12'd8) && (S_y_2d < 12'd22) &&
            (S_x_2d >= 12'd128) && (S_x_2d < 12'd260)) begin
            S_text_group = 4'd0;
            S_text_index = (S_x_2d - 12'd128) / 12'd12;
            S_text_x0 = 12'd128;
            S_text_y0 = 12'd8;
        end else if ((S_y_2d >= 12'd34) && (S_y_2d < 12'd48) &&
                     (S_x_2d >= 12'd128) && (S_x_2d < 12'd272)) begin
            S_text_group = 4'd1;
            S_text_index = (S_x_2d - 12'd128) / 12'd12;
            S_text_x0 = 12'd128;
            S_text_y0 = 12'd34;
        end else if ((S_y_2d >= 12'd24) && (S_y_2d < 12'd38) &&
                     (S_x_2d >= 12'd470) && (S_x_2d < 12'd662)) begin
            S_text_group = 4'd2;
            S_text_index = (S_x_2d - 12'd470) / 12'd12;
            S_text_x0 = 12'd470;
            S_text_y0 = 12'd24;
        end else if ((S_y_2d >= 12'd24) && (S_y_2d < 12'd38) &&
                     (S_x_2d >= 12'd770) && (S_x_2d < 12'd1000)) begin
            S_text_group = 4'd3;
            S_text_index = (S_x_2d - 12'd770) / 12'd12;
            S_text_x0 = 12'd770;
            S_text_y0 = 12'd24;
        end else if ((S_y_2d >= 12'd44) && (S_y_2d < 12'd58) &&
                     (S_x_2d >= 12'd1020) && (S_x_2d < 12'd1164)) begin
            S_text_group = 4'd10;
            S_text_index = (S_x_2d - 12'd1020) / 12'd12;
            S_text_x0 = 12'd1020;
            S_text_y0 = 12'd44;
        end else if ((S_y_2d >= FOOTER_TEXT_Y) && (S_y_2d < FOOTER_TEXT_Y + 12'd14) &&
                     (S_x_2d >= 12'd46) && (S_x_2d < 12'd166)) begin
            S_text_group = 4'd4;
            S_text_index = (S_x_2d - 12'd46) / 12'd12;
            S_text_x0 = 12'd46;
            S_text_y0 = FOOTER_TEXT_Y;
        end else if ((S_y_2d >= FOOTER_TEXT_Y) && (S_y_2d < FOOTER_TEXT_Y + 12'd14) &&
                     (S_x_2d >= 12'd1095) && (S_x_2d < 12'd1251)) begin
            S_text_group = 4'd5;
            S_text_index = (S_x_2d - 12'd1095) / 12'd12;
            S_text_x0 = 12'd1095;
            S_text_y0 = FOOTER_TEXT_Y;
        end else if ((S_y_2d >= FOOTER_TEXT_Y) && (S_y_2d < FOOTER_TEXT_Y + 12'd14) &&
                     (S_x_2d >= 12'd443) && (S_x_2d < 12'd623)) begin
            S_text_group = 4'd6;
            S_text_index = (S_x_2d - 12'd443) / 12'd12;
            S_text_x0 = 12'd443;
            S_text_y0 = FOOTER_TEXT_Y;
        end else if ((S_y_2d >= FOOTER_TEXT_Y) && (S_y_2d < FOOTER_TEXT_Y + 12'd14) &&
                     (S_x_2d >= 12'd675) && (S_x_2d < 12'd819)) begin
            S_text_group = 4'd7;
            S_text_index = (S_x_2d - 12'd675) / 12'd12;
            S_text_x0 = 12'd675;
            S_text_y0 = FOOTER_TEXT_Y;
        end else if ((S_y_2d >= FOOTER_TEXT_Y) && (S_y_2d < FOOTER_TEXT_Y + 12'd14) &&
                     (S_x_2d >= 12'd918) && (S_x_2d < 12'd1002)) begin
            S_text_group = 4'd8;
            S_text_index = (S_x_2d - 12'd918) / 12'd12;
            S_text_x0 = 12'd918;
            S_text_y0 = FOOTER_TEXT_Y;
        end else if ((S_y_2d >= FOOTER_TEXT_Y) && (S_y_2d < FOOTER_TEXT_Y + 12'd14) &&
                     (S_x_2d >= 12'd230) && (S_x_2d < 12'd410)) begin
            S_text_group = 4'd9;
            S_text_index = (S_x_2d - 12'd230) / 12'd12;
            S_text_x0 = 12'd230;
            S_text_y0 = FOOTER_TEXT_Y;
        end

        S_text_char = ui_char(S_text_group, S_text_index, S_mode_display,
                              S_fps_tens, S_fps_ones,
                              S_motion_hundreds, S_motion_tens,
                              S_motion_ones, S_age_tens, S_age_ones,
                              S_target_valid_display,
                              S_target_x_thousands, S_target_x_hundreds,
                              S_target_x_tens, S_target_x_ones,
                              S_target_y_hundreds, S_target_y_tens,
                              S_target_y_ones, S_latency_tens,
                              S_latency_ones);
        S_text_row = font5x7(S_text_char, (S_y_2d - S_text_y0) >> 1);
        S_text_pixel = 1'b0;
        if ((S_text_group != 4'd15) &&
            (((S_x_2d - S_text_x0) % 12'd12) < 12'd10))
            S_text_pixel = S_text_row[12'd4 - ((S_x_2d - S_text_x0) % 12'd12) / 12'd2];
    end

    always @* begin
        // video_out returns a pixel two sampling edges after its request.
        // S_x_2d/S_y_2d and S_video_de_2d describe that same pixel.
        S_pixel = I_video_rd_data;
        if ((ENABLE_OSD == 0) || !I_osd_enable) begin
            S_pixel = I_video_rd_data;
        end else if (S_y_2d < 12'd68) begin
            S_pixel = C_TOP_BG;
            if ((S_x_2d >= 12'd16) && (S_x_2d < 12'd112) &&
                (S_y_2d >= 12'd2) && (S_y_2d < 12'd66)) begin
                case (S_logo_pixel)
                    4'd1: S_pixel = C_NAVY;
                    4'd2: S_pixel = C_RED;
                    default: S_pixel = C_TOP_BG;
                endcase
            end else if (S_text_pixel) begin
                if (S_text_group == 4'd0)
                    S_pixel = C_WHITE;
                else if (S_text_group == 4'd1)
                    S_pixel = C_MUTED;
                else if (S_text_group == 4'd2)
                    S_pixel = C_CYAN;
                else if (S_text_group == 4'd3)
                    S_pixel = C_WHITE;
                else if (S_text_group == 4'd10)
                    S_pixel = S_hand_valid_display ? C_CYAN : C_MUTED;
            end
            if ((S_x_2d >= 12'd440) && (S_x_2d < 12'd444) &&
                (S_y_2d >= 12'd19) && (S_y_2d < 12'd48))
                S_pixel = C_CYAN;
            if ((S_x_2d >= 12'd760) && (S_x_2d < 12'd764) &&
                (S_y_2d >= 12'd19) && (S_y_2d < 12'd48))
                S_pixel = C_RED;
        end else if ((S_y_2d >= FOOTER_Y) && (S_y_2d < IMG_HEIGHT)) begin
            S_pixel = C_BOTTOM_BG;
            if (S_text_pixel)
                S_pixel = ((S_text_group == 4'd4) ||
                           (S_text_group == 4'd7)) ? C_CYAN : C_MUTED;
        end else begin
            if (S_motion_outline)
                S_pixel = C_MOTION_GREEN;
            if (S_target_outline || S_target_cross)
                S_pixel = C_RED;
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_video_vsync_1d <= 1'b0;
            S_video_vsync_2d <= 1'b0;
            S_video_hsync_1d <= 1'b0;
            S_video_hsync_2d <= 1'b0;
            S_video_de_1d <= 1'b0;
            S_video_de_2d <= 1'b0;
            S_video_data_1d <= 24'd0;
            S_video_data_2d <= 24'd0;
            O_hdmi_vsync <= 1'b0;
            O_hdmi_hsync <= 1'b0;
            O_hdmi_de <= 1'b0;
            O_hdmi_data <= 24'd0;
        end else begin
            S_video_vsync_1d <= I_video_vsync;
            S_video_vsync_2d <= S_video_vsync_1d;
            O_hdmi_vsync <= S_video_vsync_2d;
            S_video_hsync_1d <= I_video_hsync;
            S_video_hsync_2d <= S_video_hsync_1d;
            O_hdmi_hsync <= S_video_hsync_2d;
            S_video_de_1d <= I_video_de;
            S_video_de_2d <= S_video_de_1d;
            O_hdmi_de <= S_video_de_2d;
            S_video_data_1d <= I_video_rd_data;
            S_video_data_2d <= S_video_data_1d;
            if (DEBUG_MODE == 0)
                O_hdmi_data <= S_pixel;
            else if (S_video_de_2d)
                O_hdmi_data <= I_debug_status[0] ? 24'h00ff00 : 24'hff0000;
            else
                O_hdmi_data <= 24'd0;
        end
    end

    function [3:0] logo_pixel;
        input [5:0] px;
        input [4:0] py;
        reg [191:0] row_data;
        begin
            row_data = 192'd0;
            case (py)
                0:row_data=192'h000000000000000102222222222222222222222222222222;
                1:row_data=192'h000000000000000100222222222222222222222222222220;
                2:row_data=192'h000000000000001100000000000000000000000000000000;
                3:row_data=192'h000000000000001110000000000000000000000000000000;
                4:row_data=192'h000000000000011111022222222222222222222222222200;
                5:row_data=192'h000000000000011111002222222222222222222222222000;
                6:row_data=192'h000000000000111111100000000000000000000000000000;
                7:row_data=192'h000000000000111111100000000000000000000000000000;
                8:row_data=192'h000000000001111111110222222222222222222222220000;
                9:row_data=192'h000000000001111111110000000000000000000000000000;
                10:row_data=192'h000000000011111111111000000000000000000000000000;
                11:row_data=192'h000000000011111111111002222222222222222222000000;
                12:row_data=192'h000000000111111111111002222222222222222222000000;
                13:row_data=192'h000000000111111111111100000000000000000000000000;
                14:row_data=192'h000000000111111111111100000000000000000000000000;
                15:row_data=192'h000000001111111011111110022222222222222200000000;
                16:row_data=192'h000000001111110011111111022222222222222200000000;
                17:row_data=192'h000000011111110001111111000000000000000000000000;
                18:row_data=192'h000000011111100000111111000000000000000000000000;
                19:row_data=192'h000000111111100000111111102222222222222000000000;
                20:row_data=192'h000000111111000000111111110222222222220000000000;
                21:row_data=192'h000001111111000000011111110000000000000000000000;
                22:row_data=192'h000001111110000000001111110000000000000000000000;
                23:row_data=192'h000011111110000000001111111022222222200000000000;
                24:row_data=192'h000011111100000000000111111000000000000000000000;
                25:row_data=192'h000111111100000000000111111100000000000000000000;
                26:row_data=192'h000111111111111110000011111100222220000000000000;
                27:row_data=192'h001111111111111111000011111110222220000000000000;
                28:row_data=192'h001111111111111111000001111111000000000000000000;
                29:row_data=192'h011111111111111111100001111111000000000000000000;
                30:row_data=192'h011111111111111111100000111111002000000000000000;
                31:row_data=192'h111111111111111111110000111111102000000000000000;
                default:row_data=192'd0;
            endcase
            if (px < 6'd48)
                logo_pixel = row_data >> ((6'd47 - px) * 4);
            else
                logo_pixel = 4'd0;
        end
    endfunction

    function [7:0] ui_char;
        input [3:0] group_id;
        input [4:0] index;
        input [2:0] mode;
        input [7:0] fps_tens;
        input [7:0] fps_ones;
        input [7:0] motion_hundreds;
        input [7:0] motion_tens;
        input [7:0] motion_ones;
        input [7:0] age_tens;
        input [7:0] age_ones;
        input target_valid;
        input [7:0] target_x_thousands;
        input [7:0] target_x_hundreds;
        input [7:0] target_x_tens;
        input [7:0] target_x_ones;
        input [7:0] target_y_hundreds;
        input [7:0] target_y_tens;
        input [7:0] target_y_ones;
        input [7:0] latency_tens;
        input [7:0] latency_ones;
        begin
            ui_char = 8'h20;
            case (group_id)
                4'd0: case (index)
                    0:ui_char="A"; 1:ui_char="N"; 2:ui_char="L"; 3:ui_char="U";
                    4:ui_char=" "; 5:ui_char="V"; 6:ui_char="I"; 7:ui_char="S";
                    8:ui_char="I"; 9:ui_char="O"; 10:ui_char="N";
                    default:ui_char=" ";
                endcase
                4'd1: case (index)
                    0:ui_char="R"; 1:ui_char="E"; 2:ui_char="A"; 3:ui_char="L";
                    4:ui_char="T"; 5:ui_char="I"; 6:ui_char="M"; 7:ui_char="E";
                    8:ui_char=" "; 9:ui_char="I"; 10:ui_char="S"; 11:ui_char="P";
                    default:ui_char=" ";
                endcase
                4'd2: begin
                    case (index)
                        0:ui_char="M"; 1:ui_char="O"; 2:ui_char="D"; 3:ui_char="E";
                        4:ui_char=":"; 5:ui_char=" ";
                        6:case(mode)
                            0:ui_char="R"; 1:ui_char="G"; 2:ui_char="B";
                            3:ui_char="I"; 4:ui_char="R"; 5:ui_char="S"; 6:ui_char="C";
                            7:ui_char="H";
                            default:ui_char="?";
                        endcase
                        7:case(mode)
                            0:ui_char="G"; 1:ui_char="R"; 2:ui_char="I";
                            3:ui_char="N"; 4:ui_char="E"; 5:ui_char="O"; 6:ui_char="A";
                            7:ui_char="I";
                            default:ui_char=" ";
                        endcase
                        8:case(mode)
                            0:ui_char="B";
                            1:ui_char="A"; 2:ui_char="N"; 3:ui_char="V";
                            4:ui_char="D"; 5:ui_char="B"; 6:ui_char="R";
                            7:ui_char="S";
                            default:ui_char=" ";
                        endcase
                        9:case(mode)
                            1:ui_char="Y"; 3:ui_char="V"; 5:ui_char="E"; 6:ui_char="T";
                            7:ui_char="T";
                            default:ui_char=" ";
                        endcase
                        10:case(mode)
                            3:ui_char="T"; 5:ui_char="L"; 6:ui_char="O";
                            7:ui_char="E";
                            default:ui_char=" ";
                        endcase
                        11:if(mode==7) ui_char="Q"; else if(mode==6) ui_char="O"; else ui_char=" ";
                        12:if(mode==6) ui_char="N"; else ui_char=" ";
                        13:if(mode==5) ui_char="T"; else ui_char=" ";
                        14:if(mode==5) ui_char=8'd48+(S_edge_display/8'd10); else ui_char=" ";
                        15:if(mode==5) ui_char=8'd48+(S_edge_display%8'd10); else ui_char=" ";
                        default:ui_char=" ";
                    endcase
                end
                4'd3: case (index)
                    0:ui_char="H"; 1:ui_char="D"; 2:ui_char="M"; 3:ui_char="I";
                    4:ui_char=" "; 5:ui_char="F"; 6:ui_char="P"; 7:ui_char="S";
                    8:ui_char=":"; 9:ui_char=" "; 10:ui_char=8'd48+fps_tens;
                    11:ui_char=8'd48+fps_ones;
                    default:ui_char=" ";
                endcase
                4'd4: case(index)
                    0:ui_char="M"; 1:ui_char="I"; 2:ui_char="P"; 3:ui_char="I";
                    4:ui_char=" "; 5:ui_char="I"; 6:ui_char="N"; 7:ui_char="P";
                    8:ui_char="U"; 9:ui_char="T"; default:ui_char=" ";
                endcase
                4'd5: case(index)
                    0:ui_char="H"; 1:ui_char="D"; 2:ui_char="M"; 3:ui_char="I";
                    4:ui_char=" "; 5:ui_char=8'd48+(IMG_WIDTH/1000)%10;
                    6:ui_char=8'd48+(IMG_WIDTH/100)%10;
                    7:ui_char=8'd48+(IMG_WIDTH/10)%10;
                    8:ui_char=8'd48+IMG_WIDTH%10; 9:ui_char="X";
                    10:ui_char=8'd48+(IMG_HEIGHT/100)%10;
                    11:ui_char=8'd48+(IMG_HEIGHT/10)%10;
                    12:ui_char=8'd48+IMG_HEIGHT%10; default:ui_char=" ";
                endcase
                4'd6: case(index)
                    0:ui_char="M"; 1:ui_char="O"; 2:ui_char="T"; 3:ui_char=":";
                    4:ui_char=8'd48+motion_hundreds;
                    5:ui_char=8'd48+motion_tens;
                    6:ui_char=8'd48+motion_ones;
                    7:ui_char=" "; 8:ui_char="A"; 9:ui_char="G"; 10:ui_char="E";
                    11:ui_char=":"; 12:ui_char=8'd48+age_tens;
                    13:ui_char=8'd48+age_ones; 14:ui_char="F";
                    default:ui_char=" ";
                endcase
                4'd7: begin
                    if (target_valid) begin
                        case (index)
                            0:ui_char="X"; 1:ui_char=":";
                            2:ui_char=8'd48+target_x_thousands;
                            3:ui_char=8'd48+target_x_hundreds;
                            4:ui_char=8'd48+target_x_tens;
                            5:ui_char=8'd48+target_x_ones;
                            6:ui_char=" ";
                            7:ui_char="Y"; 8:ui_char=":";
                            9:ui_char=8'd48+target_y_hundreds;
                            10:ui_char=8'd48+target_y_tens;
                            11:ui_char=8'd48+target_y_ones;
                            default:ui_char=" ";
                        endcase
                    end else begin
                        case (index)
                            0:ui_char="N"; 1:ui_char="O"; 2:ui_char=" ";
                            3:ui_char="T"; 4:ui_char="A"; 5:ui_char="R";
                            6:ui_char="G"; 7:ui_char="E"; 8:ui_char="T";
                            default:ui_char=" ";
                        endcase
                    end
                end
                4'd9: begin
                    if (S_ae_mode_display) begin
                        case (index)
                            0:ui_char="A"; 1:ui_char="E"; 2:ui_char=":";
                            3:ui_char=8'd48+S_ae_thousands;
                            4:ui_char=8'd48+S_ae_hundreds;
                            5:ui_char=8'd48+S_ae_tens;
                            6:ui_char=8'd48+S_ae_ones;
                            7:ui_char=" ";
                             8:case (S_ae_level_display)
                                   3'd0:ui_char="0"; 3'd1:ui_char="0";
                                   3'd2:ui_char="1"; 3'd3:ui_char="1";
                                   3'd4:ui_char="2"; default:ui_char="2";
                               endcase
                             9:case (S_ae_level_display)
                                   3'd0:ui_char="0"; 3'd1:ui_char="5";
                                   3'd2:ui_char="0"; 3'd3:ui_char="5";
                                   3'd4:ui_char="0"; default:ui_char="5";
                               endcase
                             10:ui_char="0";
                            11:ui_char="-";
                             12:case (S_ae_level_display)
                                   3'd0:ui_char="0"; 3'd1:ui_char="1";
                                   3'd2:ui_char="1"; 3'd3:ui_char="2";
                                   3'd4:ui_char="2"; default:ui_char="2";
                               endcase
                             13:case (S_ae_level_display)
                                   3'd0:ui_char="5"; 3'd1:ui_char="0";
                                   3'd2:ui_char="5"; 3'd3:ui_char="0";
                                   3'd4:ui_char="5"; default:ui_char="5";
                               endcase
                             14:case (S_ae_level_display)
                                   3'd5:ui_char="5"; default:ui_char="0";
                               endcase
                            default:ui_char=" ";
                        endcase
                    end else begin
                        case (index)
                            0:ui_char="A"; 1:ui_char="G"; 2:ui_char=":";
                            3:ui_char=8'd48+S_ae_thousands;
                            4:ui_char=8'd48+S_ae_hundreds;
                            5:ui_char=8'd48+S_ae_tens;
                            6:ui_char=8'd48+S_ae_ones;
                            7:ui_char=" "; 8:ui_char="M";
                            9:ui_char="A"; 10:ui_char="N";
                            default:ui_char=" ";
                        endcase
                    end
                end
                4'd8: case (index)
                    0:ui_char="L"; 1:ui_char="A"; 2:ui_char="T";
                    3:ui_char=":"; 4:ui_char=8'd48+latency_tens;
                    5:ui_char=8'd48+latency_ones;
                    6:ui_char="F";
                    default:ui_char=" ";
                endcase
                4'd10: begin
                    case(index)
                        0:ui_char="H"; 1:ui_char="A"; 2:ui_char="N"; 3:ui_char="D";
                        4:ui_char=":";
                        5:ui_char=S_hand_enable_display?(S_hand_valid_display?(8'd48+S_hand_count_display):"-"):"O";
                        6:ui_char=S_hand_enable_display?" ":"F";
                        7:ui_char=S_hand_enable_display?" ":"F";
                        8:ui_char=S_hand_enable_display?"E":" ";
                        9:ui_char=S_hand_enable_display?8'd48+S_hand_error_display:" ";
                        default:ui_char=" ";
                    endcase
                end
                default:ui_char=" ";
            endcase
        end
    endfunction

    function [4:0] font5x7;
        input [7:0] c;
        input [2:0] row;
        begin
            font5x7 = 5'b00000;
            case (c)
                "A": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=17;3:font5x7=31;4:font5x7=17;5:font5x7=17;6:font5x7=17;endcase
                "B": case(row) 0:font5x7=30;1:font5x7=17;2:font5x7=17;3:font5x7=30;4:font5x7=17;5:font5x7=17;6:font5x7=30;endcase
                "C": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=16;3:font5x7=16;4:font5x7=16;5:font5x7=17;6:font5x7=14;endcase
                "D": case(row) 0:font5x7=30;1:font5x7=17;2:font5x7=17;3:font5x7=17;4:font5x7=17;5:font5x7=17;6:font5x7=30;endcase
                "E": case(row) 0:font5x7=31;1:font5x7=16;2:font5x7=16;3:font5x7=30;4:font5x7=16;5:font5x7=16;6:font5x7=31;endcase
                "F": case(row) 0:font5x7=31;1:font5x7=16;2:font5x7=16;3:font5x7=30;4:font5x7=16;5:font5x7=16;6:font5x7=16;endcase
                "G": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=16;3:font5x7=23;4:font5x7=17;5:font5x7=17;6:font5x7=15;endcase
                "H": case(row) 0:font5x7=17;1:font5x7=17;2:font5x7=17;3:font5x7=31;4:font5x7=17;5:font5x7=17;6:font5x7=17;endcase
                "I": case(row) 0:font5x7=14;1:font5x7=4;2:font5x7=4;3:font5x7=4;4:font5x7=4;5:font5x7=4;6:font5x7=14;endcase
                "L": case(row) 0:font5x7=16;1:font5x7=16;2:font5x7=16;3:font5x7=16;4:font5x7=16;5:font5x7=16;6:font5x7=31;endcase
                "M": case(row) 0:font5x7=17;1:font5x7=27;2:font5x7=21;3:font5x7=21;4:font5x7=17;5:font5x7=17;6:font5x7=17;endcase
                "N": case(row) 0:font5x7=17;1:font5x7=25;2:font5x7=25;3:font5x7=21;4:font5x7=19;5:font5x7=19;6:font5x7=17;endcase
                "O": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=17;3:font5x7=17;4:font5x7=17;5:font5x7=17;6:font5x7=14;endcase
                "P": case(row) 0:font5x7=30;1:font5x7=17;2:font5x7=17;3:font5x7=30;4:font5x7=16;5:font5x7=16;6:font5x7=16;endcase
                "Q": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=17;3:font5x7=17;4:font5x7=21;5:font5x7=18;6:font5x7=13;endcase
                "R": case(row) 0:font5x7=30;1:font5x7=17;2:font5x7=17;3:font5x7=30;4:font5x7=20;5:font5x7=18;6:font5x7=17;endcase
                "S": case(row) 0:font5x7=15;1:font5x7=16;2:font5x7=16;3:font5x7=14;4:font5x7=1;5:font5x7=1;6:font5x7=30;endcase
                "T": case(row) 0:font5x7=31;1:font5x7=4;2:font5x7=4;3:font5x7=4;4:font5x7=4;5:font5x7=4;6:font5x7=4;endcase
                "U": case(row) 0:font5x7=17;1:font5x7=17;2:font5x7=17;3:font5x7=17;4:font5x7=17;5:font5x7=17;6:font5x7=14;endcase
                "V": case(row) 0:font5x7=17;1:font5x7=17;2:font5x7=17;3:font5x7=17;4:font5x7=17;5:font5x7=10;6:font5x7=4;endcase
                "X": case(row) 0:font5x7=17;1:font5x7=17;2:font5x7=10;3:font5x7=4;4:font5x7=10;5:font5x7=17;6:font5x7=17;endcase
                "Y": case(row) 0:font5x7=17;1:font5x7=17;2:font5x7=10;3:font5x7=4;4:font5x7=4;5:font5x7=4;6:font5x7=4;endcase
                "0": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=19;3:font5x7=21;4:font5x7=25;5:font5x7=17;6:font5x7=14;endcase
                "1": case(row) 0:font5x7=4;1:font5x7=12;2:font5x7=4;3:font5x7=4;4:font5x7=4;5:font5x7=4;6:font5x7=14;endcase
                "2": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=1;3:font5x7=2;4:font5x7=4;5:font5x7=8;6:font5x7=31;endcase
                "3": case(row) 0:font5x7=30;1:font5x7=1;2:font5x7=1;3:font5x7=14;4:font5x7=1;5:font5x7=1;6:font5x7=30;endcase
                "4": case(row) 0:font5x7=2;1:font5x7=6;2:font5x7=10;3:font5x7=18;4:font5x7=31;5:font5x7=2;6:font5x7=2;endcase
                "5": case(row) 0:font5x7=31;1:font5x7=16;2:font5x7=16;3:font5x7=30;4:font5x7=1;5:font5x7=1;6:font5x7=30;endcase
                "6": case(row) 0:font5x7=6;1:font5x7=8;2:font5x7=16;3:font5x7=30;4:font5x7=17;5:font5x7=17;6:font5x7=14;endcase
                "7": case(row) 0:font5x7=31;1:font5x7=1;2:font5x7=2;3:font5x7=4;4:font5x7=8;5:font5x7=8;6:font5x7=8;endcase
                "8": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=17;3:font5x7=14;4:font5x7=17;5:font5x7=17;6:font5x7=14;endcase
                "9": case(row) 0:font5x7=14;1:font5x7=17;2:font5x7=17;3:font5x7=15;4:font5x7=1;5:font5x7=2;6:font5x7=12;endcase
                ":": case(row) 2:font5x7=4;3:font5x7=0;4:font5x7=4;default:font5x7=0;endcase
                "-": if (row == 3) font5x7 = 5'b11111;
                default: font5x7 = 5'b00000;
            endcase
        end
    endfunction
endmodule
