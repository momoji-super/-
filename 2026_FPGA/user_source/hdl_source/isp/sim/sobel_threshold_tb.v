`timescale 1ns/1ps
module sobel_threshold_tb;
reg clk=0,rst_n=0,valid=0,user=0,last=0;
reg [95:0] data=0;
reg [2:0] mode=5;
reg [7:0] threshold=128;
wire [95:0] out_data;wire out_valid,out_user,out_last;
integer x,y,k;
integer output_beats=0, white_pixels=0;
integer dark_count;
always @(posedge clk) begin
 #1;
 if(out_valid) begin
  output_beats=output_beats+1;
  for(k=0;k<4;k=k+1)
   if(out_data[k*24+:24] === 24'hffffff) white_pixels=white_pixels+1;
 end
end
reg [23:0] pix;
always #5 clk=~clk;
image_algo_switch #(.IMG_WIDTH(16),.IMG_HEIGHT(8)) dut(
 .I_clk(clk),.I_rst_n(rst_n),.I_tdata(data),.I_tvalid(valid),.I_tuser(user),.I_tlast(last),.I_tready(),
 .O_tdata(out_data),.O_tvalid(out_valid),.O_tuser(out_user),.O_tlast(out_last),
 .I_algo_mode(mode),.I_threshold(threshold));
task send_image;
input [7:0] th;
integer xx,yy,n;
begin
 @(negedge clk);threshold=th;
 for(yy=0;yy<8;yy=yy+1)begin
  for(xx=0;xx<16;xx=xx+4)begin
   @(negedge clk);user=(xx==0&&yy==0);last=(xx==12);
   valid=1;data=0;
   for(n=0;n<4;n=n+1)begin
    pix=(xx+n<8)?24'h404040:24'h505050;
    data[n*24+:24]=pix;
   end
  end
 end
 @(negedge clk);valid=0;user=0;last=0;
 repeat(6) @(negedge clk);
end endtask
initial begin
 repeat(3)@(negedge clk);rst_n=1;
 send_image(128);
 if(white_pixels!=0) $fatal(1,"weak edge should be rejected at 128");
 dark_count=output_beats;
 send_image(48);
 if(white_pixels!=12) $fatal(1,"48 must detect 2 columns x 6 rows, got %0d",white_pixels);
 if(output_beats-dark_count!=32) $fatal(1,"frame beat count changed");
 $display("PASS Sobel edge threshold updates between frames");$finish;
end
initial begin #200000;$fatal(1,"timeout");end
endmodule
