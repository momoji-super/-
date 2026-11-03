`timescale 1ns/1ps
module motion_stability_tb;
    reg clk=0,rst_n=0,valid=0,sof=0,last=0;
    reg [95:0] rgb=0;
    wire mv;
    wire [11:0] mc;
    wire [10:0] x0,y0,x1,y1;
    reg snap_valid=0;
    reg [11:0] snap_count=0;
    reg [10:0] snap_x0=0,snap_y0=0,snap_x1=0,snap_y1=0;
    integer xx,yy,lane,v,f;
    always #5 clk=~clk;
    target_detect_track #(.IMG_WIDTH(320),.IMG_HEIGHT(192)) dut(
        .I_clk(clk),.I_rst_n(rst_n),.I_tdata(rgb),.I_red_tdata(96'd0),
        .I_tvalid(valid),.I_tuser(sof),.I_tlast(last),
        .O_frame_toggle(),.O_target_valid(),.O_x_min(),.O_y_min(),.O_x_max(),.O_y_max(),
        .O_center_x(),.O_center_y(),.O_motion_count(mc),.O_motion_valid(mv),
        .O_motion_x_min(x0),.O_motion_y_min(y0),.O_motion_x_max(x1),.O_motion_y_max(y1));
    always @(posedge clk) if(dut.pipe_user) begin
        #1;snap_valid=mv;snap_count=mc;snap_x0=x0;snap_y0=y0;snap_x1=x1;snap_y1=y1;
    end
    task frame;
        input integer mode,left,level;
        begin
            for(yy=0;yy<192;yy=yy+1) for(xx=0;xx<320;xx=xx+4) begin
                @(negedge clk);valid=1;sof=(xx==0&&yy==0);last=(xx==316);
                for(lane=0;lane<4;lane=lane+1) begin
                    v=40;
                    if(mode==1 && (xx%64==0)&&(yy%64==0)) v=level;
                    if(mode==2) v=level;
                    if(mode==3 && xx>=left&&xx<left+64&&yy>=32&&yy<96) v=level;
                    // One noisy pixel per beat must be averaged below threshold.
                    if(mode==4 && lane==0) v=100;
                    rgb[lane*24+:24]={v[7:0],v[7:0],v[7:0]};
                end
                if(xx%28==0 && !last) begin
                    @(negedge clk);valid=0;sof=0;last=0;
                end
            end
            @(negedge clk);valid=0;sof=0;last=0;
            repeat(20) @(negedge clk);
            $display("motion mode=%0d left=%0d level=%0d published=%b count=%0d box=%0d,%0d..%0d,%0d",mode,left,level,snap_valid,snap_count,snap_x0,snap_y0,snap_x1,snap_y1);
        end
    endtask
    initial begin
        repeat(5) @(negedge clk);rst_n=1;
        frame(0,0,0);if(snap_valid) $fatal(1,"first-frame false detection");
        frame(0,0,0);if(snap_valid) $fatal(1,"static scene false detection");
        frame(4,0,0);if(snap_valid) $fatal(1,"single pixel noise");
        frame(0,0,0);if(snap_valid) $fatal(1,"single pixel noise recovery");
        for(f=0;f<4;f=f+1) begin
            frame(1,0,(f%2)?40:200);if(snap_valid) $fatal(1,"isolated grid noise");
        end
        frame(2,0,200);if(snap_valid) $fatal(1,"global brightness jump");
        frame(0,0,0);if(snap_valid) $fatal(1,"global brightness recovery");
        frame(3,32,200);
        frame(3,32,200);
        if(!snap_valid||snap_x0!=32||snap_y0!=32||snap_x1!=95||snap_y1!=95) $fatal(1,"local motion acquisition");
        frame(3,32,120);
        frame(3,32,120);
        if(!snap_valid||snap_x0!=32||snap_x1!=95) $fatal(1,"stable region jitter");
        frame(3,48,200);
        frame(3,48,200);
        if(!snap_valid||snap_x1<=95||snap_x1>=111) $fatal(1,"small edge change must be smoothed");
        frame(3,176,120); // Difference includes old and new positions.
        frame(3,176,200);
        if(!snap_valid||snap_x0>48||snap_x1<239) $fatal(1,"large move must follow promptly");
        frame(3,176,200);if(!snap_valid) $fatal(1,"last moving frame should publish");
        frame(3,176,200);if(!snap_valid) $fatal(1,"first missed frame should hold");
        frame(3,176,200);if(!snap_valid) $fatal(1,"second missed frame should hold");
        frame(3,176,200);
        if(snap_valid) $fatal(1,"stopped motion must expire");
        // Constant-brightness object translates just one grid per frame.
        // Both vacated and newly covered thin edges must remain detectable.
        frame(0,0,0);frame(0,0,0);frame(0,0,0);frame(0,0,0);
        frame(3,32,200);frame(3,48,200);frame(3,64,200);
        frame(3,80,200);frame(3,96,200);frame(3,112,200);
        if(!snap_valid || snap_count<6 || snap_x1<143)
            $fatal(1,"slow constant-brightness movement must survive edge filtering");
        $display("PASS motion_stability_tb: startup, noise, flash, acquisition, smoothing, fast movement, hold and expiry");
        $finish;
    end
    initial begin #20000000;$fatal(1,"watchdog");end
endmodule
