// Gap-tolerant RGB888 (96-bit / four pixels) to 128-bit byte stream.
// Valid gaps do not discard the partial 12-byte accumulation.
module data_96bit_to_128bit (
    input wire I_clk,
    input wire I_rst_n,
    input wire I_96b_frame_start,
    input wire I_96b_valid,
    input wire I_96b_last,
    input wire [95:0] I_96b_data,
    output reg O_128b_frame_start,
    output reg O_128b_last,
    output reg O_128b_valid,
    output reg [127:0] O_128b_data
);
    reg [95:0] byte_buffer;
    reg [1:0] phase;
    reg sof_pending;
    wire [95:0] append_bytes = {I_96b_data[23:0], I_96b_data[47:24],
                               I_96b_data[71:48], I_96b_data[95:72]};
    wire [1:0] current_phase = I_96b_frame_start ? 2'd0 : phase;

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            byte_buffer <= 96'd0;
            phase <= 2'd0;
            sof_pending <= 1'b0;
            O_128b_frame_start <= 1'b0;
            O_128b_last <= 1'b0;
            O_128b_valid <= 1'b0;
            O_128b_data <= 128'd0;
        end else begin
            O_128b_valid <= 1'b0;
            O_128b_frame_start <= 1'b0;
            O_128b_last <= 1'b0;
            if (I_96b_frame_start) begin
                phase <= 2'd0;
                sof_pending <= 1'b1;
            end
            if (I_96b_valid) begin
                // Earliest RGB byte is at the most significant end of the
                // stream; input pixels themselves are lane 0 at [23:0].
                phase <= current_phase + 1'b1;
                byte_buffer <= append_bytes;
                case (current_phase)
                    2'd1: O_128b_data <= {byte_buffer, append_bytes[95:64]};
                    2'd2: O_128b_data <= {byte_buffer[63:0], append_bytes[95:32]};
                    2'd3: O_128b_data <= {byte_buffer[31:0], append_bytes};
                    default: ;
                endcase
                if (current_phase != 0) begin
                    O_128b_valid <= 1'b1;
                    O_128b_frame_start <= sof_pending;
                    // Every 1280-pixel line ends on phase 3.
                    O_128b_last <= I_96b_last;
                    sof_pending <= 1'b0;
                end
            end
        end
    end
endmodule
