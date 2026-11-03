module gimbal_servo_test #(
    parameter integer CLK_FREQ_HZ = 100000000,
    parameter integer CENTER_ANGLE = 90,
    parameter integer MIN_ANGLE = 80,
    parameter integer MAX_ANGLE = 100,
    parameter integer STEP_ANGLE = 2
)(
    input  wire I_clk,
    input  wire I_rst_n,
    input  wire I_test_enable,
    input  wire I_step_up,
    input  wire I_step_down,
    output wire O_pan_pwm,
    output wire O_tilt_pwm
);
    localparam integer US_DIV = CLK_FREQ_HZ / 1000000;
    localparam integer US_DIV_WIDTH = (US_DIV <= 2) ? 1 : $clog2(US_DIV);
    localparam integer PERIOD_WIDTH = 15;

    reg [1:0] enable_sync;
    reg [7:0] pan_angle;
    reg [12:0] pan_pulse_us;
    reg [3:0] pan_pulse_remainder;
    reg [US_DIV_WIDTH-1:0] us_div_count;
    reg [PERIOD_WIDTH-1:0] period_us_count;
    reg [12:0] active_pan_pulse_us;

    assign O_pan_pwm = (period_us_count < active_pan_pulse_us);
    assign O_tilt_pwm = (period_us_count < 13'd1500);

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n)
            enable_sync <= 2'b00;
        else
            enable_sync <= {enable_sync[0], I_test_enable};
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            pan_angle <= CENTER_ANGLE;
            pan_pulse_us <= 13'd1500;
            pan_pulse_remainder <= 4'd4;
        end else if (!enable_sync[1]) begin
            pan_angle <= CENTER_ANGLE;
            pan_pulse_us <= 13'd1500;
            pan_pulse_remainder <= 4'd4;
        end
        else if (I_step_up && !I_step_down) begin
            if (pan_angle <= MAX_ANGLE - STEP_ANGLE) begin
                pan_angle <= pan_angle + STEP_ANGLE;
                if (pan_angle == MAX_ANGLE - STEP_ANGLE) begin
                    pan_pulse_us <= 13'd2500;
                    pan_pulse_remainder <= 4'd4;
                end else if (pan_pulse_remainder + 4'd2 >= 4'd9) begin
                    pan_pulse_us <= pan_pulse_us + 13'd23;
                    pan_pulse_remainder <= pan_pulse_remainder + 4'd2 - 4'd9;
                end else begin
                    pan_pulse_us <= pan_pulse_us + 13'd22;
                    pan_pulse_remainder <= pan_pulse_remainder + 4'd2;
                end
            end else begin
                pan_angle <= MAX_ANGLE;
                pan_pulse_us <= 13'd2500;
                pan_pulse_remainder <= 4'd4;
            end
        end else if (I_step_down && !I_step_up) begin
            if (pan_angle >= MIN_ANGLE + STEP_ANGLE) begin
                pan_angle <= pan_angle - STEP_ANGLE;
                if (pan_angle == MIN_ANGLE + STEP_ANGLE) begin
                    pan_pulse_us <= 13'd500;
                    pan_pulse_remainder <= 4'd4;
                end else if (pan_pulse_remainder >= 4'd2) begin
                    pan_pulse_us <= pan_pulse_us - 13'd22;
                    pan_pulse_remainder <= pan_pulse_remainder - 4'd2;
                end else begin
                    pan_pulse_us <= pan_pulse_us - 13'd23;
                    pan_pulse_remainder <= pan_pulse_remainder + 4'd7;
                end
            end else begin
                pan_angle <= MIN_ANGLE;
                pan_pulse_us <= 13'd500;
                pan_pulse_remainder <= 4'd4;
            end
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            us_div_count <= {US_DIV_WIDTH{1'b0}};
            period_us_count <= {PERIOD_WIDTH{1'b0}};
            active_pan_pulse_us <= 13'd1500;
        end else if (us_div_count == US_DIV - 1) begin
            us_div_count <= {US_DIV_WIDTH{1'b0}};
            if (period_us_count == 15'd19999) begin
                period_us_count <= {PERIOD_WIDTH{1'b0}};
                active_pan_pulse_us <= pan_pulse_us;
            end else
                period_us_count <= period_us_count + 1'b1;
        end else begin
            us_div_count <= us_div_count + 1'b1;
        end
    end
endmodule
