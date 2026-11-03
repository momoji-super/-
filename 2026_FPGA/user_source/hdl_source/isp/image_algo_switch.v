// Four pixels/clock. Modes 0..4 retained; 5=Sobel, 6=cartoon, 7=histogram equalization.
// Fixed four-register latency for data AND sidebands in every mode.
// Causal 3x3 window ends at (x,y); gradient centre is (x-1,y-1).
// First two rows/columns are masked; no stale RAM is exposed after reset/SOF.
module image_algo_switch #(
    parameter IMG_WIDTH = 1024,
    parameter IMG_HEIGHT = 600,
    parameter EDGE_THRESHOLD = 8'd48
)(
    input I_clk, input I_rst_n,
    input [95:0] I_tdata,
    input I_tvalid, input I_tuser, input I_tlast,
    output I_tready,
    output reg [95:0] O_tdata,
    output reg O_tvalid, output reg O_tuser, output reg O_tlast,
    input [2:0] I_algo_mode, input [7:0] I_threshold,
    input I_vivid_enable
);
    localparam BEATS = IMG_WIDTH/4;
    localparam AW = (BEATS > 1) ? $clog2(BEATS) : 1;
    reg [95:0] color_line [0:BEATS-1];
    reg [95:0] prev_color_d;
    reg [23:0] color_hist;
    reg [31:0] line1 [0:BEATS-1];
    reg [31:0] line2 [0:BEATS-1];
    reg [AW-1:0] addr, addr_d;
    reg [15:0] row;
    reg [2:0] mode_frame;
    reg [7:0] threshold_frame;
    reg vivid_frame;
    wire [2:0] active_mode = I_tuser ? I_algo_mode : mode_frame;
    wire [7:0] requested_threshold = (I_algo_mode == 5) ? I_threshold : 8'd128;
    wire [7:0] active_threshold = I_tuser ? requested_threshold : threshold_frame;
    wire [AW-1:0] read_addr = I_tuser ? {AW{1'b0}} : addr;
    reg [31:0] gray_d, prev1_d, prev2_d;
    reg [95:0] rgb_d, rgb_q;
    reg [31:0] gray_q;
    reg valid_d, user_d, last_d, valid_q, user_q, last_q;
    reg [2:0] mode_d, mode_q;
    reg [7:0] threshold_d, threshold_q;
    reg top_border_d;
    reg [15:0] hist0, hist1, hist2;
    wire [47:0] win0 = {gray_d,  (addr_d == 0 ? 16'd0 : hist0)};
    wire [47:0] win1 = {prev1_d, (addr_d == 0 ? 16'd0 : hist1)};
    wire [47:0] win2 = {prev2_d, (addr_d == 0 ? 16'd0 : hist2)};
    reg [23:0] gradients [0:3];
    reg [10:0] magnitude [0:3];
    wire [31:0] equalized_luma;
    wire [7:0] input_sample_luma = gray(I_tdata[95:72]);
    wire hist_sample_valid = I_tvalid && (read_addr[1:0] == 2'b00) &&
                             (row[3:0] == 4'b0000);
    reg [95:0] rgb_r;
    reg [31:0] luma_r;
    reg valid_r,user_r,last_r;
    reg [2:0] mode_r;
    reg [7:0] threshold_r;
    integer i;
    assign I_tready = 1'b1;
    histogram_equalizer #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) u_histogram_equalizer (
        .I_clk(I_clk),
        .I_rst_n(I_rst_n),
        .I_tuser(I_tuser),
        .I_sample_valid(hist_sample_valid),
        .I_sample_luma(input_sample_luma),
        // luma_r is pipelined alongside rgb_r; reuse it instead of placing
        // three channel multipliers and an adder on the lookup-to-render path.
        .I_map_luma(luma_r),
        .O_equalized_luma(equalized_luma)
    );
    function [7:0] gray;
        input [23:0] p;
        reg [15:0] sum;
        begin
            sum = p[23:16]*16'd77 + p[15:8]*16'd150 + p[7:0]*16'd29;
            gray = sum[15:8];
        end
    endfunction
    function [7:0] clamp_channel;
        input signed [10:0] value;
        begin
            if (value < 0) clamp_channel = 8'd0;
            else if (value > 11'sd255) clamp_channel = 8'd255;
            else clamp_channel = value[7:0];
        end
    endfunction
    function [23:0] vivid_rgb;
        input [23:0] p;
        input [7:0] y;
        reg signed [9:0] dr, dg, db;
        reg signed [10:0] r_boost, g_boost, b_boost;
        begin
            dr = $signed({1'b0, p[23:16]}) - $signed({1'b0, y});
            dg = $signed({1'b0, p[15:8]}) - $signed({1'b0, y});
            db = $signed({1'b0, p[7:0]}) - $signed({1'b0, y});
            r_boost = $signed({3'b0, y}) + dr + (dr >>> 3);
            g_boost = $signed({3'b0, y}) + dg + (dg >>> 3);
            b_boost = $signed({3'b0, y}) + db + (db >>> 3);
            vivid_rgb = {clamp_channel(r_boost),
                         clamp_channel(g_boost),
                         clamp_channel(b_boost)};
        end
    endfunction
    function [23:0] sobel;
        input [23:0] a,b,c;
        reg signed [11:0] gx,gy;
        reg [11:0] ax,ay;
        begin
            gx = $signed({4'd0,a[23:16]}) - $signed({4'd0,a[7:0]})
               + ($signed({4'd0,b[23:16]}) <<< 1) - ($signed({4'd0,b[7:0]}) <<< 1)
               + $signed({4'd0,c[23:16]}) - $signed({4'd0,c[7:0]});
            gy = $signed({4'd0,a[7:0]}) + ($signed({4'd0,a[15:8]}) <<< 1)
               + $signed({4'd0,a[23:16]}) - $signed({4'd0,c[7:0]})
               - ($signed({4'd0,c[15:8]}) <<< 1) - $signed({4'd0,c[23:16]});
            sobel = {gx,gy};
        end
    endfunction
    function [10:0] gradient_magnitude;
        input [23:0] g;
        reg [11:0] ax,ay;
        begin
            ax = g[23] ? -g[23:12] : g[23:12];
            ay = g[11] ? -g[11:0] : g[11:0];
            gradient_magnitude = ax + ay;
        end
    endfunction
    function [23:0] render;
        input [23:0] p;
        input [7:0] y;
        input [2:0] mode;
        input [7:0] threshold;
        input [10:0] mag;
        input [7:0] equalized;
        begin
            case(mode)
                1: render = {y,y,y};
                2: render = y >= threshold ? 24'hffffff : 24'd0;
                3: render = ~p;
                4: render = (({1'b0,p[23:16]} > {1'b0,p[15:8]}+9'd32) &&
                             ({1'b0,p[23:16]} > {1'b0,p[7:0]}+9'd32)) ? p : {y,y,y};
                5: render = mag >= {3'd0,threshold} ? 24'hffffff : 24'd0;
                6: render = mag >= {3'd0,threshold} ? 24'd0 :
                    {p[23:21],5'b10000,p[15:13],5'b10000,p[7:5],5'b10000};
                7: render = {equalized,equalized,equalized};
                0: render = vivid_frame ? vivid_rgb(p, y) : p;
                default: render = p;
            endcase
        end
    endfunction
    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            addr <= 0; addr_d <= 0; row <= 0;
            mode_frame <= 0; threshold_frame <= EDGE_THRESHOLD;
            vivid_frame <= 1'b1;
            gray_d <= 0;
            rgb_d <= 0; rgb_q <= 0; gray_q <= 0;
            valid_d <= 0; user_d <= 0; last_d <= 0;
            valid_q <= 0; user_q <= 0; last_q <= 0;
            mode_d <= 0; mode_q <= 0; threshold_d <= EDGE_THRESHOLD; threshold_q <= EDGE_THRESHOLD;
            top_border_d <= 1;
            hist0 <= 0; hist1 <= 0; hist2 <= 0; color_hist <= 0;
            O_tdata <= 0; O_tvalid <= 0; O_tuser <= 0; O_tlast <= 0;
            rgb_r <= 0; luma_r <= 0;
            valid_r <= 0; user_r <= 0; last_r <= 0; mode_r <= 0; threshold_r <= EDGE_THRESHOLD;
            for (i=0;i<4;i=i+1) begin magnitude[i] <= 0; gradients[i] <= 0; end
        end else begin
            if (I_tuser) begin
                mode_frame <= I_algo_mode;
                threshold_frame <= requested_threshold;
                vivid_frame <= I_vivid_enable;
                addr <= 0; row <= 0;
            end
            valid_d <= I_tvalid; user_d <= I_tuser; last_d <= I_tlast;
            rgb_d <= I_tdata; mode_d <= active_mode; threshold_d <= active_threshold;
            if (I_tvalid) begin
                gray_d <= {gray(I_tdata[95:72]),gray(I_tdata[71:48]),gray(I_tdata[47:24]),gray(I_tdata[23:0])};
                addr_d <= read_addr;
                top_border_d <= I_tuser || (row < 2);
                if (read_addr == BEATS-1) begin
                    addr <= 0;
                    row <= I_tuser ? 16'd1 : row + 16'd1;
                end else addr <= read_addr + 1'b1;
            end
            valid_q <= valid_d; user_q <= user_d; last_q <= last_d;
            rgb_q <= rgb_d;
            gray_q <= gray_d;
            if ((mode_d == 6) && !top_border_d) begin
                rgb_q[95:48] <= prev_color_d[71:24];
                if (addr_d != 0) rgb_q[47:0] <= {prev_color_d[23:0],color_hist};
            end
            mode_q <= mode_d; threshold_q <= threshold_d;
            if (valid_d) begin
                color_hist <= prev_color_d[95:72];
                hist0 <= gray_d[31:16]; hist1 <= prev1_d[31:16]; hist2 <= prev2_d[31:16];
                for (i=0;i<4;i=i+1)
                    if (top_border_d || ((addr_d == 0) && (i < 2))) gradients[i] <= 0;
                    else gradients[i] <= sobel(win2[i*8 +: 24],win1[i*8 +: 24],win0[i*8 +: 24]);
            end
            valid_r <= valid_q; user_r <= user_q; last_r <= last_q;
            rgb_r <= rgb_q; mode_r <= mode_q; threshold_r <= threshold_q;
            if (valid_q) for(i=0;i<4;i=i+1) magnitude[i] <= gradient_magnitude(gradients[i]);
            if (valid_q)
                luma_r <= gray_q;
            O_tvalid <= valid_r; O_tuser <= user_r; O_tlast <= last_r;
            if (valid_r)
                for (i=0;i<4;i=i+1)
                    O_tdata[i*24 +: 24] <= render(
                        rgb_r[i*24 +: 24], luma_r[i*8 +: 8], mode_r,
                        threshold_r, magnitude[i], equalized_luma[i*8 +: 8]);
        end
    end
    // RAM ports have no reset so TD can infer block memories.
    always @(posedge I_clk) begin
        if (I_rst_n && I_tvalid) begin
            prev_color_d <= color_line[read_addr];
            color_line[read_addr] <= I_tdata;
            prev1_d <= line1[read_addr];
            prev2_d <= line2[read_addr];
            line1[read_addr] <= {gray(I_tdata[95:72]),gray(I_tdata[71:48]),gray(I_tdata[47:24]),gray(I_tdata[23:0])};
        end
        if (I_rst_n && valid_d) line2[addr_d] <= prev1_d;
    end
endmodule

module histogram_equalizer #(
    parameter IMG_WIDTH = 1024,
    parameter IMG_HEIGHT = 600
) (
    input wire I_clk,
    input wire I_rst_n,
    input wire I_tuser,
    input wire I_sample_valid,
    input wire [7:0] I_sample_luma,
    input wire [31:0] I_map_luma,
    output wire [31:0] O_equalized_luma
);
    localparam TOTAL_SAMPLES = ((IMG_WIDTH + 15) / 16) *
                               ((IMG_HEIGHT + 15) / 16);
    localparam [13:0] SAMPLE_TOTAL = TOTAL_SAMPLES;
    reg [11:0] hist0 [0:63];
    reg [11:0] hist1 [0:63];
    reg hist0_epoch [0:63];
    reg hist1_epoch [0:63];
    reg epoch0, epoch1;
    reg write_bank;
    reg frame_seen;
    reg [7:0] lut0 [0:63];
    reg [7:0] lut1 [0:63];
    reg lut_active;
    reg lut_frame;
    reg lut_ready;
    reg lut_frame_valid;
    reg scan_active;
    reg scan_bank;
    reg scan_lut_bank;
    reg [5:0] scan_addr;
    reg [12:0] scan_cdf;
    reg [12:0] cdf_min;
    reg cdf_min_found;
    reg div_busy;
    reg [5:0] div_bin;
    reg [4:0] div_bits_left;
    reg [19:0] div_dividend;
    reg [19:0] div_quotient;
    reg [12:0] div_remainder;
    reg [13:0] div_denominator;
    reg [1:0] scan_pipeline_stage;
    reg [5:0] map_bin;
    reg [12:0] map_cdf;
    reg [13:0] map_denominator;
    reg [19:0] map_dividend;
    reg sample_valid_d;
    reg [5:0] sample_bin_d;
    reg sample_bank_d;
    reg sample_epoch_d;
    wire sample_bank = (I_tuser && frame_seen) ? ~write_bank : write_bank;
    wire sample_epoch = sample_bank ?
        ((I_tuser && frame_seen) ? ~epoch1 : epoch1) :
        ((I_tuser && frame_seen) ? ~epoch0 : epoch0);
    wire [5:0] scan_bin = scan_addr;
    wire [11:0] scan_count = scan_bank ?
        ((hist1_epoch[scan_bin] == epoch1) ? hist1[scan_bin] : 12'd0) :
        ((hist0_epoch[scan_bin] == epoch0) ? hist0[scan_bin] : 12'd0);
    wire [12:0] scan_cdf_next = scan_cdf + {1'b0, scan_count};
    wire [12:0] scan_cdf_min = cdf_min_found ? cdf_min :
                               (scan_count != 0 ? scan_cdf_next : 13'd0);
    wire [13:0] scan_denominator = SAMPLE_TOTAL - scan_cdf_min;
    wire [12:0] scan_cdf_equalized = scan_cdf_next - scan_cdf_min;
    wire [19:0] scaled_cdf = {scan_cdf_equalized, 8'd0} - scan_cdf_equalized;
    wire [13:0] div_shift_rem = {1'b0, div_remainder, div_dividend[19]};
    wire div_subtract = div_shift_rem >= {1'b0, div_denominator};
    wire [12:0] div_remainder_next = div_subtract ?
        (div_shift_rem - {1'b0, div_denominator}) : div_shift_rem[12:0];
    wire [7:0] div_quotient_next = {div_quotient[6:0], div_subtract};
    wire [7:0] div_result = (div_denominator == 0) ?
                            {div_bin, 2'b00} : div_quotient_next;
    wire [7:0] lut_map0 = lut_frame ? lut1[I_map_luma[7:2]] :
                                      lut0[I_map_luma[7:2]];
    wire [7:0] lut_map1 = lut_frame ? lut1[I_map_luma[15:10]] :
                                      lut0[I_map_luma[15:10]];
    wire [7:0] lut_map2 = lut_frame ? lut1[I_map_luma[23:18]] :
                                      lut0[I_map_luma[23:18]];
    wire [7:0] lut_map3 = lut_frame ? lut1[I_map_luma[31:26]] :
                                      lut0[I_map_luma[31:26]];
    wire [7:0] mapped0 = lut_frame_valid ? lut_map0 : I_map_luma[7:0];
    wire [7:0] mapped1 = lut_frame_valid ? lut_map1 : I_map_luma[15:8];
    wire [7:0] mapped2 = lut_frame_valid ? lut_map2 : I_map_luma[23:16];
    wire [7:0] mapped3 = lut_frame_valid ? lut_map3 : I_map_luma[31:24];
    integer h;
    integer l;
    assign O_equalized_luma = {mapped3, mapped2, mapped1, mapped0};

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            epoch0 <= 1'b0;
            epoch1 <= 1'b0;
            write_bank <= 1'b0;
            frame_seen <= 1'b0;
            sample_valid_d <= 1'b0;
            sample_bin_d <= 6'd0;
            sample_bank_d <= 1'b0;
            sample_epoch_d <= 1'b0;
            for (h = 0; h < 64; h = h + 1) begin
                hist0[h] <= 12'd0;
                hist1[h] <= 12'd0;
                hist0_epoch[h] <= 1'b0;
                hist1_epoch[h] <= 1'b0;
            end
        end else begin
            sample_valid_d <= I_sample_valid;
            sample_bin_d <= I_sample_luma[7:2];
            sample_bank_d <= sample_bank;
            sample_epoch_d <= sample_epoch;
            if (I_tuser) begin
                if (frame_seen) begin
                    write_bank <= ~write_bank;
                    if (write_bank) epoch0 <= ~epoch0;
                    else epoch1 <= ~epoch1;
                end
                frame_seen <= 1'b1;
            end
            if (sample_valid_d) begin
                if (!sample_bank_d) begin
                    if (hist0_epoch[sample_bin_d] != sample_epoch_d) begin
                        hist0_epoch[sample_bin_d] <= sample_epoch_d;
                        hist0[sample_bin_d] <= 12'd1;
                    end else if (hist0[sample_bin_d] != 12'hfff)
                        hist0[sample_bin_d] <= hist0[sample_bin_d] + 12'd1;
                end else begin
                    if (hist1_epoch[sample_bin_d] != sample_epoch_d) begin
                        hist1_epoch[sample_bin_d] <= sample_epoch_d;
                        hist1[sample_bin_d] <= 12'd1;
                    end else if (hist1[sample_bin_d] != 12'hfff)
                        hist1[sample_bin_d] <= hist1[sample_bin_d] + 12'd1;
                end
            end
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            lut_active <= 1'b0;
            lut_frame <= 1'b0;
            lut_ready <= 1'b0;
            lut_frame_valid <= 1'b0;
            scan_active <= 1'b0;
            scan_bank <= 1'b0;
            scan_lut_bank <= 1'b1;
            scan_addr <= 6'd0;
            scan_cdf <= 13'd0;
            cdf_min <= 13'd0;
            cdf_min_found <= 1'b0;
            div_busy <= 1'b0;
            div_bin <= 6'd0;
            div_bits_left <= 5'd0;
            div_dividend <= 20'd0;
            div_quotient <= 20'd0;
            div_remainder <= 13'd0;
            div_denominator <= 14'd0;
            scan_pipeline_stage <= 2'd0;
            map_bin <= 6'd0;
            map_cdf <= 13'd0;
            map_denominator <= 14'd0;
            map_dividend <= 20'd0;
            for (l = 0; l < 64; l = l + 1) begin
                lut0[l] <= 8'd0;
                lut1[l] <= 8'd0;
            end
        end else begin
            if (I_tuser) begin
                lut_frame <= lut_active;
                lut_frame_valid <= lut_ready;
            end
            if (div_busy) begin
                div_dividend <= {div_dividend[18:0], 1'b0};
                div_remainder <= div_remainder_next;
                div_quotient <= {div_quotient[18:0], div_subtract};
                if (div_bits_left == 5'd1) begin
                    div_busy <= 1'b0;
                    if (scan_lut_bank) lut1[div_bin] <= div_result;
                    else lut0[div_bin] <= div_result;
                    if (div_bin == 6'd63) begin
                        lut_active <= scan_lut_bank;
                        lut_ready <= 1'b1;
                    end
                end else begin
                    div_bits_left <= div_bits_left - 5'd1;
                end
            end
            if (scan_active && (scan_pipeline_stage == 2'd0)) begin
                scan_cdf <= scan_cdf_next;
                if (!cdf_min_found && (scan_count != 0)) begin
                    cdf_min <= scan_cdf_next;
                    cdf_min_found <= 1'b1;
                end
                map_bin <= scan_addr;
                map_cdf <= scan_cdf_equalized;
                map_denominator <= scan_denominator;
                scan_pipeline_stage <= 2'd1;
                if (scan_addr == 6'd63)
                    scan_active <= 1'b0;
                else
                    scan_addr <= scan_addr + 6'd1;
            end else if (scan_pipeline_stage == 2'd1) begin
                map_dividend <= {map_cdf, 8'd0} - map_cdf;
                scan_pipeline_stage <= 2'd2;
            end else if (scan_pipeline_stage == 2'd2 && !div_busy) begin
                div_bin <= map_bin;
                div_dividend <= map_dividend;
                div_denominator <= map_denominator;
                div_quotient <= 20'd0;
                div_remainder <= 13'd0;
                div_bits_left <= 5'd20;
                div_busy <= 1'b1;
                scan_pipeline_stage <= 2'd0;
            end
            if (I_tuser && frame_seen) begin
                scan_active <= 1'b1;
                scan_pipeline_stage <= 2'd0;
                scan_bank <= write_bank;
                scan_lut_bank <= ~lut_active;
                scan_addr <= 6'd0;
                scan_cdf <= 13'd0;
                cdf_min <= 13'd0;
                cdf_min_found <= 1'b0;
            end
        end
    end
endmodule
