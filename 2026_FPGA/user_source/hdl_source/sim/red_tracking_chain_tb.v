`timescale 1ns/1ps
module red_tracking_chain_tb;
    reg video_clk=0, servo_clk=0, rst_n=0;
    reg [95:0] rgb=0;
    reg valid=0,user=0,last=0;
    wire toggle,red_valid,motion_valid;
    wire [10:0] cx,cy;
    wire pan_pwm,tilt_pwm;
    integer x,y,k;
    always #7 video_clk=~video_clk;
    always #5 servo_clk=~servo_clk;
    target_detect_track detector (.I_clk(video_clk),.I_rst_n(rst_n),
        .I_tdata(rgb),.I_red_tdata(rgb),.I_tvalid(valid),.I_tuser(user),.I_tlast(last),
        .O_frame_toggle(toggle),.O_target_valid(red_valid),.O_center_x(cx),.O_center_y(cy),
        .O_motion_valid(motion_valid),.O_motion_count(),
        .O_x_min(),.O_y_min(),.O_x_max(),.O_y_max(),
        .O_motion_x_min(),.O_motion_y_min(),.O_motion_x_max(),.O_motion_y_max());
    gimbal_red_tracker tracker (.I_clk(servo_clk),.I_rst_n(rst_n),.I_enable(1'b1),
        .I_target_frame_toggle(toggle),.I_target_valid(red_valid),
        .I_target_center_x(cx),.I_target_center_y(cy),
        .O_pan_pwm(pan_pwm),.O_tilt_pwm(tilt_pwm));
    task frame;
        input white;
        begin
            for(y=0;y<720;y=y+1) begin
                for(x=0;x<1280;x=x+4) begin
                    @(negedge video_clk);
                    valid=1; user=(x==0 && y==0); last=(x==1276);
                    rgb=white ? {4{24'hffffff}} : 96'd0;
                    if(!white && y==0 && x==0) rgb[23:0]=24'hff0000;
                    if(!white && y==300 && x==700) rgb={4{24'hffffff}};
                    if(!white && y==600 && x==1000)
                        rgb={24'hfa0000,24'he00000,24'hc80000,24'hc80000};
                end
            end
            @(negedge video_clk); valid=0; user=0; last=0;
            repeat(12) @(posedge servo_clk); #1;
        end
    endtask
    initial begin
        #50000000; $fatal(1,"red tracking integration watchdog");
    end
    initial begin
        repeat(5) @(negedge servo_clk); rst_n=1;
        for(k=0;k<4;k=k+1) frame(0);
        if(!red_valid || cx!==1003 || cy!==600)
            $fatal(1,"1280x720 peak coordinate/CDC: %b %0d,%0d",red_valid,cx,cy);
        if(tracker.pan_angle!==88 || tracker.tilt_angle!==88)
            $fatal(1,"detector->servo tracking failed: %0d,%0d",tracker.pan_angle,tracker.tilt_angle);
        frame(1); frame(1);
        if(red_valid || motion_valid) $fatal(1,"full white flash must not create a target");
        if(tracker.pan_angle!==88 || tracker.tilt_angle!==88)
            $fatal(1,"motion/white interference changed servo command");
        $display("PASS full 1280x720 detector -> asynchronous CDC -> dual-axis commands; white/motion cannot drive servos");
        $finish;
    end
endmodule
