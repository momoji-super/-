module target_detect_track_before #(
    parameter IMG_WIDTH = 1280,
    parameter IMG_HEIGHT = 720,
    parameter MOTION_THRESHOLD = 8'd20
) (
    input wire I_clk,
    input wire I_rst_n,
    input wire [95:0] I_tdata,
    input wire [95:0] I_red_tdata,
    input wire I_tvalid,
    input wire I_tuser,
    input wire I_tlast,
    output reg O_frame_toggle,
    output reg O_target_valid,
    output reg [10:0] O_x_min,
    output reg [10:0] O_y_min,
    output reg [10:0] O_x_max,
    output reg [10:0] O_y_max,
    output reg [10:0] O_center_x,
    output reg [10:0] O_center_y,
    output reg [11:0] O_motion_count,
    output reg O_motion_valid,
    output reg [10:0] O_motion_x_min,
    output reg [10:0] O_motion_y_min,
    output reg [10:0] O_motion_x_max,
    output reg [10:0] O_motion_y_max
);

    localparam GRID_WIDTH = (IMG_WIDTH + 15) / 16;
    localparam GRID_HEIGHT = (IMG_HEIGHT + 15) / 16;
    localparam GRID_SIZE = GRID_WIDTH * GRID_HEIGHT;
    localparam GRID_ADDR_WIDTH = (GRID_SIZE <= 2) ? 1 : $clog2(GRID_SIZE);

    reg [7:0] previous_luma [0:GRID_SIZE-1];
    reg [10:0] x_count;
    reg [10:0] y_count;
    reg [10:0] frame_x_min;
    reg [10:0] frame_y_min;
    reg [10:0] frame_x_max;
    reg [10:0] frame_y_max;
    reg [15:0] target_pixels;
    reg [11:0] motion_accum;
    reg motion_hit_d;
    reg [10:0] grid_x_d;
    reg [10:0] grid_y_d;
    reg [10:0] motion_x_d;
    reg [10:0] motion_y_d;
    reg [10:0] motion_x_min;
    reg [10:0] motion_y_min;
    reg [10:0] motion_x_max;
    reg [10:0] motion_y_max;
    reg previous_frame_valid;
    reg [7:0] luma_sample;
    reg [7:0] luma_old;
    reg [8:0] luma_delta;
    reg [GRID_ADDR_WIDTH-1:0] grid_addr;
    reg [7:0] luma_sample_d;
    reg [GRID_ADDR_WIDTH-1:0] grid_addr_d;
    reg luma_sample_valid_d;
    reg compare_enable_d;
    reg [2:0] red_lane_count;
    reg [1:0] red_min_lane;
    reg [1:0] red_max_lane;
    reg [10:0] beat_x_min;
    reg [10:0] beat_x_max;
    reg [10:0] next_x_min;
    reg [10:0] next_y_min;
    reg [10:0] next_x_max;
    reg [10:0] next_y_max;
    reg [10:0] pixel_x_base;
    reg [10:0] pixel_y_base;
    reg [15:0] target_count_base;
    // Register one complete AXI beat before the classification/statistics path.
    // This keeps the wide RGB threshold logic out of the counter update path.
    reg [95:0] pipe_tdata;
    reg [95:0] pipe_red_tdata;
    reg pipe_valid, pipe_user, pipe_last;
    wire [23:0] pixel0 = I_red_tdata[23:0];
    wire [23:0] pixel1 = I_red_tdata[47:24];
    wire [23:0] pixel2 = I_red_tdata[71:48];
    wire [23:0] pixel3 = I_red_tdata[95:72];
    reg [3:0] red_pixel;
    reg [16:0] target_sum;
    reg [15:0] frame_red_count;
    reg [7:0] frame_peak_r, frame_peak_margin;
    reg [10:0] frame_peak_x, frame_peak_y;
    reg [10:0] beat_peak_y;
    reg [7:0] beat_peak_r, beat_peak_margin;
    reg [10:0] beat_peak_x;
    wire [7:0] lane0_margin = pipe_red_tdata[23:16] -
                              ((pipe_red_tdata[15:8] > pipe_red_tdata[7:0]) ?
                               pipe_red_tdata[15:8] : pipe_red_tdata[7:0]);
    wire [7:0] lane1_margin = pipe_red_tdata[47:40] -
                              ((pipe_red_tdata[39:32] > pipe_red_tdata[31:24]) ?
                               pipe_red_tdata[39:32] : pipe_red_tdata[31:24]);
    wire [7:0] lane2_margin = pipe_red_tdata[71:64] -
                              ((pipe_red_tdata[63:56] > pipe_red_tdata[55:48]) ?
                               pipe_red_tdata[63:56] : pipe_red_tdata[55:48]);
    wire [7:0] lane3_margin = pipe_red_tdata[95:88] -
                              ((pipe_red_tdata[87:80] > pipe_red_tdata[79:72]) ?
                               pipe_red_tdata[87:80] : pipe_red_tdata[79:72]);
    wire lane01_pick1 = red_pixel[1] &&
                        (!red_pixel[0] ||
                         (pipe_red_tdata[47:40] > pipe_red_tdata[23:16]) ||
                         ((pipe_red_tdata[47:40] == pipe_red_tdata[23:16]) &&
                          (lane1_margin > lane0_margin)));
    wire lane23_pick3 = red_pixel[3] &&
                        (!red_pixel[2] ||
                         (pipe_red_tdata[95:88] > pipe_red_tdata[71:64]) ||
                         ((pipe_red_tdata[95:88] == pipe_red_tdata[71:64]) &&
                          (lane3_margin > lane2_margin)));
    wire lane01_valid = red_pixel[0] || red_pixel[1];
    wire lane23_valid = red_pixel[2] || red_pixel[3];
    wire [7:0] lane01_r = lane01_pick1 ? pipe_red_tdata[47:40] : pipe_red_tdata[23:16];
    wire [7:0] lane01_best_margin = lane01_pick1 ? lane1_margin : lane0_margin;
    wire [1:0] lane01_index = lane01_pick1 ? 2'd1 : 2'd0;
    wire [7:0] lane23_r = lane23_pick3 ? pipe_red_tdata[95:88] : pipe_red_tdata[71:64];
    wire [7:0] lane23_best_margin = lane23_pick3 ? lane3_margin : lane2_margin;
    wire [1:0] lane23_index = lane23_pick3 ? 2'd3 : 2'd2;
    wire lane23_wins = lane23_valid &&
                       (!lane01_valid || (lane23_r > lane01_r) ||
                        ((lane23_r == lane01_r) &&
                         (lane23_best_margin > lane01_best_margin)));
    wire red_best_valid = lane01_valid || lane23_valid;
    wire [7:0] red_best_r = lane23_wins ? lane23_r : lane01_r;
    wire [7:0] red_best_margin = lane23_wins ? lane23_best_margin : lane01_best_margin;
    wire [1:0] red_best_lane = lane23_wins ? lane23_index : lane01_index;

    function is_red_pixel;
        input [23:0] pixel;
        reg [8:0] red_ext;
        reg [8:0] green_ext;
        reg [8:0] blue_ext;
        reg [8:0] max_gb;
        reg [7:0] gb_delta;
        begin
            red_ext = {1'b0, pixel[23:16]};
            green_ext = {1'b0, pixel[15:8]};
            blue_ext = {1'b0, pixel[7:0]};
            max_gb = (green_ext > blue_ext) ? green_ext : blue_ext;
            gb_delta = (pixel[15:8] > pixel[7:0]) ?
                       pixel[15:8] - pixel[7:0] :
                       pixel[7:0] - pixel[15:8];
            // Saturated/bright neutral light and orange/magenta are rejected.
            is_red_pixel = (red_ext >= 9'd96) &&
                           (red_ext >= max_gb + 9'd48) &&
                           (({2'b0, red_ext} << 1) >= ({2'b0, max_gb} * 11'd3)) &&
                           ({2'b0, gb_delta, 2'b00} <= red_ext);
        end
    endfunction


    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            x_count <= 10'd0;
            y_count <= 10'd0;
            frame_x_min <= IMG_WIDTH - 1;
            frame_y_min <= IMG_HEIGHT - 1;
            frame_x_max <= 10'd0;
            frame_y_max <= 10'd0;
            target_pixels <= 16'd0;
            motion_accum <= 12'd0;
            motion_hit_d <= 1'b0;
            grid_x_d <= 10'd0;
            grid_y_d <= 10'd0;
            motion_x_d <= 10'd0;
            motion_y_d <= 10'd0;
            motion_x_min <= IMG_WIDTH - 1;
            motion_y_min <= IMG_HEIGHT - 1;
            motion_x_max <= 10'd0;
            motion_y_max <= 10'd0;
            previous_frame_valid <= 1'b0;
            O_frame_toggle <= 1'b0;
            O_target_valid <= 1'b0;
            O_x_min <= 10'd0;
            O_y_min <= 10'd0;
            O_x_max <= 10'd0;
            O_y_max <= 10'd0;
            O_center_x <= 10'd0;
            O_center_y <= 10'd0;
            O_motion_count <= 12'd0;
            O_motion_valid <= 1'b0;
            O_motion_x_min <= 10'd0;
            O_motion_y_min <= 10'd0;
            O_motion_x_max <= 10'd0;
            O_motion_y_max <= 10'd0;
            luma_sample <= 8'd0;
            luma_old <= 8'd0;
            luma_delta <= 9'd0;
            grid_addr <= {GRID_ADDR_WIDTH{1'b0}};
            luma_sample_d <= 8'd0;
            grid_addr_d <= {GRID_ADDR_WIDTH{1'b0}};
            luma_sample_valid_d <= 1'b0;
            compare_enable_d <= 1'b0;
            red_lane_count <= 3'd0;
            red_min_lane <= 2'd0;
            red_max_lane <= 2'd0;
            beat_x_min <= 10'd0;
            beat_x_max <= 10'd0;
            next_x_min = IMG_WIDTH - 1;
            next_y_min = IMG_HEIGHT - 1;
            next_x_max = 10'd0;
            next_y_max = 10'd0;
            pixel_x_base = 10'd0;
            pixel_y_base = 10'd0;
            target_count_base = 16'd0;
            pipe_tdata <= 96'd0;
            pipe_red_tdata <= 96'd0;
            red_pixel <= 4'd0;
            target_sum = 17'd0;
            frame_red_count <= 16'd0;
            frame_peak_r <= 8'd0;
            frame_peak_margin <= 8'd0;
            frame_peak_x <= 11'd0;
            frame_peak_y <= 11'd0;
            beat_peak_r = 8'd0;
            beat_peak_margin = 8'd0;
            beat_peak_x = 11'd0;
            beat_peak_y = 11'd0;
            pipe_valid <= 1'b0;
            pipe_user <= 1'b0;
            pipe_last <= 1'b0;
        end else begin
            pipe_tdata <= I_tdata;
            pipe_red_tdata <= I_red_tdata;
            red_pixel <= {is_red_pixel(pixel3), is_red_pixel(pixel2),
                          is_red_pixel(pixel1), is_red_pixel(pixel0)};
            pipe_valid <= I_tvalid;
            pipe_user <= I_tuser;
            pipe_last <= I_tlast;
            motion_hit_d <= 1'b0;
            luma_sample_valid_d <= 1'b0;
            if (luma_sample_valid_d) begin
                luma_old = previous_luma[grid_addr_d];
                previous_luma[grid_addr_d] <= luma_sample_d;
                luma_delta = (luma_sample_d >= luma_old) ?
                             (luma_sample_d - luma_old) :
                             (luma_old - luma_sample_d);
                motion_hit_d <= compare_enable_d &&
                                (luma_delta >= MOTION_THRESHOLD);
                motion_x_d <= grid_x_d;
                motion_y_d <= grid_y_d;
            end
            if (pipe_user) begin
                O_frame_toggle <= ~O_frame_toggle;
                O_target_valid <= (frame_red_count >= 16'd3);
                if (frame_red_count >= 16'd3) begin
                    O_center_x <= frame_peak_x;
                    O_center_y <= frame_peak_y;
                    O_x_min <= (frame_peak_x < 11'd8) ? 11'd0 : frame_peak_x - 11'd8;
                    O_y_min <= (frame_peak_y < 11'd8) ? 11'd0 : frame_peak_y - 11'd8;
                    O_x_max <= (frame_peak_x + 11'd8 >= IMG_WIDTH) ? IMG_WIDTH - 1 : frame_peak_x + 11'd8;
                    O_y_max <= (frame_peak_y + 11'd8 >= IMG_HEIGHT) ? IMG_HEIGHT - 1 : frame_peak_y + 11'd8;
                end
                frame_red_count <= 16'd0;
                frame_peak_r <= 8'd0;
                frame_peak_margin <= 8'd0;
                O_motion_count <= previous_frame_valid ?
                                  ((motion_accum != 12'hfff && motion_hit_d) ?
                                   motion_accum + 12'd1 : motion_accum) : 12'd0;
                O_motion_valid <= previous_frame_valid &&
                                  ((motion_accum != 12'd0) || motion_hit_d);
                if (previous_frame_valid && (motion_accum != 12'd0 || motion_hit_d)) begin
                    O_motion_x_min <= (motion_hit_d && motion_x_d < motion_x_min) ?
                                      motion_x_d : motion_x_min;
                    O_motion_y_min <= (motion_hit_d && motion_y_d < motion_y_min) ?
                                      motion_y_d : motion_y_min;
                    O_motion_x_max <= (motion_hit_d && motion_x_d > motion_x_max) ?
                                      ((motion_x_d + 10'd15 >= IMG_WIDTH) ?
                                       IMG_WIDTH - 1 : motion_x_d + 10'd15) :
                                      ((motion_x_max + 10'd15 >= IMG_WIDTH) ?
                                       IMG_WIDTH - 1 : motion_x_max + 10'd15);
                    O_motion_y_max <= (motion_hit_d && motion_y_d > motion_y_max) ?
                                      ((motion_y_d + 10'd15 >= IMG_HEIGHT) ?
                                       IMG_HEIGHT - 1 : motion_y_d + 10'd15) :
                                      ((motion_y_max + 10'd15 >= IMG_HEIGHT) ?
                                       IMG_HEIGHT - 1 : motion_y_max + 10'd15);
                end
                x_count <= 10'd0;
                y_count <= 10'd0;
                frame_x_min <= IMG_WIDTH - 1;
                frame_y_min <= IMG_HEIGHT - 1;
                frame_x_max <= 10'd0;
                frame_y_max <= 10'd0;
                target_pixels <= 16'd0;
                motion_accum <= 12'd0;
                motion_hit_d <= 1'b0;
                motion_x_min <= IMG_WIDTH - 1;
                motion_y_min <= IMG_HEIGHT - 1;
                motion_x_max <= 10'd0;
                motion_y_max <= 10'd0;
            end

            if (motion_hit_d && !pipe_user && (motion_accum != 12'hfff)) begin
                motion_accum <= motion_accum + 12'd1;
                if (motion_x_d < motion_x_min)
                    motion_x_min <= motion_x_d;
                if (motion_y_d < motion_y_min)
                    motion_y_min <= motion_y_d;
                if (motion_x_d > motion_x_max)
                    motion_x_max <= motion_x_d;
                if (motion_y_d > motion_y_max)
                    motion_y_max <= motion_y_d;
            end

            if (pipe_valid) begin
                pixel_x_base = pipe_user ? 10'd0 : x_count;
                pixel_y_base = pipe_user ? 10'd0 : y_count;
                target_count_base = pipe_user ? 16'd0 : target_pixels;
                next_x_min = pipe_user ? IMG_WIDTH - 1 : frame_x_min;
                next_y_min = pipe_user ? IMG_HEIGHT - 1 : frame_y_min;
                next_x_max = pipe_user ? 10'd0 : frame_x_max;
                next_y_max = pipe_user ? 10'd0 : frame_y_max;
                red_lane_count = {2'd0, red_pixel[0]} +
                                 {2'd0, red_pixel[1]} +
                                 {2'd0, red_pixel[2]} +
                                 {2'd0, red_pixel[3]};
                beat_peak_r = pipe_user ? 8'd0 : frame_peak_r;
                beat_peak_margin = pipe_user ? 8'd0 : frame_peak_margin;
                beat_peak_x = pipe_user ? 11'd0 : frame_peak_x;
                beat_peak_y = pipe_user ? 11'd0 : frame_peak_y;
                if (red_best_valid &&
                    ((red_best_r > beat_peak_r) ||
                     ((red_best_r == beat_peak_r) &&
                      (red_best_margin > beat_peak_margin)))) begin
                    beat_peak_r = red_best_r;
                    beat_peak_margin = red_best_margin;
                    beat_peak_x = pixel_x_base + red_best_lane;
                    beat_peak_y = pixel_y_base;
                end
                red_lane_count = {2'd0, red_pixel[0]} +
                                 {2'd0, red_pixel[1]} +
                                 {2'd0, red_pixel[2]} +
                                 {2'd0, red_pixel[3]};
                if ((red_lane_count >= 3'd2) &&
                    ((red_pixel[0] && red_pixel[1]) ||
                     (red_pixel[1] && red_pixel[2]) ||
                     (red_pixel[2] && red_pixel[3]))) begin
                    frame_peak_r <= beat_peak_r;
                    frame_peak_margin <= beat_peak_margin;
                    frame_peak_x <= beat_peak_x;
                    frame_peak_y <= beat_peak_y;
                end
                if ((red_lane_count >= 3'd2) &&
                    ((red_pixel[0] && red_pixel[1]) ||
                     (red_pixel[1] && red_pixel[2]) ||
                     (red_pixel[2] && red_pixel[3]))) begin
                    target_sum = {1'b0, (pipe_user ? 16'd0 : frame_red_count)} + red_lane_count;
                    frame_red_count <= target_sum[16] ? 16'hffff : target_sum[15:0];
                end

                if ((pixel_x_base[3:2] == 2'b00) &&
                    (pixel_y_base[3:0] == 4'd0)) begin
                    luma_sample_d <= (pipe_tdata[23:16] >> 2) +
                                     (pipe_tdata[15:8] >> 1) +
                                     (pipe_tdata[15:8] >> 3) +
                                     (pipe_tdata[7:0] >> 4) +
                                     (pipe_tdata[7:0] >> 5);
                    grid_addr_d <= ((pixel_y_base >> 4) * GRID_WIDTH) +
                                   (pixel_x_base >> 4);
                    grid_x_d <= {pixel_x_base[10:4], 4'b0000};
                    grid_y_d <= {pixel_y_base[10:4], 4'b0000};
                    luma_sample_valid_d <= 1'b1;
                    compare_enable_d <= previous_frame_valid;
                end

                if (pipe_last) begin
                    x_count <= 10'd0;
                    if (y_count == IMG_HEIGHT - 1) begin
                        y_count <= 10'd0;
                        previous_frame_valid <= 1'b1;
                    end else begin
                        y_count <= y_count + 10'd1;
                    end
                end else begin
                    x_count <= x_count + 10'd4;
                end
            end
        end
    end
endmodule
