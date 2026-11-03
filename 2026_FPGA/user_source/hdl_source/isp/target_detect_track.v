module target_detect_track #(
    parameter IMG_WIDTH = 1280,
    parameter IMG_HEIGHT = 720,
    parameter MOTION_THRESHOLD = 8'd20
) (
    input wire I_clk,
    input wire I_rst_n,
    input wire [95:0] I_tdata,
    input wire [95:0] I_red_tdata,
    input wire I_tvalid,
    input wire I_tuser,
    input wire I_tlast,
    output reg O_frame_toggle,
    output reg O_target_valid,
    output reg [10:0] O_x_min,
    output reg [10:0] O_y_min,
    output reg [10:0] O_x_max,
    output reg [10:0] O_y_max,
    output reg [10:0] O_center_x,
    output reg [10:0] O_center_y,
    output wire [11:0] O_motion_count,
    output wire O_motion_valid,
    output wire [10:0] O_motion_x_min,
    output wire [10:0] O_motion_y_min,
    output wire [10:0] O_motion_x_max,
    output wire [10:0] O_motion_y_max
);


    reg [10:0] x_count;
    reg [10:0] y_count;
    reg [10:0] frame_x_min;
    reg [10:0] frame_y_min;
    reg [10:0] frame_x_max;
    reg [10:0] frame_y_max;
    reg [15:0] target_pixels;
    reg previous_frame_valid;
    reg [2:0] red_lane_count;
    reg [1:0] red_min_lane;
    reg [1:0] red_max_lane;
    reg [10:0] beat_x_min;
    reg [10:0] beat_x_max;
    reg [10:0] next_x_min;
    reg [10:0] next_y_min;
    reg [10:0] next_x_max;
    reg [10:0] next_y_max;
    reg [10:0] pixel_x_base;
    reg [10:0] pixel_y_base;
    reg [15:0] target_count_base;
    // Three-stage candidate pipeline: color/margin, pair winners, beat winner.
    // Luma, red flags and AXI sidebands have exactly the same latency.
    reg [95:0] pipe_tdata, luma_s0, luma_s1, red_rgb_s0;
    reg pipe_valid, pipe_user, pipe_last;
    reg valid_s0,user_s0,last_s0,valid_s1,user_s1,last_s1;
    reg [3:0] red_pixel,red_s0,red_s1;
    reg [7:0] margin0_s0,margin1_s0,margin2_s0,margin3_s0;
    reg pair01_valid,pair23_valid;
    reg [7:0] pair01_r,pair23_r,pair01_margin,pair23_margin;
    reg [1:0] pair01_index,pair23_index;
    reg red_best_valid;
    reg [7:0] red_best_r,red_best_margin;
    reg [1:0] red_best_lane;
    reg [16:0] target_sum;
    reg [15:0] frame_red_count;
    reg [7:0] frame_peak_r, frame_peak_margin;
    reg [10:0] frame_peak_x, frame_peak_y;
    reg [10:0] beat_peak_y;
    reg [7:0] beat_peak_r, beat_peak_margin;
    reg [10:0] beat_peak_x;


    motion_grid_stable #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT),
        .THRESHOLD(MOTION_THRESHOLD)) u_motion_stable(
        .clk(I_clk),.rst_n(I_rst_n),.rgb(pipe_tdata),
        .valid(pipe_valid),.sof(pipe_user),.last(pipe_last),
        .frame_ready(previous_frame_valid),
        .motion_count(O_motion_count),.motion_valid(O_motion_valid),
        .x_min(O_motion_x_min),.y_min(O_motion_y_min),
        .x_max(O_motion_x_max),.y_max(O_motion_y_max));

    wire pick1=red_s0[1]&&(!red_s0[0]||
        (red_rgb_s0[47:40]>red_rgb_s0[23:16])||
        ((red_rgb_s0[47:40]==red_rgb_s0[23:16])&&(margin1_s0>margin0_s0)));
    wire pick3=red_s0[3]&&(!red_s0[2]||
        (red_rgb_s0[95:88]>red_rgb_s0[71:64])||
        ((red_rgb_s0[95:88]==red_rgb_s0[71:64])&&(margin3_s0>margin2_s0)));
    wire pick23=pair23_valid&&(!pair01_valid||(pair23_r>pair01_r)||
        ((pair23_r==pair01_r)&&(pair23_margin>pair01_margin)));
    function [7:0] red_margin;
        input [23:0] p;
        begin red_margin=p[23:16]-((p[15:8]>p[7:0])?p[15:8]:p[7:0]);end
    endfunction
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            luma_s0<=0;luma_s1<=0;pipe_tdata<=0;red_rgb_s0<=0;
            valid_s0<=0;user_s0<=0;last_s0<=0;
            valid_s1<=0;user_s1<=0;last_s1<=0;
            pipe_valid<=0;pipe_user<=0;pipe_last<=0;
            red_s0<=0;red_s1<=0;red_pixel<=0;
            margin0_s0<=0;margin1_s0<=0;margin2_s0<=0;margin3_s0<=0;
            pair01_valid<=0;pair23_valid<=0;pair01_r<=0;pair23_r<=0;
            pair01_margin<=0;pair23_margin<=0;pair01_index<=0;pair23_index<=0;
            red_best_valid<=0;red_best_r<=0;red_best_margin<=0;red_best_lane<=0;
        end else begin
            luma_s0<=I_tdata;luma_s1<=luma_s0;pipe_tdata<=luma_s1;
            valid_s0<=I_tvalid;valid_s1<=valid_s0;pipe_valid<=valid_s1;
            user_s0<=I_tuser;user_s1<=user_s0;pipe_user<=user_s1;
            last_s0<=I_tlast;last_s1<=last_s0;pipe_last<=last_s1;
            red_rgb_s0<=I_red_tdata;
            red_s0<={is_red_pixel(I_red_tdata[95:72]),is_red_pixel(I_red_tdata[71:48]),
                     is_red_pixel(I_red_tdata[47:24]),is_red_pixel(I_red_tdata[23:0])};
            red_s1<=red_s0;red_pixel<=red_s1;
            margin0_s0<=red_margin(I_red_tdata[23:0]);
            margin1_s0<=red_margin(I_red_tdata[47:24]);
            margin2_s0<=red_margin(I_red_tdata[71:48]);
            margin3_s0<=red_margin(I_red_tdata[95:72]);
            pair01_valid<=red_s0[0]||red_s0[1];pair23_valid<=red_s0[2]||red_s0[3];
            pair01_r<=pick1?red_rgb_s0[47:40]:red_rgb_s0[23:16];
            pair23_r<=pick3?red_rgb_s0[95:88]:red_rgb_s0[71:64];
            pair01_margin<=pick1?margin1_s0:margin0_s0;
            pair23_margin<=pick3?margin3_s0:margin2_s0;
            pair01_index<=pick1?2'd1:2'd0;pair23_index<=pick3?2'd3:2'd2;
            red_best_valid<=pair01_valid||pair23_valid;
            red_best_r<=pick23?pair23_r:pair01_r;
            red_best_margin<=pick23?pair23_margin:pair01_margin;
            red_best_lane<=pick23?pair23_index:pair01_index;
        end
    end

    function is_red_pixel;
        input [23:0] pixel;
        reg [8:0] red_ext;
        reg [8:0] green_ext;
        reg [8:0] blue_ext;
        reg [8:0] max_gb;
        reg [7:0] gb_delta;
        begin
            red_ext = {1'b0, pixel[23:16]};
            green_ext = {1'b0, pixel[15:8]};
            blue_ext = {1'b0, pixel[7:0]};
            max_gb = (green_ext > blue_ext) ? green_ext : blue_ext;
            gb_delta = (pixel[15:8] > pixel[7:0]) ?
                       pixel[15:8] - pixel[7:0] :
                       pixel[7:0] - pixel[15:8];
            // Saturated/bright neutral light and orange/magenta are rejected.
            is_red_pixel = (red_ext >= 9'd96) &&
                           (red_ext >= max_gb + 9'd48) &&
                           (({2'b0, red_ext} << 1) >= ({2'b0, max_gb} * 11'd3)) &&
                           ({2'b0, gb_delta, 2'b00} <= red_ext);
        end
    endfunction


    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            x_count <= 10'd0;
            y_count <= 10'd0;
            frame_x_min <= IMG_WIDTH - 1;
            frame_y_min <= IMG_HEIGHT - 1;
            frame_x_max <= 10'd0;
            frame_y_max <= 10'd0;
            target_pixels <= 16'd0;
            previous_frame_valid <= 1'b0;
            O_frame_toggle <= 1'b0;
            O_target_valid <= 1'b0;
            O_x_min <= 10'd0;
            O_y_min <= 10'd0;
            O_x_max <= 10'd0;
            O_y_max <= 10'd0;
            O_center_x <= 10'd0;
            O_center_y <= 10'd0;
            red_lane_count <= 3'd0;
            red_min_lane <= 2'd0;
            red_max_lane <= 2'd0;
            beat_x_min <= 10'd0;
            beat_x_max <= 10'd0;
            next_x_min = IMG_WIDTH - 1;
            next_y_min = IMG_HEIGHT - 1;
            next_x_max = 10'd0;
            next_y_max = 10'd0;
            pixel_x_base = 10'd0;
            pixel_y_base = 10'd0;
            target_count_base = 16'd0;
            target_sum = 17'd0;
            frame_red_count <= 16'd0;
            frame_peak_r <= 8'd0;
            frame_peak_margin <= 8'd0;
            frame_peak_x <= 11'd0;
            frame_peak_y <= 11'd0;
            beat_peak_r = 8'd0;
            beat_peak_margin = 8'd0;
            beat_peak_x = 11'd0;
            beat_peak_y = 11'd0;
        end else begin
            if (pipe_user) begin
                O_frame_toggle <= ~O_frame_toggle;
                O_target_valid <= (frame_red_count >= 16'd3);
                if (frame_red_count >= 16'd3) begin
                    O_center_x <= frame_peak_x;
                    O_center_y <= frame_peak_y;
                    O_x_min <= (frame_peak_x < 11'd8) ? 11'd0 : frame_peak_x - 11'd8;
                    O_y_min <= (frame_peak_y < 11'd8) ? 11'd0 : frame_peak_y - 11'd8;
                    O_x_max <= (frame_peak_x + 11'd8 >= IMG_WIDTH) ? IMG_WIDTH - 1 : frame_peak_x + 11'd8;
                    O_y_max <= (frame_peak_y + 11'd8 >= IMG_HEIGHT) ? IMG_HEIGHT - 1 : frame_peak_y + 11'd8;
                end
                frame_red_count <= 16'd0;
                frame_peak_r <= 8'd0;
                frame_peak_margin <= 8'd0;
                x_count <= 10'd0;
                y_count <= 10'd0;
                frame_x_min <= IMG_WIDTH - 1;
                frame_y_min <= IMG_HEIGHT - 1;
                frame_x_max <= 10'd0;
                frame_y_max <= 10'd0;
                target_pixels <= 16'd0;
            end

            if (pipe_valid) begin
                pixel_x_base = pipe_user ? 10'd0 : x_count;
                pixel_y_base = pipe_user ? 10'd0 : y_count;
                target_count_base = pipe_user ? 16'd0 : target_pixels;
                next_x_min = pipe_user ? IMG_WIDTH - 1 : frame_x_min;
                next_y_min = pipe_user ? IMG_HEIGHT - 1 : frame_y_min;
                next_x_max = pipe_user ? 10'd0 : frame_x_max;
                next_y_max = pipe_user ? 10'd0 : frame_y_max;
                red_lane_count = {2'd0, red_pixel[0]} +
                                 {2'd0, red_pixel[1]} +
                                 {2'd0, red_pixel[2]} +
                                 {2'd0, red_pixel[3]};
                beat_peak_r = pipe_user ? 8'd0 : frame_peak_r;
                beat_peak_margin = pipe_user ? 8'd0 : frame_peak_margin;
                beat_peak_x = pipe_user ? 11'd0 : frame_peak_x;
                beat_peak_y = pipe_user ? 11'd0 : frame_peak_y;
                if (red_best_valid &&
                    ((red_best_r > beat_peak_r) ||
                     ((red_best_r == beat_peak_r) &&
                      (red_best_margin > beat_peak_margin)))) begin
                    beat_peak_r = red_best_r;
                    beat_peak_margin = red_best_margin;
                    beat_peak_x = pixel_x_base + red_best_lane;
                    beat_peak_y = pixel_y_base;
                end
                red_lane_count = {2'd0, red_pixel[0]} +
                                 {2'd0, red_pixel[1]} +
                                 {2'd0, red_pixel[2]} +
                                 {2'd0, red_pixel[3]};
                if ((red_lane_count >= 3'd2) &&
                    ((red_pixel[0] && red_pixel[1]) ||
                     (red_pixel[1] && red_pixel[2]) ||
                     (red_pixel[2] && red_pixel[3]))) begin
                    frame_peak_r <= beat_peak_r;
                    frame_peak_margin <= beat_peak_margin;
                    frame_peak_x <= beat_peak_x;
                    frame_peak_y <= beat_peak_y;
                end
                if ((red_lane_count >= 3'd2) &&
                    ((red_pixel[0] && red_pixel[1]) ||
                     (red_pixel[1] && red_pixel[2]) ||
                     (red_pixel[2] && red_pixel[3]))) begin
                    target_sum = {1'b0, (pipe_user ? 16'd0 : frame_red_count)} + red_lane_count;
                    frame_red_count <= target_sum[16] ? 16'hffff : target_sum[15:0];
                end

                if (pipe_last) begin
                    x_count <= 10'd0;
                    if (y_count == IMG_HEIGHT - 1) begin
                        y_count <= 10'd0;
                        previous_frame_valid <= 1'b1;
                    end else begin
                        y_count <= y_count + 10'd1;
                    end
                end else begin
                    x_count <= x_count + 10'd4;
                end
            end
        end
    end
endmodule

// Streaming grid difference: four-pixel mean, causal 2x2 support, area gate,
// flash rejection and adaptive edge smoothing. One prior grid in block RAM.
module motion_grid_stable #(
    parameter WIDTH=1280,HEIGHT=720,THRESHOLD=20,
    parameter MIN_CELLS=6,HOLD_FRAMES=2,DEADBAND=8,FAST_STEP=48
)(
    input wire clk,rst_n,valid,sof,last,frame_ready,
    input wire [95:0] rgb,
    output reg [11:0] motion_count,
    output reg motion_valid,
    output reg [10:0] x_min,y_min,x_max,y_max
);
    localparam COLS=(WIDTH+15)/16,ROWS=(HEIGHT+15)/16,SIZE=COLS*ROWS;
    localparam AW=(SIZE<=2)?1:$clog2(SIZE);
    reg [10:0] x,y;
    wire [10:0] px=sof?11'd0:x,py=sof?11'd0:y;
    wire sample=valid&&(px[3:0]==0)&&(py[3:0]==0);
    wire [AW-1:0] address=(py>>4)*COLS+(px>>4);
    function [7:0] luma;
        input [23:0] p;
        reg [9:0] sum;
        begin sum={2'b0,p[23:16]}+{1'b0,p[15:8],1'b0}+{2'b0,p[7:0]};luma=sum[9:2];end
    endfunction
    wire [9:0] luma_sum={2'b0,luma(rgb[23:0])}+{2'b0,luma(rgb[47:24])}+
                        {2'b0,luma(rgb[71:48])}+{2'b0,luma(rgb[95:72])};
    (* ram_style="bram" *) reg [7:0] prior [0:SIZE-1];
    reg [7:0] prior_q,new_q;
    reg sample_q,compare_q,hit_q,hit_valid;
    reg [10:0] sx_q,sy_q,hx,hy;
    wire [8:0] delta=(new_q>=prior_q)?new_q-prior_q:prior_q-new_q;
    // Read-before-write inference: the first frame initializes all addresses.
    always @(posedge clk) if(sample) begin
        prior_q<=prior[address];prior[address]<=luma_sum[9:2];
    end
    reg [COLS-1:0] above;
    reg left_hit,upper_left;
    wire up_hit=(hy!=0)?above[hx>>4]:1'b0;
    wire left_ok=(hx!=0)&&left_hit;
    wire diag_ok=(hx!=0)&&(hy!=0)&&upper_left;
    // Keep thin moving boundaries (including diagonal edges); isolated hits
    // still fail, and the frame must contain MIN_CELLS supported samples.
    wire supported=hit_q&&(left_ok||up_hit||diag_ok);
    reg [11:0] cells,raw_cells;
    reg [10:0] bx0,by0,bx1,by1;
    reg [3:0] missing;
    wire [10:0] cell_x0=(left_ok||diag_ok)?hx-11'd16:hx;
    wire [10:0] cell_y0=(up_hit||diag_ok)?hy-11'd16:hy;
    wire [10:0] cell_x1=(hx+11'd15<WIDTH)?hx+11'd15:WIDTH-1;
    wire [10:0] cell_y1=(hy+11'd15<HEIGHT)?hy+11'd15:HEIGHT-1;
    function [10:0] follow_edge;
        input [10:0] old_value,new_value;
        reg [10:0] diff;
        begin
            diff=(new_value>=old_value)?new_value-old_value:old_value-new_value;
            if(diff<=DEADBAND) follow_edge=old_value;
            else if(diff>=FAST_STEP) follow_edge=new_value;
            else if(new_value>old_value) follow_edge=old_value+((diff+1'b1)>>1);
            else follow_edge=old_value-((diff+1'b1)>>1);
        end
    endfunction
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            x<=0;y<=0;sample_q<=0;compare_q<=0;new_q<=0;
            sx_q<=0;sy_q<=0;hit_q<=0;hit_valid<=0;hx<=0;hy<=0;
            above<=0;left_hit<=0;upper_left<=0;cells<=0;raw_cells<=0;
            bx0<=WIDTH-1;by0<=HEIGHT-1;bx1<=0;by1<=0;missing<=0;
            motion_count<=0;motion_valid<=0;x_min<=0;y_min<=0;x_max<=0;y_max<=0;
        end else begin
            sample_q<=sample;hit_valid<=sample_q;
            if(sample) begin
                new_q<=luma_sum[9:2];compare_q<=frame_ready;sx_q<=px;sy_q<=py;
            end
            if(sample_q) begin
                hit_q<=compare_q&&(delta>=THRESHOLD);hx<=sx_q;hy<=sy_q;
            end
            if(sof) begin
                cells<=0;raw_cells<=0;left_hit<=0;upper_left<=0;
                bx0<=WIDTH-1;by0<=HEIGHT-1;bx1<=0;by1<=0;
                motion_count<=cells;
                if(frame_ready && raw_cells<SIZE/2 && cells>=MIN_CELLS) begin
                    motion_valid<=1;missing<=0;
                    x_min<=motion_valid?follow_edge(x_min,bx0):bx0;
                    y_min<=motion_valid?follow_edge(y_min,by0):by0;
                    x_max<=motion_valid?follow_edge(x_max,bx1):bx1;
                    y_max<=motion_valid?follow_edge(y_max,by1):by1;
                end else if(frame_ready && raw_cells>=SIZE/2) begin
                    // Camera shake/exposure jumps cannot identify a local target.
                    motion_valid<=0;missing<=0;motion_count<=0;
                end else if(motion_valid && missing<HOLD_FRAMES) missing<=missing+1'b1;
                else begin motion_valid<=0;missing<=0;end
            end else if(hit_valid) begin
                above[hx>>4]<=hit_q;upper_left<=up_hit;left_hit<=hit_q;
                if(hit_q && raw_cells!=12'hfff) raw_cells<=raw_cells+1'b1;
                if(supported) begin
                    if(cells!=12'hfff) cells<=cells+1'b1;
                    if(cell_x0<bx0) bx0<=cell_x0;
                    if(cell_y0<by0) by0<=cell_y0;
                    if(cell_x1>bx1) bx1<=cell_x1;
                    if(cell_y1>by1) by1<=cell_y1;
                end
            end
            if(sof) begin x<=0;y<=0;end
            if(valid) begin
                if(last) begin x<=0;y<=(py==HEIGHT-1)?11'd0:py+1'b1;end
                else begin x<=px+11'd4;y<=py;end
            end
        end
    end
endmodule
