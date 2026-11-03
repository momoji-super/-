// RGB (before effects) frame mean. Shift/add luminance uses no DSP.
// A 28-cycle restoring divider avoids a large combinational divide.
// Mailbox holds average until the 24MHz consumer acknowledges its toggle.
module frame_luma_stats #(
    parameter IMG_WIDTH=1024, parameter IMG_HEIGHT=600
)(
    input I_clk, input I_rst_n,
    input [95:0] I_tdata, input I_tvalid, input I_tuser,
    input I_ack_toggle,
    output reg O_frame_toggle, output reg [7:0] O_avg_luma,
    output reg [19:0] O_highlight_count
);
    localparam TOTAL_BEATS=IMG_WIDTH*IMG_HEIGHT/4;
    reg [19:0] beats;
    reg [27:0] sum;
    reg [19:0] highlight_count, frame_highlight_count;
    reg active;
    reg [1:0] ack_sync;
    reg busy;
    reg [5:0] left;
    reg [27:0] dividend, quotient;
    reg [20:0] remainder;
    reg [20:0] trial;
    wire [9:0] beat_luma={2'd0,luma(I_tdata[23:0])}+{2'd0,luma(I_tdata[47:24])}
                          +{2'd0,luma(I_tdata[71:48])}+{2'd0,luma(I_tdata[95:72])};
    wire [2:0] beat_highlights = {2'd0,(luma(I_tdata[23:0]) >= 8'd240)}
                               + {2'd0,(luma(I_tdata[47:24]) >= 8'd240)}
                               + {2'd0,(luma(I_tdata[71:48]) >= 8'd240)}
                               + {2'd0,(luma(I_tdata[95:72]) >= 8'd240)};
    function [7:0] luma;
        input [23:0] p;
        reg [9:0] s;
        begin s={2'd0,p[23:16]}+{1'd0,p[15:8],1'b0}+{2'd0,p[7:0]}; luma=s[9:2]; end
    endfunction
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            beats<=0;sum<=0;highlight_count<=0;frame_highlight_count<=0;
            active<=0;ack_sync<=0;busy<=0;left<=0;
            dividend<=0;quotient<=0;remainder<=0;
            O_frame_toggle<=0;O_avg_luma<=0;O_highlight_count<=0;
        end else begin
            ack_sync<={ack_sync[0],I_ack_toggle};
            if(I_tuser) begin
                active<=1; beats<=0; sum<=0;highlight_count<=0;
            end
            if(I_tvalid && (active || I_tuser)) begin
                highlight_count <= (I_tuser ? 20'd0 : highlight_count) + beat_highlights;
                if((I_tuser ? 20'd0 : beats)==TOTAL_BEATS-1) begin
                    active<=0;
                    if(!busy && ack_sync[1]==O_frame_toggle) begin
                        frame_highlight_count <= (I_tuser ? 20'd0 : highlight_count) + beat_highlights;
                        dividend<=(I_tuser ? 28'd0 : sum)+beat_luma;
                        remainder<=0;quotient<=0;left<=28;busy<=1;
                    end
                end else begin
                    beats<=(I_tuser ? 20'd0 : beats)+1'b1;
                    sum<=(I_tuser ? 28'd0 : sum)+beat_luma;
                end
            end
            if(busy) begin
                trial={remainder[19:0],dividend[27]};
                dividend<={dividend[26:0],1'b0};
                if(trial>=IMG_WIDTH*IMG_HEIGHT) begin
                    remainder<=trial-IMG_WIDTH*IMG_HEIGHT;
                    quotient<={quotient[26:0],1'b1};
                end else begin
                    remainder<=trial;
                    quotient<={quotient[26:0],1'b0};
                end
                left<=left-1'b1;
                if(left==1) begin
                    O_avg_luma<={quotient[6:0],(trial>=IMG_WIDTH*IMG_HEIGHT)};
                    O_highlight_count<=frame_highlight_count;
                    O_frame_toggle<=~O_frame_toggle;busy<=0;
                end
            end
        end
    end
endmodule
