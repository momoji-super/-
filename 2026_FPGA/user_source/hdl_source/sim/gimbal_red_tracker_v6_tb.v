`timescale 1ns/1ps
module gimbal_red_tracker_v6_tb;
    reg clk=0, rst_n=0, enable=1, toggle=0, valid=0;
    reg [10:0] x=640,y=360;
    wire pan_pwm,tilt_pwm;
    integer high_cycles;
    time first_rise;
    always #5 clk=~clk;
    gimbal_red_tracker dut (.I_clk(clk),.I_rst_n(rst_n),.I_enable(enable),
        .I_target_frame_toggle(toggle),.I_target_valid(valid),
        .I_target_center_x(x),.I_target_center_y(y),
        .O_pan_pwm(pan_pwm),.O_tilt_pwm(tilt_pwm));
    task frame;
        input v; input [10:0] px,py;
        begin
            @(negedge clk); valid=v; x=px; y=py; toggle=~toggle;
            repeat(6) @(posedge clk); #1;
        end
    endtask
    initial begin
        #300000000; $fatal(1,"tracker production timing watchdog");
    end
    initial begin
        repeat(3) @(negedge clk); rst_n=1; #1;
        fork
            begin
                high_cycles=0;
                while(pan_pwm) begin
                    high_cycles=high_cycles+1; @(posedge clk); #1;
                end
                if(high_cycles!=150000) $fatal(1,"first pulse changed mid-period: %0d",high_cycles);
            end
            begin
                frame(1,700,420); frame(1,700,420); frame(1,700,420);
                if(dut.pan_angle!==88 || dut.tilt_angle!==88) $fatal(1,"initial confirmed step");
                if(dut.pan_pulse_active!==1500 || dut.tilt_pulse_active!==1500)
                    $fatal(1,"active PWM width updated before boundary");
            end
        join
        @(posedge pan_pwm); first_rise=$time; #1;
        if(dut.pan_pulse_active!==1478 || dut.tilt_pulse_active!==1478)
            $fatal(1,"new widths did not latch at 20ms boundary");
        @(negedge pan_pwm);
        if($time-first_rise!=1478000) $fatal(1,"pan high width");
        @(posedge pan_pwm);
        if($time-first_rise!=20000000) $fatal(1,"PWM period");
        // Repeated frames within 100 ms must not accelerate the controller.
        frame(1,700,420);
        if(dut.pan_angle!==88 || dut.tilt_angle!==88) $fatal(1,"100ms rate limit");
        #61000000;
        frame(1,700,420);
        if(dut.pan_angle!==86 || dut.tilt_angle!==86) $fatal(1,"relative second step after 100ms");
        frame(0,0,0); #101000000;
        frame(1,590,310); frame(1,689,409); frame(1,640,360);
        if(dut.pan_angle!==86 || dut.tilt_angle!==86) $fatal(1,"center/lost-target hold");
        $display("PASS production 100MHz divider, 20ms frame-latched PWM, 1500us reset, 100ms correction interval and center hold");
        $finish;
    end
endmodule
