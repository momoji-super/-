// Acquire with a majority, but change a locked gesture only on strong,
// repeated evidence. Invalid frames age the window without voting as zero.
// Brief no-hand dropouts retain the display; sustained absence clears it.
module hand_temporal_vote #(
    parameter WINDOW=8, THRESHOLD=5, INVALID_LIMIT=6,
    parameter MOVE_LIMIT=20, SWITCH_THRESHOLD=7, SWITCH_CONFIRM=2,
    parameter NO_HAND_LIMIT=3
)(
    input wire clk, rst_n, done, result_valid, present,
    input wire [3:0] raw_count, input wire [7:0] palm_x,palm_y,
    output reg [3:0] count, output reg display_valid,
    output reg [3:0] support
);
    reg [3:0] history [0:WINDOW-1];
    reg [7:0] hist [0:5];
    integer pointer, fill, invalid_frames;
    integer i;
    reg scanning;
    reg [2:0] scan_index,scan_best;
    reg [7:0] scan_votes;
    reg [7:0] old_x,old_y;
    reg tracked;
    reg locked;
    reg [3:0] challenger,last_count;
    reg [3:0] confirmations;
    integer no_hand_frames;
    wire [8:0] dx=(palm_x>old_x)?(palm_x-old_x):(old_x-palm_x);
    wire [8:0] dy=(palm_y>old_y)?(palm_y-old_y):(old_y-palm_y);
    wire moved=tracked&&((dx>MOVE_LIMIT)||(dy>MOVE_LIMIT));
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count<=0;display_valid<=0;support<=0;
            pointer<=0;fill<=0;invalid_frames<=0;old_x<=0;old_y<=0;tracked<=0;
            locked<=0;challenger<=0;last_count<=0;confirmations<=0;no_hand_frames<=0;
            scanning<=0;scan_index<=0;scan_best<=0;scan_votes<=0;
            for(i=0;i<6;i=i+1) hist[i]<=0;
            for(i=0;i<WINDOW;i=i+1) history[i]<=0;
        end else if(done) begin
            scanning<=0;
            if(result_valid&&!present) begin
                invalid_frames<=0;confirmations<=0;
                if(no_hand_frames<NO_HAND_LIMIT) no_hand_frames<=no_hand_frames+1;
                if(no_hand_frames>=NO_HAND_LIMIT-1) begin
                    count<=0;display_valid<=1;support<=0;locked<=0;
                    pointer<=0;fill<=0;tracked<=0;
                    for(i=0;i<6;i=i+1) hist[i]<=0;
                end
            end else if(result_valid&&raw_count<=5) begin
                no_hand_frames<=0;last_count<=raw_count;
                old_x<=palm_x;old_y<=palm_y;tracked<=1;invalid_frames<=0;
                for(i=0;i<6;i=i+1)
                    hist[i]<=(moved?0:hist[i])+((raw_count==i)?8'd1:8'd0)
                            -((!moved&&fill==WINDOW&&history[pointer]==i)?8'd1:8'd0);
                if(moved) begin
                    history[0]<=raw_count;pointer<=(WINDOW==1)?0:1;fill<=1;display_valid<=0;
                    locked<=0;confirmations<=0;support<=0;
                end else begin
                    history[pointer]<=raw_count;pointer<=(pointer==WINDOW-1)?0:pointer+1;
                    if(fill<WINDOW) fill<=fill+1;
                end
                scanning<=1;scan_index<=0;scan_best<=0;scan_votes<=0;
            end else begin
                no_hand_frames<=0;confirmations<=0;
                // An invalid observation occupies a slot, but casts no vote.
                for(i=0;i<6;i=i+1)
                    hist[i]<=hist[i]-((fill==WINDOW&&history[pointer]==i)?8'd1:8'd0);
                history[pointer]<=4'hf;
                pointer<=(pointer==WINDOW-1)?0:pointer+1;
                if(fill<WINDOW) fill<=fill+1;
                if(invalid_frames<INVALID_LIMIT) invalid_frames<=invalid_frames+1;
                if(invalid_frames>=INVALID_LIMIT-1) begin
                    display_valid<=0;pointer<=0;fill<=0;support<=0;tracked<=0;scanning<=0;
                    locked<=0;
                    for(i=0;i<6;i=i+1) hist[i]<=0;
                end
            end
        end else if(scanning) begin
            if(scan_index<6) begin
                if(hist[scan_index]>scan_votes) begin scan_votes<=hist[scan_index];scan_best<=scan_index;end
                scan_index<=scan_index+1'b1;
            end else begin
                support<=scan_votes[3:0];scanning<=0;
                if(!locked) begin
                    confirmations<=0;
                    if(scan_votes>=THRESHOLD && last_count==scan_best) begin
                        count<={1'b0,scan_best};display_valid<=1;locked<=1;
                    end
                end else if(scan_best==count) begin
                    confirmations<=0;
                end else if(scan_votes>=SWITCH_THRESHOLD && last_count==scan_best) begin
                    if(SWITCH_CONFIRM<=1 ||
                       (challenger==scan_best && confirmations>=SWITCH_CONFIRM-1)) begin
                        count<={1'b0,scan_best};display_valid<=1;confirmations<=0;
                    end else begin
                        challenger<={1'b0,scan_best};
                        confirmations<=(challenger==scan_best)?confirmations+1'b1:4'd1;
                    end
                end else confirmations<=0;
            end
        end
    end
endmodule
