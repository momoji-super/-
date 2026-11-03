`timescale 1ns/1ps
// Functional FIFO model: records writes that survive the actual video_in reset.
module w128_d512_fifo(input rst,clkw,clkr,we,re,input[127:0]di,
 output[127:0]dout,output[8:0]wrusedw,rdusedw,
 output valid,full_flag,empty_flag,afull,aempty);
integer accepted=0,dropped=0;reg[127:0]seen[0:1023];
always @(posedge clkw)begin
 if(we)begin
  if(rst)dropped=dropped+1;
  else begin seen[accepted]=di;accepted=accepted+1;end
 end
end
assign dout=0;assign wrusedw=0;assign rdusedw=0;
assign valid=0;assign full_flag=0;assign empty_flag=1;assign afull=0;assign aempty=1;
endmodule
module camera_fifo_guard_tb;
reg clk=0,ddr=0,rst=0,fs=0,v=0;
reg[127:0]d=0;wire gv;wire[127:0]gd;
always #4.444 clk=~clk;
always #7.5 ddr=~ddr;
camera_fifo_guard guard(clk,rst,v,d,gv,gd);
video_in raw_path(.I_rst_n(rst),.I_camera_clk(clk),.I_camera_frame_start(fs),.I_camera_valid(v),.I_camera_data(d),.I_mipi_rx_error(1'b0),.I_ddr_clk(ddr),.I_display_pause(1'b0),.I_video_out_rd_busy(1'b0),.I_ddr_user_ready(1'b1));
video_in safe_path(.I_rst_n(rst),.I_camera_clk(clk),.I_camera_frame_start(fs),.I_camera_valid(gv),.I_camera_data(gd),.I_mipi_rx_error(1'b0),.I_ddr_clk(ddr),.I_display_pause(1'b0),.I_video_out_rd_busy(1'b0),.I_ddr_user_ready(1'b1));
integer i,sent=0,received=0;
reg[127:0]expected[0:1023];
always @(posedge clk)begin
 if(rst && v)begin expected[sent]=d;sent=sent+1;end
 #1;
 if(rst && gv)begin
  if(gd!==expected[received])$fatal(1,"guard data/valid mismatch %0d",received);
  received=received+1;
 end
end
initial begin
 repeat(10)@(negedge clk);rst=1;repeat(10)@(negedge clk);
 for(i=0;i<192;i=i+1)begin
  @(negedge clk);fs=(i==0);v=(i%4!=0);d=i;
 end
 @(negedge clk);fs=0;v=0;
 repeat(100)@(negedge clk);
 if(raw_path.U_w128_d512_fifo.dropped==0)$fatal(1,"baseline failed to reproduce reset/write collision");
 if(safe_path.U_w128_d512_fifo.dropped!=0)$fatal(1,"guarded FIFO loses data during reset");
 if(sent!=received || safe_path.U_w128_d512_fifo.accepted!=sent)$fatal(1,"missing data");
 for(i=0;i<sent;i=i+1)if(safe_path.U_w128_d512_fifo.seen[i]!==expected[i])$fatal(1,"FIFO pixel order %0d",i);
 $display("PASS baseline dropped %0d packed words; guard lost 0, all %0d words ordered",raw_path.U_w128_d512_fifo.dropped,sent);$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
