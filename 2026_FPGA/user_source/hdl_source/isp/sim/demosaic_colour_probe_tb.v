`timescale 1ns/1ps
module blk_mem_gen_zhenghe(input clka,wea,input[10:0]addra,input[31:0]dia,input clkb,input[10:0]addrb,output reg[31:0]dob);
reg[31:0]m[0:2047];always @(posedge clka)if(wea)m[addra]<=dia;always @(posedge clkb)dob<=m[addrb];endmodule
module blk_mem_gen_demosaic(input clka,wea,input[10:0]addra,input[32:0]dia,input clkb,input[10:0]addrb,output reg[32:0]dob);
reg[32:0]m[0:2047];always @(posedge clka)if(wea)m[addra]<=dia;always @(posedge clkb)dob<=m[addrb];endmodule
module demosaic_colour_probe_tb;
reg clk=0,rst=0,v=0,u=0,l=0;reg[39:0]d=0;
wire ov,ou,ol;wire[127:0]q;integer x,y,f,col=0,row=0,errors=0,count=0,k;reg[31:0]p;
always #5 clk=~clk;
demosaic #(.IMG_WIDTH(1024),.IMG_HEIGHT(16),.data_complete_delay(50),.BAYER_MODE("BGGR")) dut(.I_clk(clk),.I_rst_n(rst),.axi4s_video_tdata(d),.axi4s_video_tdest(10'd0),.axi4s_video_tlast(l),.axi4s_video_tvalid(v),.axi4s_video_tuser(u),.axi4s_video_tready(),.O_tlast(ol),.O_tuser(ou),.O_tdata(q),.O_tvalid(ov),.O_tready(1'b1));
always @(posedge clk)begin #1;if(ov)begin
 if(ou)begin col=0;row=0;end
 // Ignore the literal image outer boundary, check uniform interior.
 if(row>=3 && col>=3 && col<250)begin
  if(q!=={4{32'h00808080}})begin
   if(errors<12)$display("DEMOSAIC row=%0d col=%0d data=%h",row,col,q);errors=errors+1;end
 end
 count=count+1;if(col==255)begin col=0;row=row+1;end else col=col+1;
end end
initial begin repeat(4)@(negedge clk);rst=1;
for(f=0;f<2;f=f+1)begin
 for(y=0;y<16;y=y+1)begin
  for(x=0;x<256;x=x+1)begin @(negedge clk);v=1;u=(y==0&&x==0);l=(x==255);d={4{10'd512}};end
  @(negedge clk);v=0;u=0;l=0;repeat(y%2?1100:950)@(negedge clk);
 end
 repeat(500)@(negedge clk);
end
repeat(500)@(negedge clk);$display("DEMOSAIC probe beats %0d errors %0d",count,errors);$finish;
end
endmodule
