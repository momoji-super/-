`ifndef FRAME_AWB_V
`define FRAME_AWB_V
// One pair of Q8 gains for the whole image. Ratios are calculated once
// per frame by a shared-cycle restoring divider, never in the pixel path.
module frame_awb #(
 parameter IMG_WIDTH=1024,IMG_HEIGHT=600,MIN_SAMPLES=1024
)(
 input I_clk,I_rst_n,input [95:0] I_data,
 input I_valid,I_user,I_last,input I_update_enable,
 output reg [95:0] O_data,output reg O_valid,O_user,O_last
);
 localparam BEATS=IMG_WIDTH*IMG_HEIGHT/4;
 reg [19:0] beats,samples;
 reg [29:0] sum_r,sum_g,sum_b;
 reg [9:0] gain_r,gain_b,next_r,next_b;
 reg pending,active,busy,ratio_ready;
 reg [9:0] ratio_r,ratio_b;
 reg [5:0] left;
 reg [37:0] dividend_r,dividend_b,quot_r,quot_b;
 reg [30:0] rem_r,rem_b,den_r,den_b;
 wire [30:0] trial_r={rem_r[29:0],dividend_r[37]};
 wire [30:0] trial_b={rem_b[29:0],dividend_b[37]};
 wire bit_r=trial_r>=den_r,bit_b=trial_b>=den_b;
 wire [37:0] result_r={quot_r[36:0],bit_r};
 wire [37:0] result_b={quot_b[36:0],bit_b};
 reg [9:0] br,bg,bb;
 reg [2:0] bn;
 integer j,k;
 reg [23:0] p;
 always @* begin
  br=0;bg=0;bb=0;bn=0;
  for(j=0;j<4;j=j+1)begin
   p=I_data[j*24+:24];
   // Reject near-black and clipped pixels, use identical sample mask.
   if(p[23:16]>=16 && p[23:16]<=240 && p[15:8]>=16 && p[15:8]<=240 && p[7:0]>=16 && p[7:0]<=240)begin
    br=br+{2'd0,p[23:16]};bg=bg+{2'd0,p[15:8]};bb=bb+{2'd0,p[7:0]};bn=bn+1'b1;
   end
  end
 end
 reg [9:0] br_d,bg_d,bb_d;
 reg [2:0] bn_d;
 reg stat_valid,stat_user,stat_enable,finish_frame;
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin br_d<=0;bg_d<=0;bb_d<=0;bn_d<=0;stat_valid<=0;stat_user<=0;stat_enable<=0;end
  else begin br_d<=br;bg_d<=bg;bb_d<=bb;bn_d<=bn;stat_valid<=I_valid;stat_user<=I_user;stat_enable<=I_update_enable;end
 end
 function [9:0] clamp;
 input [37:0] v;
 begin clamp=(v<128)?10'd128:((v>512)?10'd512:v[9:0]);end
 endfunction
 function [9:0] smooth;
 input [9:0] old_gain,target;
 reg [9:0] delta,step;
 begin
  delta=(target>old_gain)?target-old_gain:old_gain-target;
  step=delta>>2;if(step==0 && delta>2)step=1;
  smooth=(delta<=2)?old_gain:((target>old_gain)?old_gain+step:old_gain-step);
 end
 endfunction
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   beats<=0;samples<=0;sum_r<=0;sum_g<=0;sum_b<=0;
   gain_r<=256;gain_b<=256;next_r<=256;next_b<=256;
   pending<=0;active<=0;busy<=0;left<=0;finish_frame<=0;ratio_ready<=0;ratio_r<=256;ratio_b<=256;
   dividend_r<=0;dividend_b<=0;quot_r<=0;quot_b<=0;
   rem_r<=0;rem_b<=0;den_r<=1;den_b<=1;
  end else begin
   finish_frame<=0;
   ratio_ready<=0;
   if(ratio_ready)begin next_r<=smooth(gain_r,ratio_r);next_b<=smooth(gain_b,ratio_b);pending<=1;end
   if(I_user && pending && I_update_enable)begin gain_r<=next_r;gain_b<=next_b;pending<=0;end
   if(stat_user)begin
    beats<=0;samples<=0;sum_r<=0;sum_g<=0;sum_b<=0;active<=stat_enable;
   end
   if(stat_valid && (stat_user?stat_enable:active))begin
    beats<=(stat_user?20'd0:beats)+1'b1;
    samples<=(stat_user?20'd0:samples)+bn_d;
    sum_r<=(stat_user?30'd0:sum_r)+br_d;
    sum_g<=(stat_user?30'd0:sum_g)+bg_d;
    sum_b<=(stat_user?30'd0:sum_b)+bb_d;
    if((stat_user?20'd0:beats)==BEATS-1)begin active<=0;finish_frame<=1;end
   end
   if(finish_frame && !busy && samples>=MIN_SAMPLES && sum_r!=0 && sum_b!=0)begin
    dividend_r<={sum_g,8'd0};dividend_b<={sum_g,8'd0};
    den_r<={1'b0,sum_r};den_b<={1'b0,sum_b};
    rem_r<=0;rem_b<=0;quot_r<=0;quot_b<=0;left<=38;busy<=1;
   end
   if(busy)begin
    dividend_r<={dividend_r[36:0],1'b0};dividend_b<={dividend_b[36:0],1'b0};
    rem_r<=bit_r?trial_r-den_r:trial_r;rem_b<=bit_b?trial_b-den_b:trial_b;
    quot_r<=result_r;quot_b<=result_b;left<=left-1'b1;
    if(left==1)begin
     ratio_r<=clamp(result_r);ratio_b<=clamp(result_b);
     ratio_ready<=1;busy<=0;
    end
   end
  end
 end
 reg [17:0] product_r[0:3],product_b[0:3];
 reg [7:0] green[0:3];reg vd,ud,ld;
 // Diagnostic patterns are not camera color data; render them at unity gain.
 wire [9:0] apply_r=!I_update_enable?10'd256:
                    ((I_user && pending)?next_r:gain_r);
 wire [9:0] apply_b=!I_update_enable?10'd256:
                    ((I_user && pending)?next_b:gain_b);
 function [7:0] saturate;
 input [17:0] v;
 begin saturate=(v[17:8]>255)?8'd255:v[15:8];end
 endfunction
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   vd<=0;ud<=0;ld<=0;O_valid<=0;O_user<=0;O_last<=0;O_data<=0;
   for(k=0;k<4;k=k+1)begin product_r[k]<=0;product_b[k]<=0;green[k]<=0;end
  end else begin
   vd<=I_valid;ud<=I_user;ld<=I_last;
   if(I_valid)for(k=0;k<4;k=k+1)begin
    product_r[k]<=I_data[k*24+16+:8]*apply_r;
    product_b[k]<=I_data[k*24+:8]*apply_b;
    green[k]<=I_data[k*24+8+:8];
   end
   O_valid<=vd;O_user<=ud;O_last<=ld;
   if(vd)for(k=0;k<4;k=k+1)O_data[k*24+:24]<={saturate(product_r[k]),green[k],saturate(product_b[k])};
  end
 end
endmodule
`endif
