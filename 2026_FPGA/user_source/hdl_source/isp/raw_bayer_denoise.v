`ifndef RAW_BAYER_DENOISE_V
`define RAW_BAYER_DENOISE_V
// Light edge-aware prefilter BEFORE decimation. Only same Bayer colour
// sites (x-2,y) and (x,y-2) contribute. No RGB/Bayer phase mixing.
// Fixed two-register latency, bypass has identical sideband timing.
module raw_bayer_denoise #(
 parameter IMG_WIDTH=1920,
 parameter DIFFERENCE_LIMIT=48
)(
 input I_clk,I_rst_n,input [39:0] I_data,
 input I_valid,I_user,input I_enable,
 output reg [39:0] O_data,output reg O_valid,O_user
);
 localparam WORDS=IMG_WIDTH/4;
 localparam AW=(WORDS>1)?$clog2(WORDS):1;
 reg [39:0] line_even[0:WORDS-1];
 reg [39:0] line_odd[0:WORDS-1];
 reg [AW-1:0] x;
 reg [15:0] y;
 reg [19:0] history;
 reg enabled;
 wire [AW-1:0] addr=I_user?{AW{1'b0}}:x;
 wire [15:0] row=I_user?16'd0:y;
 reg [39:0] current_d,horizontal_d,vertical_d;
 reg valid_d,user_d,enable_d,has_v_d;
 reg [3:0] has_h_d;
 integer k;
 function [9:0] blend;
 input [9:0] c,h,v;
 input hh,vv;
 reg [10:0] dh,dv;
 reg [11:0] sum;
 reg [9:0] nh,nv;
 begin
  dh=(c>=h)?{1'b0,c}-{1'b0,h}:{1'b0,h}-{1'b0,c};
  dv=(c>=v)?{1'b0,c}-{1'b0,v}:{1'b0,v}-{1'b0,c};
  nh=(hh && dh<=DIFFERENCE_LIMIT)?h:c;
  nv=(vv && dv<=DIFFERENCE_LIMIT)?v:c;
  sum={2'd0,c}+{2'd0,c}+{2'd0,nh}+{2'd0,nv}+12'd2;
  blend=sum[11:2];
 end
 endfunction
 // Read-before-write gives the previous row of the same Bayer parity.
 always @(posedge I_clk) if(I_rst_n && I_valid) begin
  if(row[0])begin vertical_d<=line_odd[addr];line_odd[addr]<=I_data;end
  else begin vertical_d<=line_even[addr];line_even[addr]<=I_data;end
 end
 always @(posedge I_clk or negedge I_rst_n) begin
  if(!I_rst_n)begin
   x<=0;y<=0;history<=0;enabled<=1;
   current_d<=0;horizontal_d<=0;valid_d<=0;user_d<=0;
   enable_d<=1;has_v_d<=0;has_h_d<=0;
   O_data<=0;O_valid<=0;O_user<=0;
  end else begin
   if(I_user)begin x<=0;y<=0;history<=0;enabled<=I_enable;end
   valid_d<=I_valid;user_d<=I_user;
   enable_d<=I_user?I_enable:enabled;
   if(I_valid)begin
    current_d<=I_data;
    horizontal_d<={I_data[19:0],history};
    has_h_d<={2'b11,{2{addr!=0}}};has_v_d<=row>=2;
    history<=I_data[39:20];
    if(addr==WORDS-1)begin x<=0;y<=row+1'b1;end
    else x<=addr+1'b1;
   end
   O_valid<=valid_d;O_user<=user_d;
   if(valid_d)for(k=0;k<4;k=k+1)
    O_data[k*10+:10]<=enable_d?
      blend(current_d[k*10+:10],horizontal_d[k*10+:10],vertical_d[k*10+:10],has_h_d[k],has_v_d):current_d[k*10+:10];
  end
 end
endmodule
`endif
