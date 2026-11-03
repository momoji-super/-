`timescale 1ns/1ps
module auto_exposure_tb;
reg clk=0,rst=1,toggle=0,done=1,cam=0;
reg [7:0] luma=0;
reg [19:0] highlights=0;
reg [7:0] target_low=184,target_high=204;
reg manual_gain_enable=0;
reg [15:0] manual_gain=80;
wire ack,req;
wire [7:0] debug_luma;
wire [15:0] exp,gain;
integer requests=0;
reg [15:0] saved_exp,saved_gain;
always #5 clk=~clk;
auto_exposure #(.EXP_MIN(16),.EXP_MAX(2244),.EXP_INITIAL(1800),.GAIN_INITIAL(80),.SETTLE_FRAMES(2)) dut(
 .I_clk(clk),.I_rst(rst),.I_luma_toggle(toggle),.I_avg_luma(luma),
 .I_highlight_count(highlights),
 .I_target_low(target_low),.I_target_high(target_high),
 .I_manual_gain_enable(manual_gain_enable),.I_manual_gain(manual_gain),
 .I_cam_cfg_done(cam),.I_ae_cfg_done(done),.O_luma_ack_toggle(ack),
 .O_luma_debug(debug_luma),.O_ae_req(req),.O_ae(exp),.O_ag(gain));
// Emulate asynchronous config engine busy/done, ensure settings remain stable.
always begin
 @(posedge req); requests=requests+1;
 saved_exp=exp;saved_gain=gain;
 repeat(3) @(negedge clk);done=0;
 repeat(20) begin @(negedge clk); if(exp!==saved_exp || gain!==saved_gain) $fatal(1,"settings changed during I2C");end
 done=1;
end
task frame;
 input [7:0] value;
 begin
  @(negedge clk); luma=value;toggle=~toggle;
  wait(ack==toggle);
  repeat(35) @(negedge clk);
 end
endtask
integer i;
initial begin
 repeat(3) @(negedge clk);rst=0;
 repeat(5) @(negedge clk); if(req) $fatal(1,"request before camera init");cam=1;
 repeat(40) @(negedge clk);
 if(requests!=1) $fatal(1,"initial settings not sent");
 frame(20);frame(20);
 if(exp!=1800) $fatal(1,"initial sensor settling changed settings");
 highlights=6144;
 // A bright frame with a small saturated region must reduce exposure;
 // a dark indoor mean is intentionally allowed to remain bright.
 frame(220);
 if(exp>=1800 || gain!=80) $fatal(1,"highlight guard did not reduce exposure first");
 highlights=0;
 for(i=0;i<50;i=i+1) frame(20);
 if(exp!=2244 || gain!=140) $fatal(1,"dark saturation limits incorrect: exp=%0d gain=%0d",exp,gain);
 for(i=0;i<240;i=i+1) frame(250);
 if(exp!=16 || gain!=16) $fatal(1,"bright saturation limits incorrect");
 manual_gain_enable=1;
 luma=196;
 saved_exp=exp;saved_gain=gain;
 for(i=0;i<8;i=i+1) frame(196);
 if(exp!=saved_exp || gain!=saved_gain) $fatal(1,"deadband moved settings");
 manual_gain=48; frame(196);
 if(exp!=saved_exp || gain!=48) $fatal(1,"manual gain changed exposure or missed gain preset: exp=%0d gain=%0d reqs=%0d",exp,gain,requests);
 manual_gain=112; repeat(5) frame(196);
 if(exp!=saved_exp || gain!=112) $fatal(1,"manual gain 8x endpoint incorrect: exp=%0d gain=%0d",exp,gain);
 manual_gain=140; repeat(5) frame(196);
 if(exp!=saved_exp || gain!=140) $fatal(1,"manual gain 15x endpoint incorrect: exp=%0d gain=%0d",exp,gain);
 for(i=0;i<80;i=i+1) frame(20);
 if(exp!=2244 || gain!=140) $fatal(1,"manual gain should hold while AE raises exposure: exp=%0d gain=%0d",exp,gain);
 $display("PASS auto exposure, 15x auto-gain limit, manual gain, and AE in manual-gain mode; requests=%0d",requests);$finish;
end
initial begin #1000000;$fatal(1,"timeout");end
endmodule

module frame_luma_stats_tb;
parameter WIDTH=8, HEIGHT=2;
reg clk=0,rst=0,v=0,u=0,ack=0;
reg [95:0] data=0;
wire toggle; wire [7:0] avg; wire [19:0] highlights;
always #4 clk=~clk;
frame_luma_stats #(.IMG_WIDTH(WIDTH),.IMG_HEIGHT(HEIGHT)) dut(clk,rst,data,v,u,ack,toggle,avg,highlights);
task frame;
 input [23:0] p;
 integer i;
 begin
  for(i=0;i<WIDTH*HEIGHT/4;i=i+1) begin
   @(negedge clk);v=1;u=(i==0);data={p,p,p,p};
   @(negedge clk);v=0;u=0;
  end
  repeat(35) @(negedge clk);
 end
endtask
initial begin
 repeat(3) @(negedge clk);rst=1;
 frame(24'h808080); if(avg!=128 || toggle!=1) $fatal(1,"mean gray");
 frame(24'hffffff); if(avg!=128 || toggle!=1 || highlights!=0) $fatal(1,"mailbox overwrote unacknowledged statistics");
 ack=toggle;repeat(4) @(negedge clk);
 frame(24'hffffff);if(avg!=255 || toggle!=0 || highlights!=WIDTH*HEIGHT) $fatal(1,"white frame statistics");
 ack=toggle;repeat(4) @(negedge clk);
 frame(24'hff0000);if(avg!=63 || highlights!=0) $fatal(1,"mean red");
 $display("PASS frame luma mean/divider/mailbox");$finish;
end
initial begin #100000000;$fatal(1,"timeout");end
endmodule
