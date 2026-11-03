`timescale 1ns/1ps
module gimbal_red_tracker_tb;
    reg clk=0, rst_n=0, enable=1, toggle=0, valid=0;
    reg [10:0] x=640, y=360;
    wire pan_pwm, tilt_pwm;
    integer i, angle_i, expected_pulse;
    always #500 clk=~clk;
    // Short update interval accelerates command-range and direction coverage.
    gimbal_red_tracker #(.CLK_FREQ_HZ(1000000), .UPDATE_INTERVAL_MS(1)) dut (
        .I_clk(clk), .I_rst_n(rst_n), .I_enable(enable),
        .I_target_frame_toggle(toggle), .I_target_valid(valid),
        .I_target_center_x(x), .I_target_center_y(y),
        .O_pan_pwm(pan_pwm), .O_tilt_pwm(tilt_pwm));
    task frame;
        input v; input [10:0] px,py;
        begin
            @(negedge clk); valid=v; x=px; y=py; toggle=~toggle;
            repeat(6) @(posedge clk); #1;
        end
    endtask
    task expect_angles;
        input [7:0] pan,tilt;
        begin
            if (dut.pan_angle !== pan || dut.tilt_angle !== tilt)
                $fatal(1,"angles %0d,%0d expected %0d,%0d",dut.pan_angle,dut.tilt_angle,pan,tilt);
        end
    endtask
    initial begin
        #1000000000; $fatal(1,"tracker command watchdog");
    end
    initial begin
        repeat(3) @(negedge clk); rst_n=1;
        frame(1,700,420); frame(1,700,420); expect_angles(90,90);
        frame(1,700,420); expect_angles(88,88);
        // A fixed image error must accumulate relative corrections beyond
        // the previous absolute-angle limit (83/97 degrees for this target).
        for(i=0;i<50;i=i+1) begin
            #1100000; frame(1,700,420);
        end
        expect_angles(0,0);
        #1100000; frame(1,700,420); expect_angles(0,0);
        // Inclusive lower and exclusive upper bounds of the 100x100 window.
        #1100000; frame(1,590,310); expect_angles(0,0);
        #1100000; frame(1,689,409); expect_angles(0,0);
        frame(0,0,0); expect_angles(0,0); #1100000;
        frame(1,0,0); frame(1,0,0); expect_angles(0,0);
        frame(1,0,0); expect_angles(2,2);
        enable=0; repeat(6) @(posedge clk);
        #1100000; frame(1,0,0); expect_angles(2,2);
        enable=1; repeat(6) @(posedge clk);
        frame(1,0,0); frame(1,0,0); expect_angles(2,2);
        frame(1,0,0); expect_angles(4,4);
        // Out-of-image snapshots are ignored and break confirmation.
        #1100000; frame(1,1280,720); expect_angles(4,4);
        frame(1,0,0); frame(1,0,0); expect_angles(4,4);
        frame(1,0,0); expect_angles(6,6);
        for(i=0;i<100;i=i+1) begin
            #1100000; frame(1,0,0);
        end
        expect_angles(180,180);
        for (angle_i = 0; angle_i <= 180; angle_i = angle_i + 1) begin
            expected_pulse = 500 + ((angle_i * 1000 + 45) / 90);
            if (dut.scaled_numerator_to_pulse_us(
                    dut.angle_to_scaled_numerator(angle_i[7:0])) !== expected_pulse)
                $fatal(1,"pulse mapping angle=%0d got=%0d expected=%0d", angle_i,
                       dut.scaled_numerator_to_pulse_us(
                           dut.angle_to_scaled_numerator(angle_i[7:0])), expected_pulse);
        end
        if (dut.scaled_numerator_to_pulse_us(18'd18004) !== 13'd2500)
            $fatal(1,"out-of-range pulse clamp");
        $display("PASS relative tracking, directions, full 0..180 clamps, confirmation, enable, loss and exact 100x100 bounds");
        $finish;
    end
endmodule
