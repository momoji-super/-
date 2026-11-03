`timescale 1ns/1ps
module rgb_area_2_3_tb;
 parameter IW=1920,IH=1080;
 localparam OW=IW*2/3,OH=IH*2/3;
 reg clk=0,rst=0,v=0,u=0,l=0;
 reg [95:0] d=0;
 wire [95:0] q;wire ov,ou,ol;
 integer f,x,y,k,j,ox=0,oy=0,frames=0,count=0;
 reg [23:0] expected;
 always #5 clk=~clk;
 rgb_area_2_3 #(.IN_WIDTH(IW),.IN_HEIGHT(IH)) dut(clk,rst,d,v,u,l,q,ov,ou,ol);
 function [7:0] source;
  input integer xx,yy,channel,frame;
  begin
   case(frame)
    0:source=128;
    1:source=((xx^yy)&1)?255:0;
    default:source=(xx*17+yy*31+channel*67+((xx*yy)>>3))&255;
   endcase
  end
 endfunction
 function integer horizontal;
  input integer xx,yy,channel,frame;
  integer a,b;
  begin
   a=(xx/2)*3+(xx%2);b=a+1;
   horizontal=(xx%2==0)?(2*source(a,yy,channel,frame)+source(b,yy,channel,frame)+1)/3:
                                     (source(a,yy,channel,frame)+2*source(b,yy,channel,frame)+1)/3;
  end
 endfunction
 function [7:0] reference;
  input integer xx,yy,channel,frame;
  integer a,b;
  begin
   a=(yy/2)*3+yy%2;b=a+1;
   reference=(yy%2==0)?(2*horizontal(xx,a,channel,frame)+horizontal(xx,b,channel,frame)+1)/3:
                                     (horizontal(xx,a,channel,frame)+2*horizontal(xx,b,channel,frame)+1)/3;
  end
 endfunction
 always @(posedge clk) begin
  #1;
  if(ov) begin
   if(ou!==((ox==0)&&(oy==0)) || ol!==(ox==OW-4))$fatal(1,"area sidebands x%0d y%0d",ox,oy);
   for(j=0;j<4;j=j+1) begin
    expected={reference(ox+j,oy,2,frames),reference(ox+j,oy,1,frames),reference(ox+j,oy,0,frames)};
    if(q[j*24+:24]!==expected)$fatal(1,"area frame%0d x%0d y%0d actual%h expected%h",frames,ox+j,oy,q[j*24+:24],expected);
   end
   count=count+1;
   if(ol)begin ox=0;if(oy==OH-1)begin oy=0;frames=frames+1;end else oy=oy+1;end else ox=ox+4;
  end
 end
 initial begin
  repeat(5)@(negedge clk);rst=1;
  for(f=0;f<3;f=f+1)begin
   // Also exercise SOF in a cycle without valid data.
   if(f==1)begin @(negedge clk);u=1;@(negedge clk);u=0;end
   for(y=0;y<IH;y=y+1) begin
    for(x=0;x<IW;x=x+4)begin
     @(negedge clk);v=1;u=(f!=1 && x==0 && y==0);l=(x==IW-4);
     for(k=0;k<4;k=k+1)d[k*24+:24]={source(x+k,y,2,f),source(x+k,y,1,f),source(x+k,y,0,f)};
     if(f==2 && x%44==0)begin @(negedge clk);v=0;u=0;l=0;end
    end
    @(negedge clk);v=0;u=0;l=0;repeat(y%7)@(negedge clk);
   end
   repeat(25)@(negedge clk);
  end
  if(frames!=3 || count!=3*OW*OH/4)$fatal(1,"area missing pixels frames%0d count%0d",frames,count);
  $display("PASS area full-frame %0dx%0d -> %0dx%0d, 3 frames pixel-exact, gaps and SOF",IW,IH,OW,OH);$finish;
 end
 initial begin #100000000;$fatal(1,"area timeout");end
endmodule
