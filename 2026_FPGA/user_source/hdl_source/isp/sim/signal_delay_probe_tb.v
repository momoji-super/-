`timescale 1ns/1ps
module blk_mem_gen_awb_delay_signal(input clka,wea,input [10:0] addra,input [95:0] dia,input clkb,input [10:0] addrb,output reg [95:0] dob);
reg[95:0] mem[0:2047];always @(posedge clka)if(wea)mem[addra]<=dia;
always @(posedge clkb)dob<=mem[addrb];
endmodule
module signal_delay_probe_tb;
reg clk=0,rst=0,v=0,u=0;reg[95:0] d=0;wire ov,ou;wire[95:0]q;
always #5 clk=~clk;
signal_delay #(.IMG_WIDTH(1024),.IMG_HEIGHT(8)) dut(clk,rst,u,v,d,ov,q,ou);
integer x,y,n=0,errors=0,idx=0;
always @(posedge clk)begin #1;if(ov)begin
 if(q!==idx)begin if(errors<10)$display("MISMATCH n=%0d got=%h exp=%0d",n,q,idx);errors=errors+1;end
 idx=idx+1;n=n+1;
end end
initial begin repeat(4)@(negedge clk);rst=1;
for(y=0;y<8;y=y+1)begin
 for(x=0;x<256;x=x+1)begin @(negedge clk);v=1;u=(y==0&&x==0);d=y*256+x;end
 @(negedge clk);v=0;u=0;repeat(240)@(negedge clk);
end
repeat(400)@(negedge clk);$display("probe output beats=%0d errors=%0d",n,errors);$finish;end
endmodule
