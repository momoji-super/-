`timescale 1ns/1ps
module video_stripe_diag_tb;
reg clk=0,rst=0,rv=0,ru=0,cv=0,cu=0;reg[1:0]mode=0;
reg[39:0]rd=40'h123456789a;reg[95:0]cd={4{24'h123456}};
wire[39:0]ro;wire[95:0]co;
always #5 clk=~clk;
video_stripe_diag dut(clk,rst,mode,rd,rv,ru,cd,cv,cu,ro,co);
integer i;reg[9:0]g;reg[23:0]c;
initial begin
 repeat(3)@(negedge clk);rst=1;
 if(ro!==rd || co!==cd)$fatal(1,"live path changed");
 mode=1;
 for(i=0;i<256;i=i+1)begin
  @(negedge clk);rv=1;ru=(i==0);#1;
  g=256+(i/32)*32;
  if(ro!=={4{g}})$fatal(1,"RAW step %0d",i);
 end
 @(negedge clk);rv=0;ru=0;mode=2;
 for(i=0;i<256;i=i+1)begin
  @(negedge clk);cv=1;cu=(i==0);#1;
  case(i/32)
   0:c=24'h808080;1:c=24'hffffff;2:c=24'hffff00;3:c=24'h00ffff;
   4:c=24'h00ff00;5:c=24'hff00ff;6:c=24'hff0000;7:c=24'h0000ff;
  endcase
  if(co!=={4{c}})$fatal(1,"RGB bar %0d",i);
 end
 @(negedge clk);cv=0;cu=0;mode=0;
 // mode changes only on next stream frame start.
 #1;if(co!=={4{24'h808080}})$fatal(1,"frame latch");
 @(negedge clk);cu=1;cv=1;#1;if(co!==cd)$fatal(1,"live resume");
 $display("PASS diagnostic live bypass, RAW steps/RGB bars, frame-latched mode");$finish;
end
endmodule
