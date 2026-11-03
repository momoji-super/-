`timescale 1ns/1ps
// Functional divider pipeline model; test AWB control/data alignment only.
module divider(input clk,rst,start,input[31:0]denominator,input[47:0]numerator,output[47:0]quotient,output done);
reg[47:0]q[0:49];reg[49:0]v;integer i;
always @(posedge clk)begin
 if(rst)begin v<=0;for(i=0;i<50;i=i+1)q[i]<=0;end
 else begin
 v<={v[48:0],start};q[0]<=denominator?numerator/denominator:48'hffffffffffff;
 for(i=1;i<50;i=i+1)q[i]<=q[i-1];
 end
end
assign quotient=q[49];assign done=v[49];
endmodule
module awb_colour_probe_tb;
reg clk=0,rst=0,v=0,u=0,l=0;reg[95:0]d=0;
wire ov,ou,ol;wire[95:0]q;integer x,y,f,col=0,row=0,errors=0,count=0;
always #5 clk=~clk;
awb #(.IMG_WIDTH(1024),.IMG_HEIGHT(16)) dut(clk,rst,l,u,d,v,,ol,ou,q,ov,1'b1);
always @(posedge clk)begin #1;if(ov)begin
 if(q!=={4{24'h808080}})begin
 if(errors<20)$display("COLOUR ERROR row=%0d col=%0d data=%h",row,col,q);errors=errors+1;end
 count=count+1;
 if(col==255)begin col=0;row=row+1;end else col=col+1;
end end
initial begin repeat(4)@(negedge clk);rst=1;
for(f=0;f<2;f=f+1)begin
 for(y=0;y<16;y=y+1)begin
  for(x=0;x<256;x=x+1)begin @(negedge clk);v=1;u=(y==0&&x==0);l=(x==255);d={4{24'h808080}};end
  @(negedge clk);v=0;u=0;l=0;
  repeat(y%2?1100:950)@(negedge clk);
 end
 repeat(100)@(negedge clk);
end
repeat(200)@(negedge clk);$display("AWB probe beats %0d errors %0d",count,errors);$finish;
end
endmodule
