`timescale 1ns/1ps
module raw_bayer_resize_tb;
parameter IW=1920,IH=1080,OW=1024,OH=600;
reg clk=0,rst=0,v=0,u=0;reg [39:0] d=0;
wire [39:0] q;wire qv,qu,ql;
always #5 clk=~clk;
raw_bayer_resize #(.IN_WIDTH(IW),.IN_HEIGHT(IH),.OUT_WIDTH(OW),.OUT_HEIGHT(OH)) dut(clk,rst,d,v,u,q,qv,qu,ql);
integer xm[0:OW-1],ym[0:OH-1];
integer x,y,n,p,h,idx,f,ox=0,oy=0,frames=0,words=0;
reg previous_valid=0;
function [9:0] value;
 input integer a,b;
 begin value=(a*3+b*7)%1024;end
endfunction
always @(posedge clk) begin
 #1;
 if(rst) begin
  if(previous_valid && !qv && ox!=0) $fatal(1,"output valid bubble within line");
  if(qv)begin
   if(qu!==((ox==0)&&(oy==0)))$fatal(1,"SOF alignment");
   if(ql!==(ox==OW-4))$fatal(1,"EOL alignment");
   for(n=0;n<4;n=n+1)
    if(q[n*10+:10]!==value(xm[ox+n],ym[oy]))
     $fatal(1,"pixel mismatch at %0d,%0d lane %0d got%0d exp%0d",ox,oy,n,q[n*10+:10],value(xm[ox+n],ym[oy]));
   words=words+1;
   if(ql) begin ox=0;if(oy==OH-1)begin oy=0;frames=frames+1;end else oy=oy+1;end
   else ox=ox+4;
  end
  previous_valid=qv;
 end
end
initial begin
 h=IW/2-OW/2;idx=0;
 for(p=0;p<IW/2;p=p+1)begin h=h+OW/2;if(h>=IW/2)begin h=h-IW/2;xm[idx]=2*p;xm[idx+1]=2*p+1;idx=idx+2;end end
 if(idx!=OW)$fatal(1,"x count");
 h=IH/2-OH/2;idx=0;
 for(p=0;p<IH/2;p=p+1)begin h=h+OH/2;if(h>=IH/2)begin h=h-IH/2;ym[idx]=2*p;ym[idx+1]=2*p+1;idx=idx+2;end end
 if(idx!=OH)$fatal(1,"y count");
 repeat(4)@(negedge clk);rst=1;
 for(f=0;f<2;f=f+1) begin
  for(y=0;y<IH;y=y+1)begin
   for(x=0;x<IW;x=x+4)begin
    @(negedge clk);v=1;u=(x==0 && y==0);
    d={value(x+3,y),value(x+2,y),value(x+1,y),value(x,y)};
   end
   @(negedge clk);v=0;u=0;
   repeat(25)@(negedge clk);
  end
  repeat(600)@(negedge clk);
 end
 if(frames!=2 || words!=2*OW*OH/4)$fatal(1,"missing frame or words %0d %0d",frames,words);
 $display("PASS 1080p to 1024x600 Bayer phase, coordinates, continuous lines, 2 frames, %0d words",words);$finish;
end
initial begin #100000000;$fatal(1,"timeout");end
endmodule
