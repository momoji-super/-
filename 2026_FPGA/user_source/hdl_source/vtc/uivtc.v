`timescale 1ns/1ps
// All outputs share two registers; LAST coincides with the final valid pixel.
module uivtc #(
 parameter H_ActiveSize=1280,H_FrameSize=1650,H_SyncStart=1390,H_SyncEnd=1430,
 parameter V_ActiveSize=720,V_FrameSize=750,V_SyncStart=725,V_SyncEnd=730
)(
 input I_vtc_rstn,I_vtc_clk,
 output O_vtc_vs,O_vtc_hs,O_vtc_de_valid,O_vtc_user,O_vtc_last
);
 reg [11:0] hcnt,vcnt;
 reg [1:0] reset_sync;
 reg [4:0] s0,s1;
 wire active=(hcnt<H_ActiveSize && vcnt<V_ActiveSize);
 always @(posedge I_vtc_clk or negedge I_vtc_rstn) begin
  if(!I_vtc_rstn) reset_sync<=0;
  else reset_sync<={reset_sync[0],1'b1};
 end
 always @(posedge I_vtc_clk or negedge I_vtc_rstn) begin
  if(!I_vtc_rstn) begin hcnt<=0;vcnt<=0;s0<=0;s1<=0;end
  else if(!reset_sync[1]) begin hcnt<=0;vcnt<=0;s0<=0;s1<=0;end
  else begin
   if(hcnt==H_FrameSize-1) begin
    hcnt<=0;vcnt<=(vcnt==V_FrameSize-1)?0:vcnt+1'b1;
   end else hcnt<=hcnt+1'b1;
   s0<={(vcnt>=V_SyncStart && vcnt<V_SyncEnd),
         (hcnt>=H_SyncStart && hcnt<H_SyncEnd),active,
         (hcnt==0 && vcnt==0), (active && hcnt==H_ActiveSize-1)};
   s1<=s0;
  end
 end
 assign {O_vtc_vs,O_vtc_hs,O_vtc_de_valid,O_vtc_user,O_vtc_last}=s1;
endmodule
