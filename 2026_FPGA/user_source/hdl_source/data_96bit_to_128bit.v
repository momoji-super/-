// Four RGB888 pixels/beat, earliest pixel in [23:0]. Valid gaps are allowed.
// Each 16 pixels make three DDR words, earliest byte at [127:120].
module data_96bit_to_128bit (
 input I_clk,I_rst_n,I_96b_frame_start,I_96b_valid,
 input [95:0] I_96b_data,
 output reg O_128b_frame_start,O_128b_valid,
 output reg [127:0] O_128b_data
);
 reg [95:0] previous;
 reg [1:0] phase;
 reg sof_pending;
 wire [95:0] ordered={I_96b_data[23:0],I_96b_data[47:24],
                      I_96b_data[71:48],I_96b_data[95:72]};
 always @(posedge I_clk or negedge I_rst_n) begin
  if(!I_rst_n) begin
   phase<=0;previous<=0;sof_pending<=0;
   O_128b_frame_start<=0;O_128b_valid<=0;O_128b_data<=0;
  end else begin
   O_128b_frame_start<=0;O_128b_valid<=0;
   if(I_96b_frame_start)begin phase<=0;sof_pending<=1;end
   if(I_96b_valid) begin
    previous<=ordered;
    phase<=(I_96b_frame_start?2'd0:phase)+1'b1;
    case(I_96b_frame_start?2'd0:phase)
     0: ;
     1: begin
      O_128b_valid<=1;O_128b_data<={previous,ordered[95:64]};
      O_128b_frame_start<=sof_pending;sof_pending<=0;
     end
     2: begin O_128b_valid<=1;O_128b_data<={previous[63:0],ordered[95:32]};end
     3: begin O_128b_valid<=1;O_128b_data<={previous[31:0],ordered};end
    endcase
   end
  end
 end
endmodule
