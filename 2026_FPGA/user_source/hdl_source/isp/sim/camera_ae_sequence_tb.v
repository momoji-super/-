`timescale 1ns/1ps
// Protocol-engine stub tests the register sequencer, not sensor electrical ACK.
module uii2c #(parameter WMEN_LEN=4,RMEN_LEN=1,CLK_DIV=2)(
 input I_clk,I_rstn,output O_iic_scl,inout IO_iic_sda,
 input [WMEN_LEN*8-1:0] I_wr_data,input [7:0] I_wr_cnt,
 output [RMEN_LEN*8-1:0] O_rd_data,input [7:0] I_rd_cnt,
 input I_iic_mode,I_iic_req,output reg O_iic_busy=0);
 integer n=0;
 assign O_iic_scl=1;assign O_rd_data=0;
 always @(posedge I_clk) begin
  if(!I_rstn) begin O_iic_busy<=0;n<=0;end
  else if(I_iic_req && !O_iic_busy) begin O_iic_busy<=1;n<=12;end
  else if(n!=0) begin n<=n-1;if(n==1) O_iic_busy<=0;end
 end
endmodule
module camera_ae_sequence_tb;
reg clk=0,rst=0,req=0;reg [15:0] exp=1800,gain=80;
wire done,init,scl;tri sda;
integer writes=0,k;reg [31:0] captured[0:140];
always #5 clk=~clk;
uicfgcs500 #(.CLK_DIV(4)) dut(clk,rst,req,exp,gain,scl,sda,init,done);
always @(posedge dut.iic_req) begin captured[writes]=dut.wr_data;writes=writes+1;end
function [23:0] decoded;
input [31:0] p;
begin decoded={p[15:8],p[23:16],p[31:24]};end
endfunction
task check5;
 input integer base;
 input [15:0] e,g;
 begin
  if(decoded(captured[base])!=={16'h3e00,4'd0,e[15:12]}) $fatal(1,"3e00");
  if(decoded(captured[base+1])!=={16'h3e01,e[11:4]}) $fatal(1,"3e01");
  if(decoded(captured[base+2])!=={16'h3e02,e[3:0],4'd0}) $fatal(1,"3e02");
  if(decoded(captured[base+3])!=={16'h3e08,g[15:8]}) $fatal(1,"3e08");
  if(decoded(captured[base+4])!=={16'h3e09,g[7:0]}) $fatal(1,"3e09");
 end
endtask
initial begin
 repeat(3) @(negedge clk);rst=1;
 wait(done);repeat(5) @(negedge clk);
 if(writes!=128) $fatal(1,"init did not transition directly into 5 AE writes: %0d",writes);
 if(decoded(captured[101])!=={16'h3e00,8'h00} ||
    decoded(captured[102])!=={16'h3e01,8'h70} ||
    decoded(captured[103])!=={16'h3e02,8'h80}) $fatal(1,"initial exposure is not 1800 half-lines");
 if(decoded(captured[119])!=={16'h3e08,8'h0f} ||
    decoded(captured[120])!=={16'h3e09,8'h20}) $fatal(1,"initial analog gain is not 4x");
 check5(123,1800,16'h0f20);
 exp=2244;gain=112;req=1;@(negedge clk);req=0;
 wait(!done);repeat(4) @(negedge clk);exp=16;gain=16;
 wait(done);repeat(5) @(negedge clk);
 if(writes!=133) $fatal(1,"update length");check5(128,2244,16'h1f20);
 exp=1800;gain=140;req=1;@(negedge clk);req=0;
 wait(!done);repeat(4) @(negedge clk);wait(done);repeat(5) @(negedge clk);
 if(writes!=138) $fatal(1,"15x gain update length: %0d",writes);
 check5(133,1800,16'h1f3c);
 if(decoded(captured[136])!=={16'h3e08,8'h1f} ||
    decoded(captured[137])!=={16'h3e09,8'h3c}) $fatal(1,"15x gain did not map to SC500CS register code");
 $display("PASS camera init + 8x/15x analog-gain updates + settings snapshot");$finish;
end
initial begin #1000000;$fatal(1,"timeout");end
endmodule
