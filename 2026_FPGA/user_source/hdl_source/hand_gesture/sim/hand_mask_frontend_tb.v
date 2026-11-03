`timescale 1ns/1ps

module hand_mask_frontend_tb;
    reg clk=0, rst_n=0, enable=0, valid=0, user=0, last=0;
    reg [95:0] data=0;
    wire frame_start, sample_valid, sample_skin;
    wire [7:0] sample_x, sample_y;
    integer row,beat,samples;
    reg first_tile_seen, first_tile_value, roi_tile_seen, roi_tile_value;

    always #5 clk=~clk;

    hand_mask_frontend #(.IMG_WIDTH(32),.IMG_HEIGHT(16),.MIN_SKIN_PIXELS(2),
        .ROI_X_MIN(8),.ROI_X_MAX(23),.ROI_Y_MIN(0)) dut(
        .clk(clk),.rst_n(rst_n),.enable(enable),.rgb_data(data),.valid(valid),
        .user(user),.last(last),.frame_start(frame_start),.sample_valid(sample_valid),
        .sample_skin(sample_skin),.sample_x(sample_x),.sample_y(sample_y));

    function [23:0] pixel;
        input integer x;
        input integer y;
        begin
            // Skin inside and outside the configured ROI.
            if ((x<16)&&(y<8)) pixel=24'hdc9678;
            else pixel=24'h000000;
        end
    endfunction

    task send_beat;
        input integer x;
        input integer y;
        input integer first;
        input integer end_of_line;
        begin
            @(negedge clk);
            data={pixel(x+3,y),pixel(x+2,y),pixel(x+1,y),pixel(x,y)};
            valid=1; user=first; last=end_of_line;
        end
    endtask

    always @(posedge clk) begin
        if(sample_valid) begin
            samples=samples+1;
            if(sample_x==0 && sample_y==0) begin
                first_tile_seen=1;
                first_tile_value=sample_skin;
            end
            if(sample_x==1 && sample_y==0) begin
                roi_tile_seen=1;
                roi_tile_value=sample_skin;
            end
            if(sample_x>3 || sample_y>1)
                $fatal(1,"sample coordinate out of range x=%0d y=%0d",sample_x,sample_y);
        end
    end

    initial begin
        samples=0; first_tile_seen=0; first_tile_value=0;
        roi_tile_seen=0; roi_tile_value=0;
        repeat(3) @(posedge clk);
        rst_n=1; enable=1;
        for(row=0;row<16;row=row+1) begin
            for(beat=0;beat<8;beat=beat+1)
                send_beat(beat*4,row,(row==0 && beat==0),(beat==7));
        end
        @(negedge clk); valid=0; user=0; last=0; data=0;
        repeat(3) @(posedge clk);
        if(samples!=8) $fatal(1,"expected 8 mask samples, got %0d",samples);
        if(!first_tile_seen || first_tile_value)
            $fatal(1,"skin outside ROI was not rejected");
        if(!roi_tile_seen || !roi_tile_value)
            $fatal(1,"skin inside ROI was not classified as foreground");
        $display("PASS hand_mask_frontend_tb samples=%0d",samples);
        $finish;
    end
endmodule
