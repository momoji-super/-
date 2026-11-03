`timescale 1ns/1ps
// Full-size raster, asynchronous clocks, frame ownership and temporal vote.
// Shapes are synthetic algorithm checks, not a camera-accuracy benchmark.
module hand_pipeline_tb;
    reg cam_clk=0,analysis_clk=0,rst_n=0;
    reg frame_start=0,sample_valid=0,sample_skin=0;
    reg [7:0] x=0,y=0;
    wire [3:0] stable_count,raw_count,error,support;
    wire valid,raw_valid,present,done,busy,waiting;
    integer n,xx,yy,k,case_count=0;
    reg last_toggle;
    always #5 cam_clk=~cam_clk;
    always #9 analysis_clk=~analysis_clk;
    hand_pipeline #(.WIDTH(160),.HEIGHT(90),.REQUIRE_WRIST(0)) dut(
        .cam_clk(cam_clk),.analysis_clk(analysis_clk),.arst_n(rst_n),
        .frame_start(frame_start),.sample_valid(sample_valid),.sample_skin(sample_skin),
        .sample_x(x),.sample_y(y),.stable_count(stable_count),.raw_count(raw_count),
        .error(error),.support(support),.display_valid(valid),.raw_valid(raw_valid),
        .present(present),.result_done(done),.busy(busy),.camera_waiting(waiting),
        .palm_x(),.palm_y(),.palm_radius(),.wrist_x(),.wrist_y(),
        .tip0(),.tip1(),.tip2(),.tip3(),.tip4(),.analysis_rst_n(),.cam_rst_n());
    function shape;
        input integer px,py,fingers;
        integer dx,dy,j,nf;
        real angle,along,across;
        begin
            dx=px-80;dy=py-48;nf=fingers%10;
            shape=0;
            if(fingers>=0) begin
                shape=(dx*dx+dy*dy<=144)||((px>=76)&&(px<=84)&&(py>=48));
                for(j=0;j<nf;j=j+1) begin
                    angle=(nf==1)?-1.57079632679:(-2.55+j*1.96/(nf-1));
                    along=dx*$cos(angle)+dy*$sin(angle);
                    across=-dx*$sin(angle)+dy*$cos(angle);
                    if(along>=8.0&&along<=32.0&&across>=-2.5&&across<=2.5) shape=1;
                    // A narrow segmentation gap through each extended finger.
                    if(fingers>=20 && along>=19.0&&along<=27.0&&
                       across>=-0.45&&across<=0.45) shape=0;
                end
                // A detached patch intersects the outer counting rings, but
                // has no radial support at the inner ring (false finger).
                if(fingers>=10&&fingers<20&&px>=101&&px<=105&&py>=46&&py<=50) shape=1;
            end
        end
    endfunction
    task frame;
        input integer fingers;
        begin
            wait(!waiting && !busy);
            repeat(8) @(negedge cam_clk);
            frame_start=1;
            @(negedge cam_clk);frame_start=0;
            for(yy=0;yy<90;yy=yy+1) for(xx=0;xx<160;xx=xx+1) begin
                sample_valid=1;x=xx;y=yy;sample_skin=shape(xx,yy,fingers);
                @(negedge cam_clk);
            end
            sample_valid=0;
            @(posedge done);#1;
            $display("RESULT shape=%0d count=%0d valid=%b present=%b error=%0d",fingers,raw_count,raw_valid,present,error);
            if(!raw_valid||error!=0||present!=(fingers>=0)||raw_count!=((fingers<0)?0:(fingers%10)))
                $fatal(1,"synthetic hand mismatch");
            repeat(16) @(negedge analysis_clk);
        end
    endtask
    initial begin
        repeat(5) @(negedge cam_clk);rst_n=1;
        frame(-1);
        for(n=0;n<=5;n=n+1) frame(n);
        frame(14);frame(24);
        // Clear history, then require five matching votes before display.
        rst_n=0;repeat(5) @(negedge cam_clk);rst_n=1;
        for(k=0;k<5;k=k+1) begin
            frame(2);
            if(k<4&&valid) $fatal(1,"vote published too early");
        end
        if(!valid||stable_count!=2||support<5) $fatal(1,"stable vote mismatch");
        frame(-1);
        if(!valid||stable_count!=2) $fatal(1,"brief no-hand must retain count");
        frame(-1);frame(-1);
        if(!valid||stable_count!=0) $fatal(1,"sustained no-hand must clear count");
        $display("PASS hand_pipeline_tb: full masks, 0..5 fingers, detached noise, finger gaps, async RAM, voting/reset/no-hand");
        $finish;
    end
    initial begin #250000000;$fatal(1,"hand pipeline watchdog");end
endmodule
