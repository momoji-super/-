`timescale 1ns/1ps
module packer_720p_tb;
 reg clk=0,rst=0,v=0,u=0,l=0;reg[95:0]d=0;
 wire ov,ou,ol;wire[127:0]q;
 always #5 clk=~clk;
 data_96bit_to_128bit dut(clk,rst,u,v,l,d,ou,ol,ov,q);
 integer f,x,y,k,j,words=0,frames=0,byte_index=0;
 function [7:0] val;
  input integer n,frame;
  begin val=(n*23+frame*77+(n/3)*11)&255;end
 endfunction
 always @(posedge clk) begin #1;
  if(ov)begin
   if(ou!==(words==0))$fatal(1,"packer SOF");
   for(j=0;j<16;j=j+1)if(q[127-j*8-:8]!==val(byte_index+j,frames))$fatal(1,"packer byte%0d",byte_index+j);
   byte_index=byte_index+16;words=words+1;
   if(words==1280*720*3/16)begin frames=frames+1;words=0;byte_index=0;end
  end
 end
 initial begin
  repeat(5)@(negedge clk);rst=1;
  for(f=0;f<2;f=f+1)begin
   for(y=0;y<720;y=y+1)begin
    for(x=0;x<1280;x=x+4)begin
     @(negedge clk);v=1;u=(x==0&&y==0);l=(x==1276);
     for(k=0;k<4;k=k+1)d[k*24+:24]={val((y*1280+x+k)*3,f),val((y*1280+x+k)*3+1,f),val((y*1280+x+k)*3+2,f)};
     if(x%12==0)begin @(negedge clk);v=0;u=0;end
    end
    @(negedge clk);v=0;u=0;l=0;repeat(3)@(negedge clk);
   end
   repeat(20)@(negedge clk);
  end
  if(frames!=2 || words!=0)$fatal(1,"packer count");
  $display("PASS packer 2 full720p frames, arbitrary gaps, RGB byte and pixel order");$finish;
 end
endmodule
