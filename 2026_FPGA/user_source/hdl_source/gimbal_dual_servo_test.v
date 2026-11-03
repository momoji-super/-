// Manual two-axis test. Reuse the measured V2 PWM/command implementation.
// Both instances use the same clock/reset and therefore aligned 20ms frames.
// Fixed command calibration: 0..180 degrees, 2-degree steps, center 90.
// No image coordinates or motion-detection signals enter this module.
module gimbal_dual_servo_test #(
    parameter integer CLK_FREQ_HZ = 100000000
)(
    input wire I_clk,
    input wire I_rst_n,
    input wire I_test_enable,
    input wire I_pan_up,
    input wire I_pan_down,
    input wire I_tilt_up,
    input wire I_tilt_down,
    output wire O_pan_pwm,
    output wire O_tilt_pwm
);
    gimbal_servo_test #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .CENTER_ANGLE(90),
        .MIN_ANGLE(0), .MAX_ANGLE(180), .STEP_ANGLE(2)
    ) u_pan (
        .I_clk(I_clk), .I_rst_n(I_rst_n), .I_test_enable(I_test_enable),
        .I_step_up(I_pan_up), .I_step_down(I_pan_down),
        .O_pan_pwm(O_pan_pwm), .O_tilt_pwm()
    );
    gimbal_servo_test #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .CENTER_ANGLE(90),
        .MIN_ANGLE(0), .MAX_ANGLE(180), .STEP_ANGLE(2)
    ) u_tilt (
        .I_clk(I_clk), .I_rst_n(I_rst_n), .I_test_enable(I_test_enable),
        .I_step_up(I_tilt_up), .I_step_down(I_tilt_down),
        .O_pan_pwm(O_tilt_pwm), .O_tilt_pwm()
    );
endmodule
