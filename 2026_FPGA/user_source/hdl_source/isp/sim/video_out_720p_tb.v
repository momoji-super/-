`timescale 1ns/1ps
// Registered-read dual-clock FIFO model. Checks access bounds as well as pixels.
module w128_d512_fifo(input rst,clkw,we,input [127:0] di,
 output [8:0] wrusedw,output afull,full_flag,input clkr,re,
 output reg [127:0] dout,output [8:0] rdusedw,output valid,empty_flag,aempty);
 reg [127:0] mem[0:511];integer wp=0,rp=0;
 assign wrusedw=(wp-rp)&511; assign rdusedw=wrusedw;
 assign empty_flag=(wp==rp);assign aempty=(wp-rp<4);
 assign afull=(wp-rp>=500);assign full_flag=(wp-rp>=511);assign valid=!empty_flag;
 always @(posedge clkw or posedge rst)
  if(rst)wp<=0;else if(we)begin
   if(wp-rp>=511)$fatal(1,"read FIFO overflow");
   mem[wp&511]<=di;wp<=wp+1;
  end
 always @(posedge clkr or posedge rst)
  if(rst)begin rp<=0;dout<=0;end else if(re)begin
   if(wp==rp)$fatal(1,"read FIFO underflow");
   dout<=mem[rp&511];rp<=rp+1;
  end
endmodule

module video_out_720p_tb;
 reg dc=0,pc=0,rst=0,vs=0,de=0,hs=0,us=0,ls=0;
 reg ready=0,wrbusy=0,rv=0;reg[127:0]rd=0;
 wire ren,busy;wire[24:0]addr;wire[23:0]pix,hpix;
 wire hde,hvs,hhs;
 integer cycles=0,requested=0,received=0,frame=0,f,y,x,j,pending=0;
 reg[2:0]vp=0;reg[24:0]ap[0:2];
 reg check_pixel;reg[23:0]expected;
 always #7.5 dc=~dc;always #6.734006734 pc=~pc;
 video_out dut(.I_rst_n(rst),.I_ddr_clk(dc),.O_video_out_rd_busy(busy),
 .I_video_in_wr_busy(wrbusy),.I_video_out_rp(2'd0),.O_ddr_user_rd_en(ren),
 .O_ddr_user_addr(addr),.I_ddr_user_ready(ready),.I_ddr_user_rd_valid(rv),
 .I_ddr_user_rd_data(rd),.I_dsi_clk(pc),.I_video_vsync(vs),.I_video_rd_en(de),.O_vdieo_data(pix));
 hdmi_mixer mix(.I_clk(pc),.I_rst_n(rst),.I_video_vsync(~vs),.I_video_hsync(hs),
 .I_video_de(de),.I_video_user(us),.I_video_last(ls),.I_debug_status(4'd0),
 .I_algo_mode(3'd0),.I_edge_threshold(8'd48),.I_ae_target_level(3'd3),.I_ae_value(16'd0),
 .I_ae_mode(1'b1),.I_tracking_mode(1'b0),.I_capture_frame_id(16'd0),.I_display_frame_id(16'd0),
 .I_osd_enable(1'b0),
 .I_target_valid(1'b0),.I_target_x_min(11'd0),.I_target_y_min(11'd0),.I_target_x_max(11'd0),
 .I_target_y_max(11'd0),.I_target_center_x(11'd0),.I_target_center_y(11'd0),.I_motion_count(12'd0),
 .I_motion_valid(1'b0),.I_motion_x_min(11'd0),.I_motion_y_min(11'd0),.I_motion_x_max(11'd0),
 .I_motion_y_max(11'd0),.O_video_rd_en(),.I_video_rd_data(pix),
 .O_hdmi_vsync(hvs),.O_hdmi_hsync(hhs),.O_hdmi_de(hde),.O_hdmi_data(hpix));
 function[7:0] byteval;input integer n;begin byteval=(n*17+(n/3)*5+(n/3840)*19)&255;end endfunction
 always @(posedge dc)begin
  cycles=cycles+1;
  ready<=rst&&(cycles%7!=0);wrbusy<=rst&&(cycles%1000<100);
  vp<={vp[1:0],ren};ap[0]<=addr;ap[1]<=ap[0];ap[2]<=ap[1];rv<=vp[2];
  for(j=0;j<16;j=j+1)rd[127-j*8-:8]<=byteval((ap[2]/8)*16+j);
  if(ren)begin
   if(addr!==requested*8)$fatal(1,"DDR address got%0d expected%0d",addr,requested*8);
   requested=requested+1;
   if(requested>172800)$fatal(1,"DDR frame overread");
  end
 end
 always @(posedge pc)begin #1;
  if(hde)begin
   expected={byteval(received*3),byteval(received*3+1),byteval(received*3+2)};
   if(hpix!==expected)$fatal(1,"HDMI pixel%0d got%h expected%h",received,hpix,expected);
   received=received+1;
  end
 end
 task blank;input integer n;integer k;begin
  for(k=0;k<n;k=k+1)begin @(negedge pc);de=0;us=0;ls=0;end
 end endtask
 initial begin
  blank(20);rst=1;blank(100);
  for(f=0;f<2;f=f+1)begin
   requested=0;received=0;vs=1;blank(1650*20);
   for(y=0;y<720;y=y+1)begin
    for(x=0;x<1280;x=x+1)begin
     @(negedge pc);de=1;us=(y==0&&x==0);ls=(x==1279);
    end
    blank(370);
   end
   blank(1650*10);vs=0;blank(1650*5);
   if(received!=921600||requested!=172800)$fatal(1,"frame counts pixels%0d words%0d",received,requested);
  end
  $display("PASS video_out_720p_tb: two complete DDR->RGB->HDMI frames, gaps, bounds, alignment");$finish;
 end
 initial begin #100000000;$fatal(1,"video out timeout");end
endmodule
