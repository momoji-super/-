`ifndef CAMERA_FIFO_GUARD_V
`define CAMERA_FIFO_GUARD_V
// Delay the packed stream, NOT the frame-reset announcement. At 112.5MHz
// 64 camera clocks cover the DDR-domain reset crossing/pulse/release window.
// A RAM ring avoids a large 128-bit shift register. Read/write addresses
// differ by 64, so there is no same-address collision dependency.
module camera_fifo_guard #(parameter DELAY=64)(
 input clk,rst_n,input valid,input[127:0]data,
 output reg out_valid,output reg[127:0]out_data
);
 localparam AW=$clog2(2*DELAY);
 reg[127:0]mem[0:2*DELAY-1];
 reg[AW-1:0]ptr;
 reg[DELAY-1:0]valid_pipe;
 wire[AW-1:0]read_ptr=ptr-DELAY;
 always @(posedge clk)begin
  mem[ptr]<=data;
  out_data<=mem[read_ptr];
 end
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin ptr<=0;valid_pipe<=0;out_valid<=0;end
  else begin
   ptr<=ptr+1'b1;
   valid_pipe<={valid_pipe[DELAY-2:0],valid};
   out_valid<=valid_pipe[DELAY-1];
  end
 end
endmodule
`endif
