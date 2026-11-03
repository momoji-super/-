`ifndef RGB_AREA_2_3_V
`define RGB_AREA_2_3_V
// Exact pixel-area integration for 3:2 reduction, independently in X and Y.
// Input/output: four RGB888 pixels, earliest pixel in bits [23:0].
// For each triplet a,b,c: (2*a+b)/3, (b+2*c)/3, rounded to nearest.
// Keeps the entire image, has unity DC gain and never clips/rings at edges.
// Width must be divisible by 12, height by 3. No backpressure is supported.
module rgb_area_2_3 #(
 parameter IN_WIDTH=1920, IN_HEIGHT=1080
)(
 input clk,rst_n,
 input [95:0] I_data,input I_valid,I_user,I_last,
 output reg [95:0] O_data,output reg O_valid,O_user,O_last
);
 localparam WORDS=IN_WIDTH/6;
 localparam AW=(WORDS>1)?$clog2(WORDS):1;
 reg [1:0] phase,fill,row_phase;
 reg [23:0] previous;
 reg [95:0] packing;
 reg [AW-1:0] column;
 reg [11:0] row;
 reg active;
 reg [95:0] h_data;
 reg h_valid,h_user,h_last;
 reg [1:0] h_phase;
 reg [AW-1:0] h_column;
 reg [95:0] line_ram[0:WORDS-1];
 reg [95:0] old_line,current_line;
 reg v_valid,v_user,v_last;
 reg [1:0] v_phase;
 integer lane;
 reg [1:0] phase_w,fill_w;
 reg [23:0] prev_w,pixel_w,scaled_w;
 reg [95:0] pack_w;

 function [7:0] weighted;
  input [7:0] a,b;
  reg [9:0] n;
  begin
   n={a,1'b0}+{2'b0,b}+10'd1;
   // n is at most 766. Constant division preserves the rounded area sum.
   weighted=n/10'd3;
  end
 endfunction
 function [23:0] blend;
  input [23:0] a,b;
  begin blend={weighted(a[23:16],b[23:16]),
               weighted(a[15:8],b[15:8]),weighted(a[7:0],b[7:0])};end
 endfunction

 // Four input lanes produce at most one complete four-pixel output beat.
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   phase<=0;fill<=0;previous<=0;packing<=0;column<=0;row<=0;
   row_phase<=0;active<=0;h_valid<=0;h_user<=0;h_last<=0;
   h_data<=0;h_phase<=0;h_column<=0;
  end else begin
   h_valid<=0;h_user<=0;h_last<=0;
   if(I_user) begin
    phase<=0;fill<=0;column<=0;row<=0;row_phase<=0;active<=1;
   end
   if(I_valid && (active || I_user)) begin
    phase_w=I_user?0:phase;fill_w=I_user?0:fill;
    prev_w=previous;pack_w=packing;
    for(lane=0;lane<4;lane=lane+1) begin
     pixel_w=I_data[lane*24+:24];
     if(phase_w!=0) begin
      scaled_w=(phase_w==1)?blend(prev_w,pixel_w):blend(pixel_w,prev_w);
      pack_w[fill_w*24+:24]=scaled_w;
      if(fill_w==3) begin
       h_data<=pack_w;h_valid<=1;
       h_column<=I_user?0:column;h_phase<=I_user?0:row_phase;
       h_user<=(row==1 && column==0 && !I_user);
       h_last<=(column==WORDS-1);
       if(column==WORDS-1) begin
        column<=0;row<=row+1'b1;
        row_phase<=(row_phase==2)?0:row_phase+1'b1;
        if(row==IN_HEIGHT-1)active<=0;
       end else column<=(I_user?0:column)+1'b1;
       fill_w=0;
      end else fill_w=fill_w+1'b1;
     end
     prev_w=pixel_w;
     phase_w=(phase_w==2)?0:phase_w+1'b1;
    end
    phase<=phase_w;fill<=fill_w;previous<=prev_w;packing<=pack_w;
   end
  end
 end

 // Read-first simple dual-port RAM. Row 1 replaces row 0 after reading it;
 // row 2 reads row 1. No RAM reset or uninitialised line is exposed.
 always @(posedge clk) begin
  if(h_valid) begin
   old_line<=line_ram[h_column];
   if(h_phase!=2)line_ram[h_column]<=h_data;
  end
 end
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   current_line<=0;v_valid<=0;v_user<=0;v_last<=0;v_phase<=0;
   O_data<=0;O_valid<=0;O_user<=0;O_last<=0;
  end else begin
   current_line<=h_data;v_phase<=h_phase;
   v_valid<=h_valid && h_phase!=0;
   v_user<=h_valid && h_user;v_last<=h_valid && h_last;
   O_valid<=v_valid;O_user<=v_valid && v_user;O_last<=v_valid && v_last;
   if(v_valid) begin
    O_data[23:0]<=v_phase==1?blend(old_line[23:0],current_line[23:0]):blend(current_line[23:0],old_line[23:0]);
    O_data[47:24]<=v_phase==1?blend(old_line[47:24],current_line[47:24]):blend(current_line[47:24],old_line[47:24]);
    O_data[71:48]<=v_phase==1?blend(old_line[71:48],current_line[71:48]):blend(current_line[71:48],old_line[71:48]);
    O_data[95:72]<=v_phase==1?blend(old_line[95:72],current_line[95:72]):blend(current_line[95:72],old_line[95:72]);
   end
  end
 end
endmodule
`endif
