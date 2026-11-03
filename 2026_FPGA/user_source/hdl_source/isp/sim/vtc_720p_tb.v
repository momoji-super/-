`timescale 1ns/1ps
module vtc_720p_tb;
 reg clk=0,rst=0;always #5 clk=~clk;
 wire vs,hs,de,u,l;
 uivtc dut(rst,clk,vs,hs,de,u,l);
 integer cycles=0,pixels=0,lines=0,hs_ticks=0,vs_ticks=0,frames=0,line_pixels=0;
 reg started=0;
 always @(posedge clk)begin #1;
  if(rst)begin
   if(u)begin
    if(started)begin
     if(cycles!=1650*750 || pixels!=1280*720 || lines!=720 || hs_ticks!=40*750 || vs_ticks!=5*1650)
      $fatal(1,"VTC bad cycles%0d pixels%0d lines%0d hs%0d vs%0d",cycles,pixels,lines,hs_ticks,vs_ticks);
     frames=frames+1;
     if(frames==2)begin $display("PASS VTC 1280x720, totals1650x750, HS40 VS5, aligned sidebands");$finish;end
    end
    started=1;cycles=0;pixels=0;lines=0;hs_ticks=0;vs_ticks=0;
   end
   if(started)begin
    cycles=cycles+1;hs_ticks=hs_ticks+hs;vs_ticks=vs_ticks+vs;
    if(de)begin pixels=pixels+1;line_pixels=line_pixels+1;end
    if(l)begin
     if(!de || line_pixels!=1280)$fatal(1,"VTC line length%0d",line_pixels);
     lines=lines+1;line_pixels=0;
    end
    if(u && !de)$fatal(1,"VTC SOF without DE");
   end
  end
 end
 initial begin repeat(5)@(negedge clk);rst=1;#30000000;$fatal(1,"VTC timeout");end
endmodule
