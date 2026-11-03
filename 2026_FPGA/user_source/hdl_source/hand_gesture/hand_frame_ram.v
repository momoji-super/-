// Inferred simple-dual-port single-bit RAM. Each bank is written only in the
// camera clock domain and read only in the analysis clock domain.
module hand_frame_ram #(
    parameter SIZE=14400,
    parameter ADDR_WIDTH=16
)(
    input wire write_clk,
    input wire read_clk,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] write_addr,
    input wire [ADDR_WIDTH-1:0] read_addr,
    input wire write_skin,
    output reg read_skin
);
    localparam MEM_ADDR_WIDTH = $clog2(SIZE);
    (* ram_style="bram" *) reg memory [0:SIZE-1];
    always @(posedge write_clk)
        if(write_enable) memory[write_addr[MEM_ADDR_WIDTH-1:0]] <= write_skin;
    always @(posedge read_clk)
        read_skin <= memory[read_addr[MEM_ADDR_WIDTH-1:0]];
endmodule

