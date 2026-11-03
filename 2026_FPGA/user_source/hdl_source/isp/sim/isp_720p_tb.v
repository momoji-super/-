`timescale 1ns/1ps
module blk_mem_gen_zhenghe(input clka,wea,input[10:0]addra,input[31:0]dia,input clkb,web,input[31:0]dib,input[10:0]addrb,output reg[31:0]dob);
reg[31:0]m[0:2047];always @(posedge clka)if(wea)m[addra]<=dia;always @(posedge clkb)dob<=m[addrb];endmodule
module blk_mem_gen_demosaic(input clka,wea,input[10:0]addra,input[32:0]dia,input clkb,web,input[32:0]dib,input[10:0]addrb,output reg[32:0]dob);
reg[32:0]m[0:2047];always @(posedge clka)if(wea)m[addra]<=dia;always @(posedge clkb)dob<=m[addrb];endmodule
module isp_720p_tb;
 reg clk=0,rst=0,v=0,u=0,l=0;reg[39:0]d=0;
 wire ov,ou;wire[127:0]q;
 integer f,x,y,dem_beats=0,scaled_beats=0,packed_words=0,sofs=0,sx=0,sy=0,dx=0,dy=0;
 always #5 clk=~clk;
 isp_top dut(.axi4s_video_aclk(clk),.I_rst_n(rst),.I_tlast(l),.I_tuser(u),.I_tdata(d),.I_tvalid(v),.I_tdest(10'd0),
  .I_diag_mode(2'd0),.I_algo_mode(3'd0),.I_algo_threshold(8'd48),.I_vivid_enable(1'b0),.I_luma_ack_toggle(1'b0),
  .O_tdata(q),.O_tvalid(ov),.O_tuser(ou));
 always @(posedge clk)begin #1;
  if(dut.m_aixs_tvalid) begin
   if(dut.m_aixs_tuser!==(dx==0&&dy==0) || dut.m_aixs_tlast!==(dx==479))$fatal(1,"ISP demosaic sidebands dx%0d dy%0d",dx,dy);
   dem_beats=dem_beats+1;
   if(dx==479)begin dx=0;dy=(dy==1079)?0:dy+1;end else dx=dx+1;
  end
  if(dut.scaled_valid) begin
   if(dut.scaled_user!==(sx==0&&sy==0) || dut.scaled_last!==(sx==319))$fatal(1,"ISP scaler sidebands");
   if(sy>=4 && sy<716 && sx>=4 && sx<316 && dut.scaled_data!=={12{8'd128}})$fatal(1,"ISP interior grey x%0d y%0d data%h",sx,sy,dut.scaled_data);
   scaled_beats=scaled_beats+1;
   if(sx==319)begin sx=0;sy=(sy==719)?0:sy+1;end else sx=sx+1;
  end
  if(ov) begin
   if(^q===1'bx)$fatal(1,"ISP undefined DDR data");
   if(ou!==(packed_words%172800==0))$fatal(1,"ISP DDR SOF word%0d",packed_words);
   if(dut.O_tlast!==(packed_words%240==239))$fatal(1,"ISP DDR line end word%0d last%0b",packed_words,dut.O_tlast);
   packed_words=packed_words+1;
  end
  if(ou)sofs=sofs+1;
 end
 initial begin
  repeat(8)@(negedge clk);rst=1;
  for(f=0;f<2;f=f+1)begin
   for(y=0;y<1080;y=y+1) begin
    for(x=0;x<480;x=x+1)begin @(negedge clk);v=1;u=(x==0&&y==0);l=(x==479);d={4{10'd512}};end
    @(negedge clk);v=0;u=0;l=0;repeat(160)@(negedge clk);
   end
   repeat(1000)@(negedge clk);
  end
  if(dem_beats!=2*1920*1080/4 || scaled_beats!=2*1280*720/4 || packed_words!=2*1280*720*3/16 || sofs!=2)
   $fatal(1,"ISP counts dem%0d scaled%0d packed%0d sof%0d",dem_beats,scaled_beats,packed_words,sofs);
  $display("PASS ISP 2 full1080p frames -> 2 full720p frames ->345600 DDR words; grey interior, no undefined pixels");$finish;
 end
 initial begin #100000000;$fatal(1,"ISP timeout");end
endmodule
