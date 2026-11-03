`timescale 1ns/1ps

module red_laser_peak_tb;
    reg clk = 0, rst_n = 0;
    reg [95:0] data = 0;
    reg valid = 0, user = 0, last = 0;
    wire frame_toggle, target_valid;
    wire [10:0] x_min, y_min, x_max, y_max, center_x, center_y;
    wire [11:0] motion_count;
    wire motion_valid;
    wire [10:0] motion_x_min, motion_y_min, motion_x_max, motion_y_max;
    integer x, y;
    reg [23:0] p0, p1, p2, p3;

    always #5 clk = ~clk;

    target_detect_track #(.IMG_WIDTH(8), .IMG_HEIGHT(4)) dut (
        .I_clk(clk), .I_rst_n(rst_n), .I_tdata(data), .I_red_tdata(data),
        .I_tvalid(valid), .I_tuser(user), .I_tlast(last),
        .O_frame_toggle(frame_toggle), .O_target_valid(target_valid),
        .O_x_min(x_min), .O_y_min(y_min), .O_x_max(x_max), .O_y_max(y_max),
        .O_center_x(center_x), .O_center_y(center_y),
        .O_motion_count(motion_count), .O_motion_valid(motion_valid),
        .O_motion_x_min(motion_x_min), .O_motion_y_min(motion_y_min),
        .O_motion_x_max(motion_x_max), .O_motion_y_max(motion_y_max)
    );

    task send_beat;
        input [23:0] a, b, c, d;
        input fs, le;
        begin
            @(negedge clk);
            data = {d, c, b, a}; valid = 1; user = fs; last = le;
            @(posedge clk); #1;
        end
    endtask

    task send_frame;
        input integer pattern;
        begin
            for (y = 0; y < 4; y = y + 1) begin
                for (x = 0; x < 8; x = x + 4) begin
                    p0 = 24'h000000; p1 = 24'h000000;
                    p2 = 24'h000000; p3 = 24'h000000;
                    case(pattern)
                    0: begin
                        if (y == 0 && x == 0) p0 = 24'hff0000; // isolated hot pixel
                        if (y == 0 && x == 4) p0 = 24'hffffff;
                        if (y == 1 && x == 4) begin p2 = 24'hdc0808; p3 = 24'hf00000; end
                        if (y == 2 && x == 4) begin p2 = 24'hb40000; p3 = 24'hb40000; end
                        if (y == 3 && x == 0) begin p0 = 24'hc80000; p1 = 24'hc80000; end
                        if (y == 3 && x == 4) p0 = 24'hff8000;
                    end
                    1: if(y==0 && x==0) begin
                        p0=24'hc80000; p1=24'hfa0000; p2=24'he00000; p3=24'hc80000;
                    end
                    2: if(y==3 && x==4) begin
                        p0=24'hc80000; p1=24'hc80000; p2=24'hc80000; p3=24'hfe0000;
                    end
                    3: begin p0=24'hffffff; p1=24'hfff0e0; p2=24'hff8000; p3=24'hff00ff; end
                    4: begin
                        if(y==0 && x==0) begin
                            p0=24'hf01414; p1=24'hf00000; p2=24'hf00000; p3=24'hb40000;
                        end
                        if(y==3 && x==4) begin p0=24'hf00000; p1=24'hf00000; end
                    end
                    endcase
                    send_beat(p0, p1, p2, p3, (y == 0) && (x == 0), x == 4);
                end
            end
            @(negedge clk); valid=0; user=0; last=0;
            repeat(4) @(posedge clk); #1;
        end
    endtask

    initial begin
        if (dut.is_red_pixel(24'hffffff) || dut.is_red_pixel(24'hfff0e0) ||
            dut.is_red_pixel(24'hff8000) || dut.is_red_pixel(24'hff00ff) ||
            !dut.is_red_pixel(24'hf00000) || !dut.is_red_pixel(24'hb40000))
            $fatal(1, "RGB rejection/acceptance boundary failed");
        repeat (3) @(posedge clk); rst_n = 1;
        send_frame(0);
        send_frame(1);
        if (!target_valid || center_x !== 11'd7 || center_y !== 11'd1 ||
            x_min !== 11'd0 || x_max !== 11'd7 || y_min !== 11'd0 || y_max !== 11'd3)
            $fatal(1, "brightest-point selection or clipped box failed: valid=%b center=%0d,%0d box=%0d..%0d,%0d..%0d",
                   target_valid, center_x, center_y, x_min, x_max, y_min, y_max);
        send_frame(2);
        if(!target_valid || center_x!==1 || center_y!==0) $fatal(1,"first-beat peak lost");
        send_frame(3);
        if(!target_valid || center_x!==7 || center_y!==3) $fatal(1,"last-beat peak lost");
        send_frame(4);
        if(target_valid) $fatal(1,"white/orange/magenta frame detected red");
        send_frame(3);
        if(!target_valid || center_x!==1 || center_y!==0) $fatal(1,"margin/earliest tie selection");
        $display("PASS red laser: brightest point, white/orange rejection, isolated noise, clipped marker, frame boundaries and tie order");
        $finish;
    end
endmodule
