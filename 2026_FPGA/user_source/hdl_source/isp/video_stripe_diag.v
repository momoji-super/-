`ifndef VIDEO_STRIPE_DIAG_V
`define VIDEO_STRIPE_DIAG_V
// Camera-timed diagnostic patterns. Never changes pixel count or blanking.
// Mode 0 live; 1 RAW horizontal grey steps through ISP; 2 RGB bars after AWB.
module video_stripe_diag #(parameter RAW_WIDTH=1920,RGB_WIDTH=1280)(
 input clk,rst_n,input[1:0] mode,
 input[39:0] raw_data,input raw_valid,raw_user,
 input[95:0] rgb_data,input rgb_valid,rgb_user,
 output[39:0] raw_out,output[95:0] rgb_out
);
 reg[1:0] raw_mode,rgb_mode;
 reg[10:0] raw_x,rgb_x;
 wire[10:0] rx=raw_user?11'd0:raw_x;
 wire[10:0] cx=rgb_user?11'd0:rgb_x;
 wire[1:0] rm=raw_user?mode:raw_mode;
 wire[1:0] cm=rgb_user?mode:rgb_mode;
 wire[2:0] rb=rx/(RAW_WIDTH/32),cb=cx/(RGB_WIDTH/32);
 wire[9:0] grey={rb,7'b1000000};
 reg[23:0] colour;
 always @* case(cb)
 0:colour=24'h808080;
 1:colour=24'hffffff;
 2:colour=24'hffff00;
 3:colour=24'h00ffff;
 4:colour=24'h00ff00;
 5:colour=24'hff00ff;
 6:colour=24'hff0000;
 7:colour=24'h0000ff;
 endcase
 assign raw_out=(rm==1)?{4{grey}}:raw_data;
 assign rgb_out=(cm==2)?{4{colour}}:rgb_data;
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin raw_x<=0;rgb_x<=0;raw_mode<=0;rgb_mode<=0;end
  else begin
   if(raw_user)begin raw_mode<=mode;raw_x<=0;end
   if(rgb_user)begin rgb_mode<=mode;rgb_x<=0;end
   if(raw_valid)raw_x<=(rx==RAW_WIDTH/4-1)?0:rx+1'b1;
   if(rgb_valid)rgb_x<=(cx==RGB_WIDTH/4-1)?0:cx+1'b1;
  end
 end
endmodule
`endif
