module gimbal_red_tracker #(
    parameter integer CLK_FREQ_HZ = 100000000,
    parameter integer IMG_WIDTH = 1280,
    parameter integer IMG_HEIGHT = 720,
    parameter integer DEAD_BAND_PIXELS = 50,
    parameter integer MAX_STEP_PER_UPDATE = 2,
    parameter integer UPDATE_INTERVAL_MS = 100,
    parameter integer CONFIRM_FRAMES = 3,
    parameter integer PAN_REVERSE = 1,
    parameter integer TILT_REVERSE = 1
)(
    input wire I_clk, input wire I_rst_n, input wire I_enable,
    input wire I_target_frame_toggle, input wire I_target_valid,
    input wire [10:0] I_target_center_x, input wire [10:0] I_target_center_y,
    output wire O_pan_pwm, output wire O_tilt_pwm
);
    localparam integer US_DIV = CLK_FREQ_HZ / 1000000;
    localparam integer US_DIV_WIDTH = (US_DIV <= 2) ? 1 : $clog2(US_DIV);
    localparam integer PERIOD_WIDTH = 15;
    localparam integer PAN_CENTER = IMG_WIDTH / 2;
    localparam integer TILT_CENTER = IMG_HEIGHT / 2;
    localparam integer UPDATE_TICKS = (CLK_FREQ_HZ / 1000) * UPDATE_INTERVAL_MS;
    localparam integer UPDATE_WIDTH = (UPDATE_TICKS <= 2) ? 1 : $clog2(UPDATE_TICKS);
    localparam integer CONFIRM_WIDTH = (CONFIRM_FRAMES <= 1) ? 1 : $clog2(CONFIRM_FRAMES + 1);

    // The source holds its bundled coordinates for one video frame. Delay
    // event delivery one extra clock beyond the two-stage bus sampling.
    reg [2:0] target_toggle_sync;
    reg target_toggle_seen;
    reg [10:0] target_x_sync1, target_x_sync2;
    reg [10:0] target_y_sync1, target_y_sync2;
    reg target_valid_sync1, target_valid_sync2;
    reg enable_sync1, enable_sync2;
    reg [7:0] pan_angle, tilt_angle;
    reg [12:0] pan_pulse_active, tilt_pulse_active;
    reg [17:0] pan_angle_scaled, tilt_angle_scaled;
    reg [12:0] pan_pulse_next, tilt_pulse_next;
    reg [US_DIV_WIDTH-1:0] us_div_count;
    reg [PERIOD_WIDTH-1:0] period_us_count;
    reg [UPDATE_WIDTH-1:0] update_elapsed;
    reg [CONFIRM_WIDTH-1:0] valid_frames;

    function [7:0] step_angle;
        input [10:0] coordinate;
        input integer center;
        input [7:0] current_angle;
        input integer reverse_direction;
        integer delta, next_value;
        begin
            // Half-open bounds give exactly 100 pixels when the half-width
            // is 50: x=590..689 and y=310..409 for a 1280x720 frame.
            if ((coordinate < center + DEAD_BAND_PIXELS) &&
                (coordinate >= center - DEAD_BAND_PIXELS)) begin
                step_angle = current_angle;
            end else begin
                delta = (coordinate < center) ? -MAX_STEP_PER_UPDATE : MAX_STEP_PER_UPDATE;
                if (reverse_direction != 0) delta = -delta;
                next_value = current_angle + delta;
                if (next_value < 0) next_value = 0;
                if (next_value > 180) next_value = 180;
                step_angle = next_value[7:0];
            end
        end
    endfunction

    function [17:0] angle_to_scaled_numerator;
        input [7:0] angle;
        begin
            if (angle > 8'd180) angle_to_scaled_numerator = 18'd18004;
            else angle_to_scaled_numerator = angle * 18'd100 + 18'd4;
        end
    endfunction

    function [12:0] scaled_numerator_to_pulse_us;
        input [17:0] scaled_numerator;
        reg [12:0] scaled_angle;
        begin
            scaled_angle = scaled_numerator / 18'd9;
            scaled_numerator_to_pulse_us = 13'd500 + scaled_angle;
        end
    endfunction

    assign O_pan_pwm = (period_us_count < pan_pulse_active);
    assign O_tilt_pwm = (period_us_count < tilt_pulse_active);

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            target_toggle_sync <= 3'b000; target_toggle_seen <= 1'b0;
            target_x_sync1 <= 11'd0; target_x_sync2 <= 11'd0;
            target_y_sync1 <= 11'd0; target_y_sync2 <= 11'd0;
            target_valid_sync1 <= 1'b0; target_valid_sync2 <= 1'b0;
            enable_sync1 <= 1'b0; enable_sync2 <= 1'b0;
            pan_angle <= 8'd90; tilt_angle <= 8'd90;
            valid_frames <= 0;
            update_elapsed <= UPDATE_TICKS - 1;
        end else begin
            target_toggle_sync <= {target_toggle_sync[1:0], I_target_frame_toggle};
            target_x_sync1 <= I_target_center_x; target_x_sync2 <= target_x_sync1;
            target_y_sync1 <= I_target_center_y; target_y_sync2 <= target_y_sync1;
            target_valid_sync1 <= I_target_valid; target_valid_sync2 <= target_valid_sync1;
            enable_sync1 <= I_enable; enable_sync2 <= enable_sync1;
            if (update_elapsed < UPDATE_TICKS - 1)
                update_elapsed <= update_elapsed + 1'b1;
            if (!enable_sync2) valid_frames <= 0;
            if (target_toggle_sync[2] != target_toggle_seen) begin
                target_toggle_seen <= target_toggle_sync[2];
                if (enable_sync2 && target_valid_sync2 &&
                    target_x_sync2 < IMG_WIDTH && target_y_sync2 < IMG_HEIGHT) begin
                    if (valid_frames < CONFIRM_FRAMES) valid_frames <= valid_frames + 1'b1;
                    if ((valid_frames >= CONFIRM_FRAMES - 1) &&
                        (update_elapsed == UPDATE_TICKS - 1)) begin
                        // Accumulate relative to the last command, rather
                        // than deriving an absolute angle around 90 degrees.
                        pan_angle <= step_angle(target_x_sync2, PAN_CENTER, pan_angle, PAN_REVERSE);
                        tilt_angle <= step_angle(target_y_sync2, TILT_CENTER, tilt_angle, TILT_REVERSE);
                        update_elapsed <= 0;
                    end
                end else begin
                    valid_frames <= 0;
                end
            end
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            us_div_count <= {US_DIV_WIDTH{1'b0}};
            period_us_count <= {PERIOD_WIDTH{1'b0}};
            pan_pulse_active <= 13'd1500; tilt_pulse_active <= 13'd1500;
            pan_angle_scaled <= 18'd9004; tilt_angle_scaled <= 18'd9004;
            pan_pulse_next <= 13'd1500; tilt_pulse_next <= 13'd1500;
        end else if (us_div_count == US_DIV - 1) begin
            us_div_count <= {US_DIV_WIDTH{1'b0}};
            pan_angle_scaled <= angle_to_scaled_numerator(pan_angle);
            tilt_angle_scaled <= angle_to_scaled_numerator(tilt_angle);
            pan_pulse_next <= scaled_numerator_to_pulse_us(pan_angle_scaled);
            tilt_pulse_next <= scaled_numerator_to_pulse_us(tilt_angle_scaled);
            if (period_us_count == 15'd19999) begin
                period_us_count <= {PERIOD_WIDTH{1'b0}};
                pan_pulse_active <= pan_pulse_next;
                tilt_pulse_active <= tilt_pulse_next;
            end else period_us_count <= period_us_count + 1'b1;
        end else us_div_count <= us_div_count + 1'b1;
    end
endmodule
