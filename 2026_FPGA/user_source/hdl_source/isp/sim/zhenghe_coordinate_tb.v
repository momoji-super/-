`timescale 1ns/1ps
module zhenghe_coordinate_tb;
reg clk=0,rst=0,v=0,u=0,l=0;reg[31:0]d=0;
wire ov,ou,ol;wire[31:0]q;
always #5 clk=~clk;
zhenghe #(.IMG_WIDTH(1024),.IMG_HEIGHT(8),.DATA_WIDTH(32),.data_complete_delay(50)) dut(clk,rst,l,u,d,v,ol,ou,q,ov);
integer x,y,idx=0,count=0,errors=0;
always @(posedge clk)begin #1;if(ov)begin
 if(q!==idx)begin if(errors<12)$display("coordinate mismatch beat %0d got%h expected%0d",count,q,idx);errors=errors+1;end
 if(ou!==(idx==0))begin errors=errors+1;$display("SOF mismatch");end
 if(ol!==((idx%256)==255))begin errors=errors+1;$display("EOL mismatch");end
 idx=idx+1;count=count+1;end end
initial begin repeat(4)@(negedge clk);rst=1;
for(y=0;y<8;y=y+1)begin
 for(x=0;x<256;x=x+1)begin @(negedge clk);v=1;u=(y==0&&x==0);l=(x==255);d=y*256+x;end
 @(negedge clk);v=0;u=0;l=0;repeat(y%2?1100:950)@(negedge clk);
end
repeat(600)@(negedge clk);
if(count!=2048||errors!=0)$fatal(1,"coordinate line test count%0d errors%0d",count,errors);
$display("PASS line consolidation coordinates/SOF/EOL, 2048 beats");$finish;end
endmodule
