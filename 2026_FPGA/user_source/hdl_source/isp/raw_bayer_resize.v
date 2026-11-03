`ifndef RAW_BAYER_RESIZE_V
`define RAW_BAYER_RESIZE_V
// Preserve 2x2 Bayer cells while resampling the input pair grid.
// Ping-pong line RAM presents a continuous output-valid burst per line,
// required by the reference ISP's valid-falling-edge line detectors.
module raw_bayer_resize #(
 parameter IN_WIDTH=1920, IN_HEIGHT=1080,
 parameter OUT_WIDTH=1024, OUT_HEIGHT=600
)(
 input I_clk,I_rst_n,input [39:0] I_data,
 input I_valid,I_user,
 output reg [39:0] O_data,output reg O_valid,O_user,O_last
);
 localparam XP=IN_WIDTH/2,YP=IN_HEIGHT/2;
 localparam OXP=OUT_WIDTH/2,OYP=OUT_HEIGHT/2;
 localparam WORDS=OUT_WIDTH/4;
 localparam AW=(WORDS>1)?$clog2(WORDS):1;
 reg [39:0] memory [0:2*(1<<AW)-1];
 reg [15:0] x,y,xphase,yphase;
 reg keep_row,active,pending,first_line,write_bank;
 reg [19:0] pair;
 reg [AW-1:0] write_col;
 reg [1:0] ready,first_flags;
 reg read_bank,reading;
 reg [AW-1:0] read_col;
 integer lane,px,py,ph,yph;
 reg kr,pend,emit;
 reg [19:0] pair_work;
 reg [39:0] packed;
 // Only RAM port processes drive RAM / read data, no RAM reset.
 wire do_write=I_valid && (active || I_user) && emit;
 wire [AW:0] write_addr={write_bank,write_col};
 wire [AW:0] read_addr={read_bank,read_col};
 always @* begin
  px=I_user?0:x;py=I_user?0:y;
  ph=I_user?(XP-OXP):xphase;
  yph=I_user?(YP-OYP):yphase;
  kr=keep_row;pend=I_user?0:pending;pair_work=pair;
  emit=0;packed=0;
  if(px==0 && (py%2)==0) begin
   yph=yph+OYP;kr=(yph>=YP);if(kr)yph=yph-YP;
  end
  if(kr) for(lane=0;lane<2;lane=lane+1) begin
   ph=ph+OXP;
   if(ph>=XP) begin
    ph=ph-XP;
    if(!pend)begin pair_work=I_data[lane*20+:20];pend=1;end
    else begin packed={I_data[lane*20+:20],pair_work};pend=0;emit=1;end
   end
  end
 end
 always @(posedge I_clk) begin
  if(I_rst_n && do_write) memory[write_addr]<=packed;
  if(I_rst_n && reading) O_data<=memory[read_addr];
 end
 always @(posedge I_clk or negedge I_rst_n) begin
  if(!I_rst_n)begin
   x<=0;y<=0;xphase<=XP-OXP;yphase<=YP-OYP;keep_row<=0;
   active<=0;pending<=0;pair<=0;first_line<=1;write_bank<=0;write_col<=0;
   ready<=0;first_flags<=0;read_bank<=0;read_col<=0;reading<=0;
   O_valid<=0;O_user<=0;O_last<=0;
  end else begin
   O_valid<=reading;
   O_user<=reading && read_col==0 && first_flags[read_bank];
   O_last<=reading && read_col==WORDS-1;
   if(reading)begin
    if(read_col==WORDS-1)begin
     reading<=0;read_col<=0;ready[read_bank]<=0;read_bank<=~read_bank;
    end else read_col<=read_col+1'b1;
   end else if(ready[read_bank])begin reading<=1;read_col<=0;end
   if(I_user)begin
    x<=0;y<=0;xphase<=XP-OXP;yphase<=YP-OYP;
    pending<=0;first_line<=1;active<=1;
   end
   if(I_valid && (active || I_user))begin
    keep_row<=kr;yphase<=yph;pair<=pair_work;pending<=pend;
    if(px==IN_WIDTH-4)begin
     x<=0;y<=py+1;xphase<=XP-OXP;pending<=0;
     if(py==IN_HEIGHT-1)active<=0;
    end else begin x<=px+4;xphase<=ph;end
    if(emit)begin
     if(write_col==WORDS-1)begin
      ready[write_bank]<=1;first_flags[write_bank]<=first_line;
      first_line<=0;write_col<=0;write_bank<=~write_bank;
     end else write_col<=write_col+1'b1;
    end
   end
  end
 end
endmodule
`endif
