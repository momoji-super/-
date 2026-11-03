`ifndef AUTO_EXPOSURE_V
`define AUTO_EXPOSURE_V
// Closed-loop sensor exposure, 24MHz domain. Input mailbox is bundled-data:
// producer holds luma stable until O_luma_ack_toggle is returned.
// Exposure is in half-line units. Current VTS=0x0467 -> max=2*1127-10=2244.
module auto_exposure #(
    parameter EXP_MIN=16, parameter EXP_MAX=2244,
    parameter EXP_INITIAL=1800, parameter GAIN_INITIAL=80,
    parameter GAIN_MIN=16, parameter GAIN_MAX=140,
    parameter TARGET_LOW=184, parameter TARGET_HIGH=204,
    parameter HIGHLIGHT_ENTER_THRESHOLD=6144,
    parameter HIGHLIGHT_EXIT_THRESHOLD=3072,
    // SC500 exposure takes effect after N+2 frames; wait through that pipeline
    // before using another frame statistic to issue a correction.
    parameter SETTLE_FRAMES=3
)(
    input I_clk, input I_rst,
    input I_luma_toggle, input [7:0] I_avg_luma,
    input [19:0] I_highlight_count,
    input [7:0] I_target_low, input [7:0] I_target_high,
    input I_manual_gain_enable, input [15:0] I_manual_gain,
    input I_cam_cfg_done, input I_ae_cfg_done,
    output reg O_luma_ack_toggle, output reg [7:0] O_luma_debug,
    output reg O_ae_req, output reg [15:0] O_ae, output reg [15:0] O_ag
);
    localparam BOOT=0, IDLE=1, WAIT_BUSY=2, WAIT_DONE=3;
    reg [1:0] state;
    reg [1:0] toggle_sync;
    reg [7:0] settle;
    reg [15:0] next_exp,next_gain,step,gain_step;
    reg [8:0] dark_error,bright_error;
    reg highlight_active;
    wire highlight_guard = highlight_active ||
                           (I_highlight_count >= HIGHLIGHT_ENTER_THRESHOLD);
    always @* begin
        next_exp=O_ae; next_gain=O_ag;
        step=(O_ae>>4);
        if(step<4) step=4;
        gain_step=2;
        dark_error=0;
        bright_error=0;
        if(I_avg_luma<I_target_low)
            dark_error=I_target_low-I_avg_luma;
        else if(I_avg_luma>I_target_high)
            bright_error=I_avg_luma-I_target_high;
        // Scale correction to distance from the active target, not fixed luma cutoffs.
        if((dark_error>=72)||(bright_error>=72)) begin
            step=(O_ae>>1); if(step<4) step=4;gain_step=16;
        end else if((dark_error>=32)||(bright_error>=32)) begin
            step=(O_ae>>2); if(step<4) step=4;gain_step=8;
        end
        // Saturated pixels alone must not darken an otherwise underexposed
        // room: the window can occupy a small part of the frame. Use the
        // highlight guard as an upper-exposure limiter only while the frame
        // mean is already above the indoor target.
        if(highlight_guard && (I_avg_luma > I_target_high)) begin
            step=(O_ae>>3); if(step<8) step=8;
            if(O_ae>EXP_MIN)
                next_exp=(O_ae<EXP_MIN+step)?EXP_MIN:O_ae-step;
            else if(!I_manual_gain_enable && O_ag>GAIN_MIN)
                next_gain=(O_ag<GAIN_MIN+gain_step)?GAIN_MIN:O_ag-gain_step;
        end else if(I_avg_luma<I_target_low) begin
            if(O_ae<EXP_MAX) next_exp=(O_ae+step>EXP_MAX)?EXP_MAX:O_ae+step;
            else if(!I_manual_gain_enable && O_ag<GAIN_MAX) next_gain=(O_ag+gain_step>GAIN_MAX)?GAIN_MAX:O_ag+gain_step;
        end else if(I_avg_luma>I_target_high) begin
            if(!I_manual_gain_enable && O_ag>GAIN_MIN) next_gain=(O_ag<GAIN_MIN+gain_step)?GAIN_MIN:O_ag-gain_step;
            else next_exp=(O_ae<EXP_MIN+step)?EXP_MIN:O_ae-step;
        end
        if(I_manual_gain_enable) begin
            if(I_manual_gain<GAIN_MIN) next_gain=GAIN_MIN;
            else if(I_manual_gain>GAIN_MAX) next_gain=GAIN_MAX;
            else next_gain=I_manual_gain;
        end
    end
    always @(posedge I_clk or posedge I_rst) begin
        if(I_rst) begin
            toggle_sync<=0;O_luma_ack_toggle<=0;O_luma_debug<=0;
            O_ae_req<=0;O_ae<=EXP_INITIAL;O_ag<=GAIN_INITIAL;
            highlight_active<=0;state<=BOOT;settle<=0;
        end else begin
            toggle_sync<={toggle_sync[0],I_luma_toggle};
            O_ae_req<=0;
            if(toggle_sync[1]!=O_luma_ack_toggle) begin
                O_luma_ack_toggle<=toggle_sync[1];
                O_luma_debug<=I_avg_luma;
                if (I_highlight_count >= HIGHLIGHT_ENTER_THRESHOLD)
                    highlight_active<=1'b1;
                else if (I_highlight_count <= HIGHLIGHT_EXIT_THRESHOLD)
                    highlight_active<=1'b0;
                if(state==IDLE) begin
                    if(settle!=0) settle<=settle-1'b1;
                    else if((next_exp!=O_ae)||(next_gain!=O_ag)) begin
                        O_ae<=next_exp;O_ag<=next_gain;
                        O_ae_req<=1;state<=WAIT_BUSY;
                    end
                end
            end
            case(state)
                BOOT: if(I_cam_cfg_done && I_ae_cfg_done) begin
                    // Force legal initial settings even if no buttons are pressed.
                    O_ae_req<=1;state<=WAIT_BUSY;
                end
                WAIT_BUSY: if(!I_ae_cfg_done) state<=WAIT_DONE;
                WAIT_DONE: if(I_ae_cfg_done) begin state<=IDLE;settle<=SETTLE_FRAMES;end
                default: begin end
            endcase
        end
    end
endmodule
`endif
