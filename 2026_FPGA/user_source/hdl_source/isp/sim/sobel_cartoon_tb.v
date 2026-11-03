`timescale 1ns/1ps
module sobel_cartoon_tb;
parameter WIDTH=16;
localparam HEIGHT=8;
reg clk=0,rst=0,v=0,u=0,l=0;
reg [95:0] data=0;
reg [2:0] mode=0;
wire [95:0] out;
wire ov,ou,ol;
always #5 clk=~clk;
image_algo_switch #(.IMG_WIDTH(WIDTH),.IMG_HEIGHT(HEIGHT)) dut(clk,rst,data,v,u,l,,out,ov,ou,ol,mode,8'd128,1'b1);
reg [23:0] image[0:WIDTH*HEIGHT-1];
reg [95:0] expected[0:28*WIDTH*HEIGHT/4];
reg eu[0:28*WIDTH*HEIGHT/4],el[0:28*WIDTH*HEIGHT/4];
integer wr=0,rd=0,f,x,y,k,a,b,gx,gy,mag,xx,yy;
reg [95:0] beat,expbeat;
reg [23:0] p;
function integer lum;
input [23:0] p;
begin lum=(p[23:16]*77+p[15:8]*150+p[7:0]*29)>>8; end
endfunction
function [23:0] quant;
input [23:0] p;
begin quant={p[23:21],5'b10000,p[15:13],5'b10000,p[7:5],5'b10000}; end
endfunction
always @(posedge clk) begin
 #1;
 if(rst && ov) begin
  if(rd>=wr || out!==expected[rd] || ou!==eu[rd] || ol!==el[rd]) begin
   $display("FAIL beat=%0d got=%h expected=%h",rd,out,expected[rd]); $fatal(1);
  end
  rd=rd+1;
 end
end
initial begin
 repeat(3) @(negedge clk); rst=1;
 for(f=0;f<28;f=f+1) begin
  mode=f%7;
  for(a=0;a<WIDTH*HEIGHT;a=a+1) begin
   case(f/7)
    0:image[a]=$random;
    1:image[a]=24'h808080;
    2:image[a]=(a%WIDTH>=7)?24'hffffff:0;
    3:image[a]=(a/WIDTH>=3)?24'hffffff:0;
   endcase
  end
  for(y=0;y<8;y=y+1) begin
   for(x=0;x<WIDTH;x=x+4) begin
    beat=0; expbeat=0;
    for(k=0;k<4;k=k+1) begin
     xx=x+k; p=image[y*WIDTH+xx]; beat[k*24+:24]=p;
     mag=0;
     if(y>=2 && xx>=2) begin
      gx=0;gy=0;
      for(a=0;a<3;a=a+1) begin
       gx=gx+(a==1?2:1)*(lum(image[(y-2+a)*WIDTH+xx])-lum(image[(y-2+a)*WIDTH+xx-2]));
       gy=gy+(a==1?2:1)*(lum(image[(y-2)*WIDTH+xx-2+a])-lum(image[y*WIDTH+xx-2+a]));
      end
      mag=(gx<0?-gx:gx)+(gy<0?-gy:gy);
     end
     case(f%7)
      0:expbeat[k*24+:24]=p;
      1:begin b=lum(p); expbeat[k*24+:24]={b[7:0],b[7:0],b[7:0]}; end
      2:expbeat[k*24+:24]=lum(p)>=128?24'hffffff:0;
      3:expbeat[k*24+:24]=~p;
      4:begin b=lum(p); expbeat[k*24+:24]=(p[23:16]>p[15:8]+32 && p[23:16]>p[7:0]+32)?p:{b[7:0],b[7:0],b[7:0]}; end
      5:expbeat[k*24+:24]=mag>=128?24'hffffff:0;
      6:expbeat[k*24+:24]=mag>=128?0:quant((y>=2 && xx>=2)?image[(y-1)*WIDTH+xx-1]:p);
     endcase
    end
    @(negedge clk);
    expected[wr]=expbeat;eu[wr]=(x==0 && y==0);el[wr]=(x==WIDTH-4);wr=wr+1;
    data=beat;v=1;u=(x==0 && y==0);l=(x==WIDTH-4);
    // Exercise valid bubbles, including line-end pauses.
    if((x==4)||(x==WIDTH-4)) begin @(negedge clk);v=0;u=0;l=0; end
   end
  end
  @(negedge clk);v=0;u=0;l=0;
  repeat(4) @(negedge clk);
 end
 repeat(5) @(negedge clk);
 if(rd!=wr) $fatal(1,"lost output");
 $display("PASS seven modes random/flat/vertical/horizontal reference: %0d beats",rd);$finish;
end
initial begin #10000000; $fatal(1,"timeout"); end
endmodule
