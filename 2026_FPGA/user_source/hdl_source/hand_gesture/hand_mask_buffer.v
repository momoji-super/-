// Two banks, one outstanding completed frame, bundled-data toggle handshake.
// A bank is immutable from publication until analysis acknowledges completion.
// Frames arriving while occupied are intentionally dropped in their entirety.
module hand_mask_buffer #(
    parameter WIDTH=160, HEIGHT=120, SIZE=WIDTH*HEIGHT
)(
    input wire cam_clk, cam_rst_n, input wire frame_start,
    input wire sample_valid, sample_skin, input wire [7:0] sample_x, sample_y,
    input wire analysis_clk, analysis_rst_n,
    input wire [15:0] read_addr, output wire read_skin,
    output reg analysis_start, output reg [3:0] capture_error,
    input wire analysis_done,
    output wire camera_waiting
);
    wire q0,q1;
    reg request_toggle, ack_toggle;
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED" *) reg [1:0] ack_sync;
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED" *) reg [1:0] request_sync;
    reg write_bank, published_bank, read_bank;
    reg active, occupied;
    reg [15:0] received;
    reg [3:0] published_error;
    reg request_seen;
    wire [15:0] write_addr=sample_y*WIDTH+sample_x;
    wire good_coord=(sample_x<WIDTH)&&(sample_y<HEIGHT);
    assign camera_waiting=occupied;
    wire begin_capture=frame_start&&!occupied&&!(active&&(received!=SIZE));
    wire first_pixel=begin_capture&&sample_valid&&good_coord&&(write_addr==0);
    wire target_bank=begin_capture?~write_bank:write_bank;
    wire write_ok=first_pixel||(active&&!frame_start&&sample_valid&&good_coord&&(write_addr==received));
    hand_frame_ram #(.SIZE(SIZE)) u_bank0(
		  .write_clk(cam_clk),
		  .read_clk(analysis_clk),
        .write_enable(write_ok&&!target_bank),
		  .write_addr(write_addr),
		  .read_addr(read_addr),
        .write_skin(sample_skin),
		  .read_skin(q0)
		  );
		  
    hand_frame_ram #(.SIZE(SIZE)) u_bank1(
		  .write_clk(cam_clk),
		  .read_clk(analysis_clk),
        .write_enable(write_ok&&target_bank),
		  .write_addr(write_addr),
		  .read_addr(read_addr),
        .write_skin(sample_skin),
		  .read_skin(q1)
		  );
		  
    assign read_skin=read_bank?q1:q0;

    // The first publication needs no RAM initialization: only fully written
    // frames may be analyzed. Partial frames publish an error instead.
    always @(posedge cam_clk or negedge cam_rst_n) begin
        if(!cam_rst_n) begin
            request_toggle<=0; ack_sync<=0; write_bank<=0;
            published_bank<=0; published_error<=0;
            active<=0; occupied<=0; received<=0;
        end else begin
            ack_sync<={ack_sync[0],ack_toggle};
            if(occupied && (ack_sync[1]==request_toggle)) occupied<=0;
            if(frame_start) begin
                if(active && received!=SIZE) begin
                    // Finish a partial frame only once. No new capture on this edge.
                    published_bank<=write_bank; published_error<=1;
                    request_toggle<=~request_toggle; occupied<=1; active<=0;
                end else if(!occupied) begin
                    active<=1; received<=first_pixel?16'd1:16'd0; write_bank<=~write_bank;
                end else active<=0;
            end else if(active && sample_valid && good_coord) begin
                // Require a dense, ordered downsampled raster. This detects
                // missing rows, duplicate pixels and an incorrect source mode.
                if(write_addr!=received) begin
                    published_bank<=write_bank; published_error<=1;
                    request_toggle<=~request_toggle; occupied<=1; active<=0;
                end else begin
                    received<=received+1'b1;
                    if(received==SIZE-1) begin
                        published_bank<=write_bank; published_error<=0;
                        request_toggle<=~request_toggle; occupied<=1; active<=0;
                    end
                end
            end
        end
    end
    always @(posedge analysis_clk or negedge analysis_rst_n) begin
        if(!analysis_rst_n) begin
            request_sync<=0; request_seen<=0; ack_toggle<=0;
            read_bank<=0; analysis_start<=0; capture_error<=0;
        end else begin
            request_sync<={request_sync[0],request_toggle};
            analysis_start<=0;
            if(request_sync[1]!=request_seen) begin
                request_seen<=request_sync[1];
                // Metadata has been stable for two receiving clocks.
                read_bank<=published_bank; capture_error<=published_error;
                analysis_start<=1;
            end
            if(analysis_done) ack_toggle<=request_seen;
        end
    end
endmodule
