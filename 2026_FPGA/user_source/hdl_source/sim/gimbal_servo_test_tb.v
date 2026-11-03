`timescale 1ns/1ps

module gimbal_servo_test_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg test_enable = 1'b0;
    reg step_up = 1'b0;
    reg step_down = 1'b0;
    wire pan_pwm;
    wire tilt_pwm;

    always #5 clk = ~clk;

    gimbal_servo_test #(
        .CLK_FREQ_HZ(1000000),
        .MIN_ANGLE(0),
        .MAX_ANGLE(180)
    ) dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_test_enable(test_enable),
        .I_step_up(step_up),
        .I_step_down(step_down),
        .O_pan_pwm(pan_pwm),
        .O_tilt_pwm(tilt_pwm)
    );

    task update_angle;
        input up;
        begin
            @(negedge clk);
            step_up = up;
            step_down = !up;
            @(negedge clk);
            step_up = 1'b0;
            step_down = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    integer high_cycles;
    integer tilt_high_cycles;
    integer low_cycles;
    integer i;
    integer next_high_cycles;
    integer expected_remaining;
    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        #1;
        if (dut.pan_angle !== 8'd90 || !pan_pwm || !tilt_pwm)
            $fatal(1, "reset must hold both servos at center");

        test_enable = 1'b1;
        repeat (3) @(posedge clk);
        update_angle(1'b1);
        if (dut.pan_angle !== 8'd92 || dut.pan_pulse_us !== 13'd1522)
            $fatal(1, "up step must move pan by 2 degrees");
        if (!tilt_pwm)
            $fatal(1, "tilt output must remain centered");

        for (i = 0; i < 20; i = i + 1)
            update_angle(1'b1);
        if (dut.pan_angle !== 8'd132)
            $fatal(1, "pan angle step progression is incorrect");
        for (i = 0; i < 20; i = i + 1)
            update_angle(1'b0);
        if (dut.pan_angle !== 8'd92)
            $fatal(1, "pan angle exceeded or missed lower limit");

        @(negedge clk);
        rst_n = 1'b0;
        test_enable = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        test_enable = 1'b1;
        repeat (3) @(posedge clk);
        while (dut.period_us_count < 15'd750) begin
            @(posedge clk);
            #1;
        end
        update_angle(1'b1);
        if (dut.pan_pulse_us !== 13'd1522 || dut.active_pan_pulse_us !== 13'd1500)
            $fatal(1, "mid-frame command must wait for the next PWM frame");
        expected_remaining = 1500 - dut.period_us_count;
        high_cycles = 0;
        while (pan_pwm) begin
            high_cycles = high_cycles + 1;
            @(posedge clk);
            #1;
        end
        if (high_cycles != expected_remaining)
            $fatal(1, "mid-frame change must preserve current pulse, expected %0d remaining, got %0d",
                   expected_remaining, high_cycles);
        while (!pan_pwm) begin
            @(posedge clk);
            #1;
        end
        next_high_cycles = 0;
        while (pan_pwm) begin
            next_high_cycles = next_high_cycles + 1;
            @(posedge clk);
            #1;
        end
        if (next_high_cycles != 1522)
            $fatal(1, "next frame must apply 1522us pulse, got %0d", next_high_cycles);

        test_enable = 1'b0;
        repeat (4) @(posedge clk);
        if (dut.pan_angle !== 8'd90 || dut.pan_pulse_us !== 13'd1500)
            $fatal(1, "disabling test must return pan to center: angle=%0d pulse=%0d",
                   dut.pan_angle, dut.pan_pulse_us);

        test_enable = 1'b1;
        repeat (3) @(posedge clk);
        for (i = 0; i < 60; i = i + 1)
            update_angle(1'b1);
        if (dut.pan_angle !== 8'd180 || dut.pan_pulse_us !== 13'd2500)
            $fatal(1, "pan command must reach 180 degrees / 2500us");
        update_angle(1'b1);
        if (dut.pan_angle !== 8'd180)
            $fatal(1, "pan command exceeded 180-degree limit");
        for (i = 0; i < 90; i = i + 1)
            update_angle(1'b0);
        if (dut.pan_angle !== 8'd0 || dut.pan_pulse_us !== 13'd500)
            $fatal(1, "pan command must reach 0 degrees / 500us");
        update_angle(1'b0);
        if (dut.pan_angle !== 8'd0)
            $fatal(1, "pan command went below 0-degree limit");

        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b1;
        #1;
        high_cycles = 0;
        tilt_high_cycles = 0;
        while (pan_pwm) begin
            high_cycles = high_cycles + 1;
            if (tilt_pwm)
                tilt_high_cycles = tilt_high_cycles + 1;
            @(posedge clk);
            #1;
        end
        if (high_cycles != 1500)
            $fatal(1, "center pulse expected 1500us, got %0d", high_cycles);
        if (tilt_high_cycles != 1500)
            $fatal(1, "fixed tilt center pulse expected 1500us, got %0d", tilt_high_cycles);
        low_cycles = 0;
        while (!pan_pwm) begin
            low_cycles = low_cycles + 1;
            @(posedge clk);
            #1;
        end
        if (high_cycles + low_cycles != 20000)
            $fatal(1, "PWM period expected 20000us, got %0d", high_cycles + low_cycles);

        $display("PASS manual pan limits, center fallback, fixed tilt, and PWM pulse");
        $finish;
    end
endmodule
