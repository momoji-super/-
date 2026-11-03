`timescale 1ns/1ps
module frame_awb_full_tb;
reg clk=0,rst=0,v=0,u=0,l=0;reg[95:0]d={4{24'h408040}};
wire[95:0]q;wire ov,ou,ol;
integer x,y,f,count=0;reg[9:0]saved_r,saved_b;
always #5 clk=~clk;
frame_awb dut(clk,rst,d,v,u,l,1'b1,q,ov,ou,ol);
always @(posedge clk)begin #1;if(ov)begin
 count=count+1;
 if(q[95:72]!==q[23:0] || q[47:24]!==q[23:0])$fatal(1,"lane colour mismatch");
end end
initial begin
 repeat(4)@(negedge clk);rst=1;
 for(f=0;f<3;f=f+1)begin
  for(y=0;y<600;y=y+1)begin
   for(x=0;x<256;x=x+1)begin @(negedge clk);v=1;u=(y==0&&x==0);l=(x==255);end
   @(negedge clk);v=0;u=0;l=0;repeat(60)@(negedge clk);
  end
  repeat(80)@(negedge clk);
  if(dut.sum_r!=64*1024*600||dut.sum_g!=128*1024*600||dut.sum_b!=64*1024*600)$fatal(1,"full frame sums");
 end
 if(dut.gain_r!=368||dut.gain_b!=368)$fatal(1,"full-frame ratio/smoothing %0d",dut.gain_r);
 if(count!=3*153600)$fatal(1,"pixel count");
 $display("PASS 1024x600 frame AWB full-frame sums/division/smoothing, %0d beats",count);$finish;
end
initial begin #100000000;$fatal(1,"timeout");end
endmodule
