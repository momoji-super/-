// RGB888 four-lane stream -> dense 160x90 mask. Fixed isotropic 8x8 blocks.
// The color gate is an initial heuristic, NOT a trained hand detector.
module hand_mask_frontend #(
    parameter IMG_WIDTH=1280, IMG_HEIGHT=720, MIN_SKIN_PIXELS=16,
    parameter ROI_X_MIN=320, ROI_X_MAX=959, ROI_Y_MIN=80
)(
    input clk,rst_n,enable,input [95:0] rgb_data,input valid,user,last,
    output reg frame_start,sample_valid,sample_skin,
    output reg [7:0] sample_x,sample_y
);
    localparam COLS=IMG_WIDTH/8;
    reg [95:0] rgb_q;
    reg v0,u0,l0,v1,u1,l1;
    reg [3:0] skin;
    reg [10:0] x;
    reg [9:0] y;
    reg active,bad;
    wire [10:0] bx=u1?11'd0:x;
    wire [9:0] by=u1?10'd0:y;
    wire live=u1?enable:active;
    wire line_ok=(l1==(bx==IMG_WIDTH-4));
    wire [7:0] col=bx[10:3];
    wire [2:0] hits={2'd0,skin[0]}+{2'd0,skin[1]}+{2'd0,skin[2]}+{2'd0,skin[3]};
    reg [2:0] half_hits;
    reg [6:0] accum [0:COLS-1];
    reg [6:0] accum_q;
    wire [6:0] total=((by[2:0]==0)?7'd0:accum_q)+{4'd0,half_hits}+{4'd0,hits};
    integer k;
    // Widen before arithmetic. Simple opponent-color + brightness conditions
    // use no multipliers and reject neutral/green/blue and saturated red.
    function is_skin;
        input [23:0] p;
        reg [9:0] lum;
        reg signed [10:0] cr,cb;
        reg [8:0] r,g,b;
        begin
            r={1'b0,p[23:16]};g={1'b0,p[15:8]};b={1'b0,p[7:0]};
            lum={1'b0,r}+{g,1'b0}+{1'b0,b};
            cr=$signed({r,2'b00})-$signed({1'b0,lum});
            cb=$signed({b,2'b00})-$signed({1'b0,lum});
            is_skin=(r>=70)&&(g>=35)&&(b>=20)&&(r>=g+9'd8)&&
                    (g+9'd32>=b)&&(lum>=160)&&(lum<=940)&&
                    (cr>=11'sd40)&&(cr<=11'sd420)&&
                    (cb>=-11'sd360)&&(cb<=11'sd10);
        end
    endfunction
    // Register the tap, then classification, so neither adds a combinational
    // path to existing AWB/red tracking. Sidebands are delayed identically.
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin rgb_q<=0;v0<=0;u0<=0;l0<=0;v1<=0;u1<=0;l1<=0;skin<=0;end
        else begin
            rgb_q<=rgb_data;v0<=valid;u0<=user;l0<=last;
            v1<=v0;u1<=u0;l1<=l0;
            for(k=0;k<4;k=k+1) skin[k]<=is_skin(rgb_q[k*24+:24]);
        end
    end
    // One synchronous read per first half-block; the next valid beat commits.
    // Row zero overwrites every accumulator, so no RAM reset is required.
    always @(posedge clk) begin
        if(v1 && live && col<COLS && bx[2]==0) accum_q<=accum[col];
        if(v1 && live && !bad && line_ok && col<COLS && bx[2]) accum[col]<=total;
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            x<=0;y<=0;active<=0;bad<=0;half_hits<=0;
            frame_start<=0;sample_valid<=0;sample_skin<=0;sample_x<=0;sample_y<=0;
        end else begin
            frame_start<=0;sample_valid<=0;
            if(u1) begin x<=0;y<=0;active<=enable;bad<=0;frame_start<=enable;end
            if(v1 && live) begin
                if(!line_ok) bad<=1;
                if(!bx[2]) half_hits<=hits;
                else if(by[2:0]==7 && !bad && line_ok && col<COLS) begin
                    sample_valid<=1;sample_x<=col;sample_y<=by[9:3];
                    sample_skin<=(total>=MIN_SKIN_PIXELS)&&
                        (bx>=ROI_X_MIN)&&(bx<=ROI_X_MAX)&&(by>=ROI_Y_MIN);
                end
                if(l1) begin x<=0;y<=by+1'b1;if(by==IMG_HEIGHT-1)active<=0;end
                else begin x<=bx+11'd4;y<=by;end
            end
        end
    end
endmodule
