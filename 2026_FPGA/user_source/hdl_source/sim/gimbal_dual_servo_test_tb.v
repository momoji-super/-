`timescale 1ns/1ps
module gimbal_dual_servo_test_tb;
    reg clk = 0;
    reg rst_n = 0;
    reg enable = 0;
    reg [3:0] commands = 0; // pan up/down, tilt up/down
    wire pan_pwm, tilt_pwm;
    integer expected_pan = 90;
    integer expected_tilt = 90;
    integer i;
    time frame_start, pan_end, tilt_end;
    always #5 clk = ~clk; // actual 100 MHz, no accelerated PWM divider

    gimbal_dual_servo_test dut (
        .I_clk(clk), .I_rst_n(rst_n), .I_test_enable(enable),
        .I_pan_up(commands[3]), .I_pan_down(commands[2]),
        .I_tilt_up(commands[1]), .I_tilt_down(commands[0]),
        .O_pan_pwm(pan_pwm), .O_tilt_pwm(tilt_pwm)
    );

    task check_commands;
        begin
            if (dut.u_pan.pan_angle !== expected_pan ||
                dut.u_tilt.pan_angle !== expected_tilt)
                $fatal(1, "independent angles: expected %0d/%0d, got %0d/%0d",
                    expected_pan, expected_tilt, dut.u_pan.pan_angle, dut.u_tilt.pan_angle);
            if (dut.u_pan.pan_pulse_us !== (500 + (100*expected_pan+4)/9) ||
                dut.u_tilt.pan_pulse_us !== (500 + (100*expected_tilt+4)/9))
                $fatal(1, "angle-to-pulse conversion incorrect");
        end
    endtask

    task press;
        input [3:0] keys;
        begin
            @(negedge clk); commands = keys;
            @(negedge clk); commands = 0;
            if (keys[3] && !keys[2] && expected_pan < 180) expected_pan = expected_pan + 2;
            if (keys[2] && !keys[3] && expected_pan > 0) expected_pan = expected_pan - 2;
            if (keys[1] && !keys[0] && expected_tilt < 180) expected_tilt = expected_tilt + 2;
            if (keys[0] && !keys[1] && expected_tilt > 0) expected_tilt = expected_tilt - 2;
            check_commands;
        end
    endtask

    task measure_frame;
        input integer pan_us;
        input integer tilt_us;
        begin
            @(posedge pan_pwm); #1;
            frame_start = $time - 1;
            if (!tilt_pwm) $fatal(1, "PWM frames must be aligned");
            fork
                begin @(negedge pan_pwm); pan_end = $time; end
                begin @(negedge tilt_pwm); tilt_end = $time; end
            join
            if (pan_end-frame_start != pan_us*1000 || tilt_end-frame_start != tilt_us*1000)
                $fatal(1, "pulse widths: expected %0d/%0d us, got %0t/%0t ns",
                    pan_us, tilt_us, pan_end-frame_start, tilt_end-frame_start);
            @(posedge pan_pwm); #1;
            if ($time-1-frame_start != 20000000 || !tilt_pwm)
                $fatal(1, "both outputs must have aligned 20ms periods");
        end
    endtask

    initial begin
        #37; rst_n = 1;
        repeat (5) @(negedge clk);
        check_commands;
        enable = 1;
        repeat (5) @(negedge clk);
        press(4'b1000); // pan only
        press(4'b0010); // tilt only
        press(4'b1001); // two axes, opposite numerical directions
        press(4'b1111); // opposing commands on each axis cancel
        press(4'b1101); // pan cancels, tilt still moves
        press(4'b0111); // tilt cancels, pan still moves
        for (i=0; i<100; i=i+1) press(4'b1010);
        for (i=0; i<100; i=i+1) press(4'b0101);
        for (i=0; i<100; i=i+1) press(4'b1000);
        // Pan=180, tilt=0. No command may shorten the initial center pulse.
        if (dut.u_pan.active_pan_pulse_us !== 1500 || dut.u_tilt.active_pan_pulse_us !== 1500)
            $fatal(1, "mid-frame changes must wait for next frame");
        #100000;
        if (!pan_pwm || !tilt_pwm) $fatal(1, "current center pulse must stay intact");
        measure_frame(2500, 500);
        @(negedge clk); enable = 0;
        repeat (5) @(negedge clk);
        expected_pan = 90; expected_tilt = 90;
        check_commands;
        // Inputs are ignored in disabled mode, including simultaneous presses.
        @(negedge clk); commands = 4'b1010;
        repeat (5) @(negedge clk);
        check_commands;
        commands = 0;
        measure_frame(1500, 1500);
        @(negedge clk); rst_n = 0;
        #1; check_commands;
        $display("PASS: dual-axis isolation, concurrent commands, cancellation, full ranges, frame updates, actual 100MHz 20ms PWM, center and reset");
        $finish;
    end

    initial begin
        #250000000;
        $fatal(1, "simulation timeout");
    end
endmodule
