`timescale 1ns/1ps
module frame_awb_tb;
reg clk=0,rst=0,v=0,u=0,l=0,en=1;
reg[95:0]d=0;wire[95:0]q;wire ov,ou,ol;
always #5 clk=~clk;
frame_awb #(.IMG_WIDTH(16),.IMG_HEIGHT(4),.MIN_SAMPLES(8)) dut(clk,rst,d,v,u,l,en,q,ov,ou,ol);
integer f,x,y,k,outputs=0,users=0,lasts=0;
reg[9:0]gr,gb;
reg[95:0]exp[0:1023];reg eu[0:1023],el[0:1023];integer wr=0;
integer rr,bb;reg[23:0]pix;
always @(posedge clk)begin #1;if(ov)begin
 if(q!==exp[outputs]||ou!==eu[outputs]||ol!==el[outputs])$fatal(1,"AWB output mismatch %0d %h %h",outputs,q,exp[outputs]);
 outputs=outputs+1;if(ou)users=users+1;if(ol)lasts=lasts+1;
end end
task frame;
input[23:0]p;
begin
 for(y=0;y<4;y=y+1)for(x=0;x<4;x=x+1)begin
  @(negedge clk);v=1;u=(y==0&&x==0);l=(x==3);d={4{p}};
  // Expected gains must remain fixed throughout this input frame.
  if(u)begin
   gr=(dut.pending && en)?dut.next_r:dut.gain_r;
   gb=(dut.pending && en)?dut.next_b:dut.gain_b;
  end else if(dut.gain_r!=gr||dut.gain_b!=gb)$fatal(1,"gain changed within frame");
  rr=(p[23:16]*(en?gr:10'd256))>>8;
  bb=(p[7:0]*(en?gb:10'd256))>>8;
  pix={(rr>255?8'd255:rr[7:0]),p[15:8],(bb>255?8'd255:bb[7:0])};
  exp[wr]={4{pix}};eu[wr]=u;el[wr]=l;wr=wr+1;
 end
 @(negedge clk);v=0;u=0;l=0;repeat(45)@(negedge clk);
end endtask
initial begin
 repeat(4)@(negedge clk);rst=1;
 for(f=0;f<16;f=f+1)frame(24'h408040);
 if(dut.gain_r<500||dut.gain_b<500)$fatal(1,"colour cast failed to converge");
 gr=dut.gain_r;gb=dut.gain_b;en=0;
 frame(24'h808080);frame(24'h808080);
 if(dut.gain_r!=gr||dut.gain_b!=gb)$fatal(1,"diagnostic changed stored gains");
 en=1;
 for(f=0;f<16;f=f+1)frame(24'h808080);
 if(dut.gain_r>268||dut.gain_b>268)$fatal(1,"neutral failed to converge");
 frame(24'h000000);frame(24'hffffff);
 if(outputs!=wr||users!=36||lasts!=144)$fatal(1,"count mismatch %0d %0d %0d",outputs,users,lasts);
 $display("PASS frame AWB pixel math, frame gain latch, cast/neutral convergence, diagnostic freeze, black/clipped handling");$finish;
end
initial begin #1000000;$fatal(1,"timeout");end
endmodule
