`include "uiisp_beta/auto_exposure.v"
`include "isp/raw_bayer_resize.v"
`include "isp/video_stripe_diag.v"
`include "isp/frame_awb.v"
`include "camera_fifo_guard.v"
`include "gimbal_red_tracker.v"
`include "gimbal_servo_test.v"
`include "gimbal_dual_servo_test.v"

module design_top_wrapper (
    input wire        I_sys_clk,
    input wire        I_rst_n,
      
    output wire       O_cam_scl,
    inout  wire       IO_cam_sda,
    output wire       O_cam_24m,
    output wire       O_cam_rst,
      
    input wire [3:0]  I_button,
    input wire        I_SW1,
    input wire        I_SW2,
    input wire        I_SW3,
    input wire        I_SW4,

    output wire       O_screen_pwm,
    output wire       O_gimbal_pan_pwm,
    output wire       O_gimbal_tilt_pwm,
    output wire       O_tmds_ch0_p,
    output wire       O_tmds_ch1_p,
    output wire       O_tmds_ch2_p,
    output wire       O_tmds_clk_p,

    inout wire        IO_rx_clk_pad_n, 
    inout wire        IO_rx_clk_pad_p, 
    inout wire[3:0]   IO_rx_data_pad_n,
    inout wire[3:0]   IO_rx_data_pad_p,

    output wire[12:0] ddr_addr,
    output wire[ 1:0] ddr_ba,
    output wire[ 0:0] ddr_cke,
    output wire[ 0:0] ddr_odt,
    output wire[ 0:0] ddr_cs_n,
    output wire       ddr_ras_n,
    output wire       ddr_cas_n,
    output wire       ddr_we_n,
    output wire[ 0:0] ddr_ck_p,
    output wire[ 0:0] ddr_ck_n,
    inout wire[1:0]   ddr_dm,
    inout wire[15:0]  ddr_dq,
    inout wire[1:0]   ddr_dqs_p,
    inout wire[1:0]   ddr_dqs_n   
);


    wire        	S_100m_clk;
    wire        	S_24m_clk;
    wire        	S_aux_50m_clk;
	wire        	S_10m_clk;
		
	wire        	S_pll_lock;
    wire        	S_rst_n;
	
	wire [15:0] 	S_ae;
    wire [15:0] 	S_ag;
    wire 			S_cam_cfg_done;
    wire 			S_ae_cfg_done;
    wire 			S_ae_req; 
	
	wire        	S_csi_rx_clk;  
    wire        	S_hs_rx_valid;  
    wire[15:0]  	S_hs_rx_data;   
	wire[1:0]   	S_lane_error;
	
	wire        	S_csi_frame_start;       
	wire        	S_csi_frame_end;         
	wire        	S_csi_valid;             
	wire[31:0]  	S_csi_data;  
		
	wire        	S_raw10_frame_start; 
	wire        	S_raw10_frame_end;   
	wire        	S_raw10_valid;       
	wire [39:0] 	S_raw10_data;
		
	wire 			S_axis_tlast;  
	wire 			S_axis_tuser;  
	wire [39:0]		S_axis_tdata;  
	wire 			S_axis_tvalid; 
	
	wire [39:0]		S_raw_tdata ;
	wire			S_raw_tlast ;
	wire 			S_raw_tvalid;
	wire 			S_raw_tuser ;
	
	wire [127:0]	S_ISP_O_tdata ;
	wire 			S_ISP_O_tlast ;
	wire 			S_ISP_O_tuser ;
	wire 			S_ISP_O_tvalid; 
	

    wire        S_ddr_clk;
    wire        S_hdmi_pixel_clk;
    wire        S_hdmi_serial_clk;
    wire        S_hdmi_rst_n;
    wire S_hdmi_pll_lock;
    wire        S_video_out_rst_n;


    wire        S_vi_128b_frame_start;
    wire        S_vi_128b_valid;      
    wire[127:0] S_vi_128b_data;    
    
    wire        S_video_out_rd_busy;
    wire        S_video_in_wr_busy; 
    wire[1:0]   S_video_out_rp;     
    wire [15:0] S_capture_frame_id_ddr;
    wire [15:0] S_display_frame_id_ddr;
    wire        S_frame_id_toggle_ddr;

    wire        S_ddr_user_wr_en;       
    wire        S_ddr_user_rd_en;       
    wire[24:0]  S_ddr_user_addr;        
    wire[127:0] S_ddr_user_wr_data;     
    wire        S_ddr_user_ready;       
    wire        S_ddr_user_rd_valid;    
    wire[127:0] S_ddr_user_rd_data;     

    wire        S_vi_ddr_wr_en;   
    wire[24:0]  S_vi_ddr_wr_addr; 
    wire[127:0] S_vi_ddr_wr_data;
    wire        S_vi_ddr_wr_ready;

    wire        S_vo_ddr_rd_en;   
    wire[24:0]  S_vo_ddr_rd_addr; 
    wire        S_vo_ddr_rd_ready;
    wire        S_vo_dbg_fifo_rst;
    wire        S_vo_dbg_ddr_rd_valid;
    wire        S_vo_dbg_fifo_rd_en;
    wire        S_vo_dbg_fifo_empty;

    wire        S_init_calib_complete; 
    wire[24:0]  S_mc_app_addr;          
    wire[2:0]   S_mc_app_cmd;           
    wire        S_mc_app_en;            
    wire[127:0] S_mc_app_wdf_data;      
    wire        S_mc_app_wdf_end;       
    wire[15:0]  S_mc_app_wdf_mask;      
    wire        S_mc_app_wdf_wren;      
    wire[127:0] S_mc_app_rd_data;       
    wire        S_mc_app_rd_data_end;   
    wire        S_mc_app_rd_data_valid; 
    wire        S_mc_app_rdy;           
    wire        S_mc_app_wdf_rdy;       
    wire        S_mc_dbg_fifo_afull;
    wire        S_mc_dbg_app_rdy;
    wire        S_mc_dbg_wdf_rdy;
    wire        S_mc_dbg_cmd_pop;

    wire        S_hdmi_vsync;
    wire        S_hdmi_hsync;
    wire        S_hdmi_de;
    wire        S_hdmi_user;
    wire        S_hdmi_last;
    wire        S_video_out_vsync;
    wire        S_hdmi_window_rd_en;
    wire        S_hdmi_out_vsync;
    wire        S_hdmi_out_hsync;
    wire        S_hdmi_out_de;
    wire[23:0]  S_hdmi_out_data;

    wire[23:0]  S_video_rd_data;
    wire        S_target_frame_toggle;
    wire        S_target_valid;
    wire [10:0]  S_target_x_min;
    wire [10:0]  S_target_y_min;
    wire [10:0]  S_target_x_max;
    wire [10:0]  S_target_y_max;
    wire [10:0]  S_target_center_x;
    wire [10:0]  S_target_center_y;
    wire [11:0] S_motion_count;
    wire        S_motion_valid;
    wire [10:0]  S_motion_x_min, S_motion_y_min;
    wire [10:0]  S_motion_x_max, S_motion_y_max;
    wire        S_hand_frame_toggle;
    wire [3:0]   S_hand_count;
    wire         S_hand_valid;
    wire [3:0]   S_hand_error;
    wire         S_hand_present;
    wire         S_hand_busy;
    reg S_sw3_sync1, S_sw3_sync2;
    reg S_sw1_sync1, S_sw1_sync2;
    reg S_sw1_hdmi_sync1, S_sw1_hdmi_sync2;
    reg S_sw3_hdmi_sync1, S_sw3_hdmi_sync2;
    reg S_sw4_hdmi_sync1, S_sw4_hdmi_sync2;
    reg  [1:0]  S_target_toggle_sync;
    reg         S_target_toggle_seen;
    reg         S_target_valid_hdmi;
    reg  [10:0]  S_target_x_min_hdmi;
    reg  [10:0]  S_target_y_min_hdmi;
    reg  [10:0]  S_target_x_max_hdmi;
    reg  [10:0]  S_target_y_max_hdmi;
    reg  [10:0]  S_target_center_x_hdmi;
    reg  [10:0]  S_target_center_y_hdmi;
    reg  [11:0] S_motion_count_hdmi;
    reg         S_motion_valid_hdmi;
    reg  [10:0]  S_motion_x_min_hdmi, S_motion_y_min_hdmi;
    reg  [10:0]  S_motion_x_max_hdmi, S_motion_y_max_hdmi;
    reg  [1:0]  S_hand_toggle_sync;
    reg         S_hand_toggle_seen;
    reg  [3:0]  S_hand_count_hdmi;
    reg         S_hand_valid_hdmi;
    reg  [3:0]  S_hand_error_hdmi;
    reg         S_hand_present_hdmi;
    reg         S_hand_busy_hdmi;
    reg  [1:0]  S_frame_id_toggle_sync;
    reg         S_frame_id_toggle_seen;
    reg  [15:0] S_capture_frame_id_hdmi;
    reg  [15:0] S_display_frame_id_hdmi;
    reg         S_dbg_raw_seen;
    reg         S_dbg_isp_seen;
    reg         S_dbg_ddr_wr_seen;
    reg         S_dbg_ddr_rd_seen;
    reg         S_dbg_cam_cfg_seen;
    reg         S_dbg_hs_seen;
    reg         S_dbg_csi_seen;
    reg         S_dbg_raw10_seen;
    reg         S_dbg_isp_fs_seen;
    reg         S_dbg_isp_valid_seen;
    reg         S_dbg_ddr_req_seen;
    reg         S_dbg_ddr_ready_seen;
    reg [1:0]   S_dbg_raw_seen_sync;
    reg [1:0]   S_dbg_isp_seen_sync;
    reg [1:0]   S_dbg_ddr_wr_seen_sync;
    reg [1:0]   S_dbg_ddr_rd_seen_sync;
    reg [1:0]   S_dbg_cam_cfg_seen_sync;
    reg [1:0]   S_dbg_hs_seen_sync;
    reg [1:0]   S_dbg_csi_seen_sync;
    reg [1:0]   S_dbg_raw10_seen_sync;
    reg [1:0]   S_dbg_isp_fs_seen_sync;
    reg [1:0]   S_dbg_isp_valid_seen_sync;
    reg [1:0]   S_dbg_ddr_req_seen_sync;
    reg [1:0]   S_dbg_ddr_ready_seen_sync;
    reg         S_dbg_video_nonzero_seen;
    reg         S_dbg_rd_req_seen;
    reg         S_dbg_rd_valid_seen;
    reg         S_dbg_rd_nonzero_seen;
    reg [1:0]   S_dbg_rd_req_seen_sync;
    reg [1:0]   S_dbg_rd_valid_seen_sync;
    reg [1:0]   S_dbg_rd_nonzero_seen_sync;
    reg         S_dbg_mc_init_seen;
    reg         S_dbg_mc_app_rdy_seen;
    reg         S_dbg_mc_wdf_rdy_seen;
    reg         S_dbg_mc_cmd_pop_seen;
    reg [1:0]   S_dbg_mc_init_seen_sync;
    reg [1:0]   S_dbg_mc_app_rdy_seen_sync;
    reg [1:0]   S_dbg_mc_wdf_rdy_seen_sync;
    reg [1:0]   S_dbg_mc_cmd_pop_seen_sync;
    wire[3:0]   S_hdmi_debug_status;
    wire        S_lane_error_any;
    wire S_luma_frame_toggle, S_luma_ack_toggle;
    wire [7:0] S_avg_luma;
    wire [19:0] S_highlight_count;
    wire [7:0] S_ae_luma_debug;
    wire S_diag_key;
    reg [1:0] S_diag_mode;
    wire [2:0]  S_algo_mode;
    wire        S_algo_key_pulse;
    reg  [2:0]  S_algo_mode_reg;
    wire        S_vivid_enable = 1'b1;
    wire S_edge_key_pulse;
    wire S_ae_target_key_pulse;
    reg [2:0] S_ae_target_level;
    reg [3:0] S_manual_gain_level;
    reg S_sw2_sync1, S_sw2_sync2;
    reg S_sw2_24_sync1, S_sw2_24_sync2;
    reg [3:0] S_gain_level_sync1, S_gain_level_sync2;
    reg [1:0] S_sw2_hdmi_sync1, S_sw2_hdmi_sync2;
    wire [15:0] S_manual_gain_value = (S_gain_level_sync2 == 4'd15) ? 16'd140 :
                                      16'd16 + ({12'd0, S_gain_level_sync2} << 3);
    reg [2:0] S_ae_level_sync1, S_ae_level_sync2;
    reg [2:0] S_ae_level_hdmi_sync1, S_ae_level_hdmi_sync2;
    // Six AE target bands cover the full 8-bit luma range.
    wire [7:0] S_ae_target_low = (S_ae_level_sync2 == 3'd0) ? 8'd0   :
                                  (S_ae_level_sync2 == 3'd1) ? 8'd50  :
                                  (S_ae_level_sync2 == 3'd2) ? 8'd100 :
                                  (S_ae_level_sync2 == 3'd3) ? 8'd150 :
                                  (S_ae_level_sync2 == 3'd4) ? 8'd200 : 8'd250;
    wire [7:0] S_ae_target_high = (S_ae_level_sync2 == 3'd0) ? 8'd50  :
                                   (S_ae_level_sync2 == 3'd1) ? 8'd100 :
                                   (S_ae_level_sync2 == 3'd2) ? 8'd150 :
                                   (S_ae_level_sync2 == 3'd3) ? 8'd200 :
                                   (S_ae_level_sync2 == 3'd4) ? 8'd250 : 8'd255;
    reg [1:0] S_edge_level;
    wire [7:0] S_edge_threshold = (S_edge_level == 0) ? 8'd48 :
                                  (S_edge_level == 1) ? 8'd32 :
                                  (S_edge_level == 2) ? 8'd16 : 8'd96;


    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if (!S_hdmi_rst_n) begin
            S_target_toggle_sync <= 2'b00;
            S_target_toggle_seen <= 1'b0;
            S_target_valid_hdmi <= 1'b0;
            S_target_x_min_hdmi <= 10'd0;
            S_target_y_min_hdmi <= 10'd0;
            S_target_x_max_hdmi <= 10'd0;
            S_target_y_max_hdmi <= 10'd0;
            S_target_center_x_hdmi <= 10'd0;
            S_target_center_y_hdmi <= 10'd0;
            S_motion_count_hdmi <= 12'd0;
            S_motion_valid_hdmi <= 1'b0;
            S_motion_x_min_hdmi <= 10'd0;
            S_motion_y_min_hdmi <= 10'd0;
            S_motion_x_max_hdmi <= 10'd0;
            S_motion_y_max_hdmi <= 10'd0;
            S_frame_id_toggle_sync <= 2'b00;
            S_frame_id_toggle_seen <= 1'b0;
            S_capture_frame_id_hdmi <= 16'd0;
            S_display_frame_id_hdmi <= 16'd0;
            S_hand_toggle_sync <= 2'b00;
            S_hand_toggle_seen <= 1'b0;
            S_hand_count_hdmi <= 4'd0;
            S_hand_valid_hdmi <= 1'b0;
            S_hand_error_hdmi <= 4'd0;
            S_hand_present_hdmi <= 1'b0;
            S_hand_busy_hdmi <= 1'b0;
        end else begin
            S_target_toggle_sync <= {S_target_toggle_sync[0], S_target_frame_toggle};
            S_hand_toggle_sync <= {S_hand_toggle_sync[0], S_hand_frame_toggle};
            S_frame_id_toggle_sync <= {S_frame_id_toggle_sync[0], S_frame_id_toggle_ddr};
            if (S_frame_id_toggle_sync[1] != S_frame_id_toggle_seen) begin
                S_frame_id_toggle_seen <= S_frame_id_toggle_sync[1];
                S_capture_frame_id_hdmi <= S_capture_frame_id_ddr;
                S_display_frame_id_hdmi <= S_display_frame_id_ddr;
            end
            if (S_target_toggle_sync[1] != S_target_toggle_seen) begin
                S_target_toggle_seen <= S_target_toggle_sync[1];
                S_target_valid_hdmi <= S_target_valid;
                S_target_x_min_hdmi <= S_target_x_min;
                S_target_y_min_hdmi <= S_target_y_min;
                S_target_x_max_hdmi <= S_target_x_max;
                S_target_y_max_hdmi <= S_target_y_max;
                S_target_center_x_hdmi <= S_target_center_x;
                S_target_center_y_hdmi <= S_target_center_y;
                S_motion_count_hdmi <= S_motion_count;
                S_motion_valid_hdmi <= S_motion_valid;
                S_motion_x_min_hdmi <= S_motion_x_min;
                S_motion_y_min_hdmi <= S_motion_y_min;
                S_motion_x_max_hdmi <= S_motion_x_max;
                S_motion_y_max_hdmi <= S_motion_y_max;
            end
            if (S_hand_toggle_sync[1] != S_hand_toggle_seen) begin
                S_hand_toggle_seen <= S_hand_toggle_sync[1];
                S_hand_count_hdmi <= S_hand_count;
                S_hand_valid_hdmi <= S_hand_valid;
                S_hand_error_hdmi <= S_hand_error;
                S_hand_present_hdmi <= S_hand_present;
                S_hand_busy_hdmi <= S_hand_busy;
            end
        end
    end


    assign O_screen_pwm = 1'b1;
    assign S_video_out_vsync = ~S_hdmi_vsync;

    // Only red coordinates drive the servos. SW3 high (motion display) and
    // diagnostic modes hold the last command; all image keys stay available.
    gimbal_red_tracker #(
        .CLK_FREQ_HZ       (100000000),
        .IMG_WIDTH         (1280),
        .IMG_HEIGHT        (720),
        // Treat the central 100x100 pixels as the tracking hold region.
        .DEAD_BAND_PIXELS  (50),
        .MAX_STEP_PER_UPDATE(2),
        .UPDATE_INTERVAL_MS(100),
        .CONFIRM_FRAMES    (3),
        .PAN_REVERSE       (1),
        // V7: invert only tilt after the V6 board test; pan is confirmed.
        .TILT_REVERSE      (1)
    ) u_gimbal_red_tracker (
        .I_clk(S_100m_clk),
        .I_rst_n(S_rst_n),
        // SW3 low selects red tracking overlay; diagnostic image modes hold
        // the gimbal command so they cannot accidentally drive the servos.
        .I_enable((!S_sw3_sync2) && (S_diag_mode == 2'd0)),
        .I_target_frame_toggle(S_target_frame_toggle),
        .I_target_valid(S_target_valid),
        .I_target_center_x(S_target_center_x),
        .I_target_center_y(S_target_center_y),
        .O_pan_pwm(O_gimbal_pan_pwm),
        .O_tilt_pwm(O_gimbal_tilt_pwm)
    );
	
	
    assign S_rst_n 		= S_pll_lock;
    assign S_hdmi_rst_n = S_pll_lock & S_hdmi_pll_lock;

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if (!S_rst_n) begin
            S_sw3_sync1 <= 1'b0;
            S_sw3_sync2 <= 1'b0;
            S_sw1_sync1 <= 1'b0;
            S_sw1_sync2 <= 1'b0;
        end else begin
            S_sw3_sync1 <= I_SW3;
            S_sw3_sync2 <= S_sw3_sync1;
            S_sw1_sync1 <= I_SW1;
            S_sw1_sync2 <= S_sw1_sync1;
        end
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_raw_seen <= 1'b0;
        else if(S_raw10_frame_start | S_axis_tvalid)
            S_dbg_raw_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_isp_seen <= 1'b0;
        else if(S_ISP_O_tuser | S_ISP_O_tvalid)
            S_dbg_isp_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_wr_seen <= 1'b0;
        else if(S_vi_ddr_wr_en)
            S_dbg_ddr_wr_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_rd_seen <= 1'b0;
        else if(S_ddr_user_rd_valid)
            S_dbg_ddr_rd_seen <= 1'b1;
    end

    always @(posedge S_24m_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_cam_cfg_seen <= 1'b0;
        else if(S_cam_cfg_done)
            S_dbg_cam_cfg_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_hs_seen <= 1'b0;
        else if(S_hs_rx_valid)
            S_dbg_hs_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_csi_seen <= 1'b0;
        else if(S_csi_frame_start | S_csi_valid)
            S_dbg_csi_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_raw10_seen <= 1'b0;
        else if(S_raw10_frame_start | S_raw10_valid)
            S_dbg_raw10_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_isp_fs_seen <= 1'b0;
        else if(S_ISP_O_tuser)
            S_dbg_isp_fs_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_isp_valid_seen <= 1'b0;
        else if(S_ISP_O_tvalid)
            S_dbg_isp_valid_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_req_seen <= 1'b0;
        else if(S_vi_ddr_wr_en)
            S_dbg_ddr_req_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_ready_seen <= 1'b0;
        else if(S_ddr_user_ready)
            S_dbg_ddr_ready_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_video_out_rst_n) begin
        if(!S_video_out_rst_n)
            S_dbg_rd_req_seen <= 1'b0;
        else if(S_video_out_vsync)
            S_dbg_rd_req_seen <= 1'b0;
        else if(S_vo_ddr_rd_en)
            S_dbg_rd_req_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_video_out_rst_n) begin
        if(!S_video_out_rst_n)
            S_dbg_rd_valid_seen <= 1'b0;
        else if(S_video_out_vsync)
            S_dbg_rd_valid_seen <= 1'b0;
        else if(S_ddr_user_rd_valid)
            S_dbg_rd_valid_seen <= 1'b1;
    end

    always @(posedge S_hdmi_pixel_clk or negedge S_video_out_rst_n) begin
        if(!S_video_out_rst_n)
            S_dbg_rd_nonzero_seen <= 1'b0;
        else if(S_video_out_vsync)
            S_dbg_rd_nonzero_seen <= 1'b0;
        else if(S_hdmi_window_rd_en && (S_video_rd_data != 24'd0))
            S_dbg_rd_nonzero_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_init_seen <= 1'b0;
        else if(S_init_calib_complete)
            S_dbg_mc_init_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_app_rdy_seen <= 1'b0;
        else if(S_mc_dbg_app_rdy)
            S_dbg_mc_app_rdy_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_wdf_rdy_seen <= 1'b0;
        else if(S_mc_dbg_wdf_rdy)
            S_dbg_mc_wdf_rdy_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_cmd_pop_seen <= 1'b0;
        else if(S_mc_dbg_cmd_pop)
            S_dbg_mc_cmd_pop_seen <= 1'b1;
    end

    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_dbg_cam_cfg_seen_sync <= 2'b00;
            S_dbg_hs_seen_sync      <= 2'b00;
            S_dbg_csi_seen_sync     <= 2'b00;
            S_dbg_raw10_seen_sync   <= 2'b00;
            S_dbg_raw_seen_sync    <= 2'b00;
            S_dbg_isp_seen_sync    <= 2'b00;
            S_dbg_ddr_wr_seen_sync <= 2'b00;
            S_dbg_ddr_rd_seen_sync <= 2'b00;
            S_dbg_isp_fs_seen_sync  <= 2'b00;
            S_dbg_isp_valid_seen_sync <= 2'b00;
            S_dbg_ddr_req_seen_sync <= 2'b00;
            S_dbg_ddr_ready_seen_sync <= 2'b00;
            S_dbg_video_nonzero_seen <= 1'b0;
            S_dbg_rd_req_seen_sync <= 2'b00;
            S_dbg_rd_valid_seen_sync <= 2'b00;
            S_dbg_rd_nonzero_seen_sync <= 2'b00;
            S_dbg_mc_init_seen_sync <= 2'b00;
            S_dbg_mc_app_rdy_seen_sync <= 2'b00;
            S_dbg_mc_wdf_rdy_seen_sync <= 2'b00;
            S_dbg_mc_cmd_pop_seen_sync <= 2'b00;
        end
        else begin
            S_dbg_cam_cfg_seen_sync <= {S_dbg_cam_cfg_seen_sync[0], S_dbg_cam_cfg_seen};
            S_dbg_hs_seen_sync      <= {S_dbg_hs_seen_sync[0],      S_dbg_hs_seen};
            S_dbg_csi_seen_sync     <= {S_dbg_csi_seen_sync[0],     S_dbg_csi_seen};
            S_dbg_raw10_seen_sync   <= {S_dbg_raw10_seen_sync[0],   S_dbg_raw10_seen};
            S_dbg_raw_seen_sync    <= {S_dbg_raw_seen_sync[0],    S_dbg_raw_seen};
            S_dbg_isp_seen_sync    <= {S_dbg_isp_seen_sync[0],    S_dbg_isp_seen};
            S_dbg_ddr_wr_seen_sync <= {S_dbg_ddr_wr_seen_sync[0], S_dbg_ddr_wr_seen};
            S_dbg_ddr_rd_seen_sync <= {S_dbg_ddr_rd_seen_sync[0], S_dbg_ddr_rd_seen};
            S_dbg_isp_fs_seen_sync  <= {S_dbg_isp_fs_seen_sync[0],  S_dbg_isp_fs_seen};
            S_dbg_isp_valid_seen_sync <= {S_dbg_isp_valid_seen_sync[0], S_dbg_isp_valid_seen};
            S_dbg_ddr_req_seen_sync <= {S_dbg_ddr_req_seen_sync[0], S_dbg_ddr_req_seen};
            S_dbg_ddr_ready_seen_sync <= {S_dbg_ddr_ready_seen_sync[0], S_dbg_ddr_ready_seen};
            S_dbg_rd_req_seen_sync <= {S_dbg_rd_req_seen_sync[0], S_dbg_rd_req_seen};
            S_dbg_rd_valid_seen_sync <= {S_dbg_rd_valid_seen_sync[0], S_dbg_rd_valid_seen};
            S_dbg_rd_nonzero_seen_sync <= {S_dbg_rd_nonzero_seen_sync[0], S_dbg_rd_nonzero_seen};
            S_dbg_mc_init_seen_sync <= {S_dbg_mc_init_seen_sync[0], S_dbg_mc_init_seen};
            S_dbg_mc_app_rdy_seen_sync <= {S_dbg_mc_app_rdy_seen_sync[0], S_dbg_mc_app_rdy_seen};
            S_dbg_mc_wdf_rdy_seen_sync <= {S_dbg_mc_wdf_rdy_seen_sync[0], S_dbg_mc_wdf_rdy_seen};
            S_dbg_mc_cmd_pop_seen_sync <= {S_dbg_mc_cmd_pop_seen_sync[0], S_dbg_mc_cmd_pop_seen};
            if(S_hdmi_window_rd_en && (S_video_rd_data != 24'd0))
                S_dbg_video_nonzero_seen <= 1'b1;
        end
    end

    assign S_lane_error_any = |S_lane_error;
    assign S_algo_mode = S_algo_mode_reg;

    key_remove_shakes u_algo_mode_key (
        .I_clk          (S_csi_rx_clk),
        .I_rst_n        (S_rst_n),
        .I_key_in       (I_button[0]),
        .O_key_trig_out (S_algo_key_pulse)
    );

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if (!S_rst_n)
            S_algo_mode_reg <= 3'd0;
        else if (S_algo_key_pulse)
            S_algo_mode_reg <= (S_algo_mode_reg == 3'd7) ? 3'd0 : S_algo_mode_reg + 3'd1;
    end

    key_remove_shakes u_edge_threshold_key (
        .I_clk(S_csi_rx_clk), .I_rst_n(S_rst_n),
        .I_key_in(I_button[1]), .O_key_trig_out(S_edge_key_pulse)
    );
    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if (!S_rst_n) S_edge_level <= 0;
        else if (S_edge_key_pulse) S_edge_level <= S_edge_level + 1'b1;
    end

    key_remove_shakes u_ae_target_key (
        .I_clk(S_csi_rx_clk), .I_rst_n(S_rst_n),
        .I_key_in(I_button[2]), .O_key_trig_out(S_ae_target_key_pulse)
    );
    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if (!S_rst_n) begin
            S_ae_target_level <= 3'd3;
            S_manual_gain_level <= 4'd0;
        end else if (S_ae_target_key_pulse) begin
            if (S_sw2_sync2)
                S_ae_target_level <= (S_ae_target_level == 3'd5) ? 3'd0 : S_ae_target_level + 1'b1;
            else
                S_manual_gain_level <= (S_manual_gain_level == 4'd15) ? 4'd0 : S_manual_gain_level + 1'b1;
        end
    end
    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if (!S_rst_n) begin
            S_sw2_sync1 <= 1'b1;
            S_sw2_sync2 <= 1'b1;
        end else begin
            S_sw2_sync1 <= I_SW2;
            S_sw2_sync2 <= S_sw2_sync1;
        end
    end
    always @(posedge S_24m_clk or negedge S_rst_n) begin
        if (!S_rst_n) begin
            S_ae_level_sync1 <= 3'd3;
            S_ae_level_sync2 <= 3'd3;
            S_gain_level_sync1 <= 4'd0;
            S_gain_level_sync2 <= 4'd0;
            S_sw2_24_sync1 <= 1'b1;
            S_sw2_24_sync2 <= 1'b1;
        end else begin
            S_ae_level_sync1 <= S_ae_target_level;
            S_ae_level_sync2 <= S_ae_level_sync1;
            S_gain_level_sync1 <= S_manual_gain_level;
            S_gain_level_sync2 <= S_gain_level_sync1;
            S_sw2_24_sync1 <= S_sw2_sync2;
            S_sw2_24_sync2 <= S_sw2_24_sync1;
        end
    end
    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if (!S_hdmi_rst_n) begin
            S_ae_level_hdmi_sync1 <= 3'd3;
            S_ae_level_hdmi_sync2 <= 3'd3;
            S_sw2_hdmi_sync1 <= 2'b11;
            S_sw2_hdmi_sync2 <= 2'b11;
            S_sw3_hdmi_sync1 <= 1'b0;
            S_sw3_hdmi_sync2 <= 1'b0;
            S_sw1_hdmi_sync1 <= 1'b0;
            S_sw1_hdmi_sync2 <= 1'b0;
            S_sw4_hdmi_sync1 <= 1'b0;
            S_sw4_hdmi_sync2 <= 1'b0;
        end else begin
            S_ae_level_hdmi_sync1 <= S_ae_level_sync2;
            S_ae_level_hdmi_sync2 <= S_ae_level_hdmi_sync1;
            S_sw2_hdmi_sync1 <= {1'b0, S_sw2_sync2};
            S_sw2_hdmi_sync2 <= S_sw2_hdmi_sync1;
            S_sw3_hdmi_sync1 <= S_sw3_sync2;
            S_sw3_hdmi_sync2 <= S_sw3_hdmi_sync1;
            S_sw1_hdmi_sync1 <= S_sw1_sync2;
            S_sw1_hdmi_sync2 <= S_sw1_hdmi_sync1;
            S_sw4_hdmi_sync1 <= I_SW4;
            S_sw4_hdmi_sync2 <= S_sw4_hdmi_sync1;
        end
    end

    key_remove_shakes u_diag_key (
        .I_clk(S_csi_rx_clk),.I_rst_n(S_rst_n),
        .I_key_in(I_button[3]),.O_key_trig_out(S_diag_key)
    );
    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n) S_diag_mode<=0;
        else if(S_diag_key)
            S_diag_mode<=(S_diag_mode==2)?0:S_diag_mode+1'b1;
    end
    assign S_vo_dbg_fifo_rst = 1'b0;
    assign S_vo_dbg_ddr_rd_valid = 1'b0;
    assign S_vo_dbg_fifo_rd_en = 1'b0;
    assign S_vo_dbg_fifo_empty = 1'b0;
    assign S_mc_dbg_fifo_afull = 1'b0;
    assign S_mc_dbg_app_rdy = 1'b0;
    assign S_mc_dbg_wdf_rdy = 1'b0;
    assign S_mc_dbg_cmd_pop = 1'b0;

    assign S_hdmi_debug_status = {
        (|S_ddr_user_rd_data),
        S_ddr_user_rd_valid,
        S_vo_ddr_rd_en,
        S_vi_ddr_wr_en
    };
	
	assign O_cam_rst 	= 1'b1;
    assign O_cam_24m 	= S_24m_clk;
	
	
	
	
    // Generated TD PLL: 50 MHz reference -> 74.25 MHz pixel, 371.25 MHz serial.
    my_pll u_hdmi_pll (
        .refclk(I_sys_clk),.reset(~I_rst_n),
        .clk0_out(S_hdmi_pixel_clk),.clk1_out(S_hdmi_serial_clk),
        .lock(S_hdmi_pll_lock)
    );

    PLL u_PLL(
        .refclk      ( I_sys_clk         ),
        .reset    	 ( ~I_rst_n          ),
        
        .clk0_out    ( S_100m_clk        ),
        .clk1_out    ( S_24m_clk         ),

        .clk4_out    ( S_aux_50m_clk     ),
        .clk5_out    (                   ),

        .lock        ( S_pll_lock        )

    );


	

  
  auto_exposure u_auto_exposure (
      .I_clk(S_24m_clk),
      .I_rst(~S_rst_n),
      .I_luma_toggle(S_luma_frame_toggle),
      .I_avg_luma(S_avg_luma),
      .I_highlight_count(S_highlight_count),
      .I_target_low(S_ae_target_low),
      .I_target_high(S_ae_target_high),
      .I_manual_gain_enable(~S_sw2_24_sync2),
      .I_manual_gain(S_manual_gain_value),
      .O_luma_ack_toggle(S_luma_ack_toggle),
      .O_luma_debug(S_ae_luma_debug),
      .I_cam_cfg_done(S_cam_cfg_done),
      .I_ae_cfg_done(S_ae_cfg_done),
      .O_ae_req(S_ae_req),
      .O_ae(S_ae),
      .O_ag(S_ag)
  );
  
    uicfgcs500 #(
      .CLK_DIV(24000000 / 100000 - 1)
  ) u_uicfgcs500 (
      .I_clk(S_24m_clk),  //系统时钟输入
      .I_rst_n(S_rst_n),  //系统复位输入
      .I_ae_req(S_ae_req),
      .I_ae(S_ae),
      .I_ag(S_ag),
      .O_cam_scl(O_cam_scl),  //I2C总线，SCL时钟
      .IO_cam_sda(IO_cam_sda),  //I2C总线，SDA数据
      .O_cfg_done(S_cam_cfg_done),  //摄像头寄存器初始化完成
      .O_ae_cfg_done(S_ae_cfg_done)  //AE配置完成
  );
	
    mipi_dphy_rx_ph1p_mipiio_wrapper#(
        .DPHY_RX_LOCATION      ( "DPHY0" ),
        .HS_EQUALIZER          ( "0dB"   ),//"0dB","1.5dB","3dB","4.5dB","6dB","7.5dB","9dB","10.5dB"
        .HS_VGA_GAIN           ( "8dB" ),//"-3dB","-1.5dB","0dB","1.5dB","3dB","4.5dB","6dB","7.5dB"
        .LANE_NUM              ( 2       ),
        .BYTE_NUM              ( 1       )
    )u_mipi_dphy_rx_ph1p_mipiio_wrapper(
        .I_lp_clk              ( S_100m_clk       ),
        .I_rst                 ( ~S_rst_n         ),

        .I_clk_lane_in_delay   ( 6'd0             ),
        .I_data_lane0_in_delay ( 6'd0             ),
        .I_data_lane1_in_delay ( 6'd0             ),
        .I_data_lane2_in_delay ( 6'd0             ),
        .I_data_lane3_in_delay ( 6'd0             ),

        .I_lane_invert         ( 2'b00            ),
     
        .O_hs_rx_clk           ( S_csi_rx_clk     ),
        .O_hs_rx_valid         ( S_hs_rx_valid    ),
        .O_hs_rx_data          ( S_hs_rx_data     ),
      
        .O_lp_rx_lane0_p       (  ),
        .O_lp_rx_lane0_n       (  ),
      
        .I_lp_tx_en            ( 1'b0             ),
        .I_lp_tx_lane0_p       ( 1'b1             ),
        .I_lp_tx_lane0_n       ( 1'b1             ),
      
        .O_lane_match_error    (                  ),
        .O_lane_error          ( S_lane_error     ),
      
        .IO_rx_clk_pad_n       ( IO_rx_clk_pad_n  ),
        .IO_rx_clk_pad_p       ( IO_rx_clk_pad_p  ),
        .IO_rx_data_pad_n      ( IO_rx_data_pad_n ),
        .IO_rx_data_pad_p      ( IO_rx_data_pad_p )
    );
	
	
 //  cwc cwc_inst
 //(
 //    .probe0(S_hs_rx_valid),
 //    .probe1(S_hs_rx_data),
 //    .probe2(S_lane_error),
 //    .clk(S_csi_rx_clk)
 //);

 //csi 解码为RAW数据
csi_unpacket_2lane u_csi_unpacket(
.I_clk                 ( S_csi_rx_clk       ),
.I_rst_n               ( S_rst_n        	),
.I_hs_valid            ( S_hs_rx_valid     ),
.I_hs_data             ( S_hs_rx_data      ),

.O_csi_frame_start     ( S_csi_frame_start ),
.O_csi_frame_end       ( S_csi_frame_end   ),
.O_csi_valid           ( S_csi_valid       ),
.O_csi_data            ( S_csi_data        )
);


//解码为RAW8
raw10_unpacket_2lane u_raw10_unpacket (
.I_clk  (S_csi_rx_clk),
.I_rst_n(S_rst_n),

.I_csi_frame_start(S_csi_frame_start),
.I_csi_frame_end  (S_csi_frame_end),
.I_csi_valid      (S_csi_valid),
.I_csi_data       (S_csi_data),
.I_camera_black_level(10'd0),

.O_raw10_frame_start(S_raw10_frame_start),
.O_raw10_frame_end  (S_raw10_frame_end),
.O_raw10_valid      (S_raw10_valid),
.O_raw10_data       (S_raw10_data)
  );


//将数据转为stream流
uial2axis #(
.IMG_WIDTH(1920),
.IMG_HEIGHT(1080),
.INPUT_DATA_WIDTH(40)
) 
u_uial2axis (
.I_native_clk(S_csi_rx_clk),
.I_rst_n     (S_rst_n),
.I_data      (S_raw10_data       ),
.I_data_valid(S_raw10_valid      ),
.I_data_start(S_raw10_frame_start),
.I_data_end  (S_raw10_frame_end  ),
.axis_tvalid (S_axis_tvalid),
.axis_tdata  (S_axis_tdata ),
.axis_tuser  (S_axis_tuser ),
.axis_tlast  (S_axis_tlast )
);
	

raw_bayer_resize #(
    .IN_WIDTH(1920),.IN_HEIGHT(1080),.OUT_WIDTH(1920),.OUT_HEIGHT(1080)
) u_raw_bayer_resize (
    .I_clk(S_csi_rx_clk),.I_rst_n(S_rst_n),
    .I_data(S_axis_tdata),.I_valid(S_axis_tvalid),.I_user(S_axis_tuser),
    .O_data(S_raw_tdata),.O_last(S_raw_tlast),
    .O_valid(S_raw_tvalid),.O_user(S_raw_tuser)
);


//cwc1 cwc1_Inst
//  (
//      .probe0(S_axis_tuser),
//      .probe1(S_axis_tvalid),
//      .probe2(S_axis_tlast),
//      .probe3(S_axis_tdata),
//      .probe4(S_ISP_O_tuser),
//      .probe5(S_ISP_O_tvalid),
//      .probe6(S_ISP_O_tlast),
//      .probe7(S_ISP_O_tdata),
//      .probe8 (S_raw_tdata ),
//      .probe9 (S_raw_tlast ),
//      .probe10(S_raw_tvalid),
//      .probe11(S_raw_tuser ),
//      .clk(S_csi_rx_clk)
//  );


//ISP算法顶层模块
isp_top u_isp_top (
.axi4s_video_aclk(S_csi_rx_clk),
.hand_analysis_clk(S_aux_50m_clk),
.I_rst_n         (S_rst_n),
.I_tlast         (S_raw_tlast	),
.I_tuser         (S_raw_tuser	),
.I_tdata         (S_raw_tdata	),
.I_tvalid        (S_raw_tvalid	),
.I_tdest         (10'd0),
.I_diag_mode(S_diag_mode),
.I_algo_mode     (S_algo_mode),
.I_algo_threshold(S_edge_threshold),
.I_vivid_enable  (S_vivid_enable),
.I_hand_enable   (S_sw1_sync2 && S_sw3_sync2),
.I_luma_ack_toggle(S_luma_ack_toggle),
.O_luma_frame_toggle(S_luma_frame_toggle),
.O_avg_luma(S_avg_luma),
.O_highlight_count(S_highlight_count),
.O_target_frame_toggle(S_target_frame_toggle),
.O_target_valid  (S_target_valid),
.O_target_x_min  (S_target_x_min),
.O_target_y_min  (S_target_y_min),
.O_target_x_max  (S_target_x_max),
.O_target_y_max  (S_target_y_max),
.O_target_center_x(S_target_center_x),
.O_target_center_y(S_target_center_y),
.O_motion_count  (S_motion_count),
.O_motion_valid  (S_motion_valid),
.O_motion_x_min  (S_motion_x_min),
.O_motion_y_min  (S_motion_y_min),
.O_motion_x_max  (S_motion_x_max),
.O_motion_y_max  (S_motion_y_max),
.O_hand_frame_toggle(S_hand_frame_toggle),
.O_hand_count(S_hand_count),
.O_hand_valid(S_hand_valid),
.O_hand_error(S_hand_error),
.O_hand_present(S_hand_present),
.O_hand_busy(S_hand_busy),
.O_tdata         (S_ISP_O_tdata ),
.O_tlast         (S_ISP_O_tlast ),
.O_tuser         (S_ISP_O_tuser ),
.O_tvalid        (S_ISP_O_tvalid),
.I_tready        ()
  );


    wire S_camera_guard_valid;
    wire [127:0] S_camera_guard_data;
    camera_fifo_guard u_camera_fifo_guard (
      .clk(S_csi_rx_clk),.rst_n(S_rst_n),
      .valid(S_ISP_O_tvalid),.data(S_ISP_O_tdata),
      .out_valid(S_camera_guard_valid),.out_data(S_camera_guard_data)
    );
    video_in u_video_in(
        .I_rst_n              (  S_rst_n             ),

        .I_camera_clk         ( S_csi_rx_clk          ),
        .I_camera_frame_start ( S_ISP_O_tuser  ),
        .I_camera_valid       ( S_camera_guard_valid ),
        .I_camera_data        ( S_camera_guard_data  ),
        .I_mipi_rx_error      ( 1'b0			      ),

        .I_ddr_clk            ( S_ddr_clk             ),
		.I_display_pause      ( 1'b0                  ),
        .I_video_out_rd_busy  ( S_video_out_rd_busy   ),
        .O_video_in_wr_busy   ( S_video_in_wr_busy    ),
        .O_video_out_rp       ( S_video_out_rp        ),
        .O_capture_frame_id   ( S_capture_frame_id_ddr),
        .O_display_frame_id   ( S_display_frame_id_ddr),
        .O_frame_id_toggle    ( S_frame_id_toggle_ddr ),

        .O_ddr_user_wr_en     ( S_vi_ddr_wr_en        ),
        .O_ddr_user_addr      ( S_vi_ddr_wr_addr      ),
        .O_ddr_user_wr_data   ( S_vi_ddr_wr_data      ),
        .I_ddr_user_ready     ( S_ddr_user_ready      )
    );



    assign S_ddr_user_wr_en    = S_vi_ddr_wr_en;

    assign S_ddr_user_rd_en    = S_vo_ddr_rd_en;

    assign S_ddr_user_addr     = S_vi_ddr_wr_en ? S_vi_ddr_wr_addr :
                                 S_vo_ddr_rd_en ? S_vo_ddr_rd_addr : 'd0;

    assign S_ddr_user_wr_data  = S_vi_ddr_wr_data;


    assign S_video_out_rst_n = S_hdmi_rst_n;

    video_out u_video_out(
        .I_rst_n             ( S_video_out_rst_n    ),
        .I_ddr_clk           ( S_ddr_clk            ),
 
        .O_video_out_rd_busy ( S_video_out_rd_busy  ),
        .I_video_in_wr_busy  ( S_video_in_wr_busy   ),
        .I_video_out_rp      ( S_video_out_rp       ),
 
        .O_ddr_user_rd_en    ( S_vo_ddr_rd_en       ),
        .O_ddr_user_addr     ( S_vo_ddr_rd_addr     ),
        .I_ddr_user_ready    ( S_ddr_user_ready     ),
        .I_ddr_user_rd_valid ( S_ddr_user_rd_valid  ),
        .I_ddr_user_rd_data  ( S_ddr_user_rd_data   ),

        .I_dsi_clk           ( S_hdmi_pixel_clk     ),
        .I_video_vsync       ( S_video_out_vsync    ),
        .I_video_rd_en       ( S_hdmi_window_rd_en  ),
        .O_vdieo_data        ( S_video_rd_data      )
    );



    mc_to_user_interface u_mc_to_user_interface(
        .I_clk                   ( S_ddr_clk               ),
        .I_rst_n                 ( S_rst_n                 ),

        .I_ddr_user_wr_en        ( S_ddr_user_wr_en        ),
        .I_ddr_user_rd_en        ( S_ddr_user_rd_en        ),
        .I_ddr_user_addr         ( S_ddr_user_addr         ),
        .I_ddr_user_wr_data      ( S_ddr_user_wr_data      ),
        .O_ddr_user_ready        ( S_ddr_user_ready        ),
        .O_ddr_user_rd_valid     ( S_ddr_user_rd_valid     ),
        .O_ddr_user_rd_data      ( S_ddr_user_rd_data      ),
            
        .O_mc_app_en             ( S_mc_app_en             ),
        .O_mc_app_addr           ( S_mc_app_addr           ),
        .O_mc_app_cmd            ( S_mc_app_cmd            ),
        .I_mc_app_rdy            ( S_mc_app_rdy            ),
        .O_mc_app_wdf_wren       ( S_mc_app_wdf_wren       ),
        .O_mc_app_wdf_data       ( S_mc_app_wdf_data       ),
        .O_mc_app_wdf_end        ( S_mc_app_wdf_end        ),
        .O_mc_app_wdf_mask       ( S_mc_app_wdf_mask       ),
        .I_mc_app_wdf_rdy        ( S_mc_app_wdf_rdy        ),
        .I_mc_app_rd_data        ( S_mc_app_rd_data        ),
        .I_mc_app_rd_data_end    ( S_mc_app_rd_data_end    ),
        .I_mc_app_rd_data_valid  ( S_mc_app_rd_data_valid  )
    );



    ph1p35_324_ddr_wrapper u_ph1p35_324_ddr_wrapper(
        .I_sys_clk              ( I_sys_clk              ),
        .I_sys_rst_n            ( S_rst_n                ),

        .O_ddr_clk              ( S_ddr_clk              ),
        .O_init_calib_complete  ( S_init_calib_complete  ),
        .I_mc_app_addr          ( S_mc_app_addr          ),
        .I_mc_app_cmd           ( S_mc_app_cmd           ),
        .I_mc_app_en            ( S_mc_app_en            ),
        .I_mc_app_wdf_data      ( S_mc_app_wdf_data      ),
        .I_mc_app_wdf_end       ( S_mc_app_wdf_end       ),
        .I_mc_app_wdf_mask      ( S_mc_app_wdf_mask      ),
        .I_mc_app_wdf_wren      ( S_mc_app_wdf_wren      ),
        .O_mc_app_rd_data       ( S_mc_app_rd_data       ),
        .O_mc_app_rd_data_end   ( S_mc_app_rd_data_end   ),
        .O_mc_app_rd_data_valid ( S_mc_app_rd_data_valid ),
        .O_mc_app_rdy           ( S_mc_app_rdy           ),
        .O_mc_app_wdf_rdy       ( S_mc_app_wdf_rdy       ),

        .ddr_addr               ( ddr_addr               ),
        .ddr_ba                 ( ddr_ba                 ),
        .ddr_cke                ( ddr_cke                ),
        .ddr_odt                ( ddr_odt                ),
        .ddr_cs_n               ( ddr_cs_n               ),
        .ddr_ras_n              ( ddr_ras_n              ),
        .ddr_cas_n              ( ddr_cas_n              ),
        .ddr_we_n               ( ddr_we_n               ),
        .ddr_ck_p               ( ddr_ck_p               ),
        .ddr_ck_n               ( ddr_ck_n               ),
        .ddr_dm                 ( ddr_dm                 ),
        .ddr_dq                 ( ddr_dq                 ),
        .ddr_dqs_p              ( ddr_dqs_p              ),
        .ddr_dqs_n              ( ddr_dqs_n              )
    );



    uivtc #(
        .H_ActiveSize ( 1280 ),
        .H_FrameSize  ( 1650 ),
        .H_SyncStart  ( 1390 ),
        .H_SyncEnd    ( 1430 ),
        .V_ActiveSize ( 720 ),
        .V_FrameSize  ( 750 ),
        .V_SyncStart  ( 725 ),
        .V_SyncEnd    ( 730 )
    )u_hdmi_vtc(
        .I_vtc_rstn    ( S_hdmi_rst_n    ),
        .I_vtc_clk     ( S_hdmi_pixel_clk ),
        .O_vtc_vs      ( S_hdmi_vsync     ),
        .O_vtc_hs      ( S_hdmi_hsync     ),
        .O_vtc_de_valid( S_hdmi_de        ),
        .O_vtc_user    ( S_hdmi_user      ),
        .O_vtc_last    ( S_hdmi_last      )
    );

    hdmi_mixer #(
        .H_OFFSET   ( 0    ),
        .V_OFFSET   ( 0    ),
        .IMG_WIDTH  ( 1280 ),
        .IMG_HEIGHT ( 720 ),
        .DEBUG_MODE ( 0    ),
        .ENABLE_OSD ( 1    )
    )u_hdmi_mixer(
        .I_clk           ( S_hdmi_pixel_clk   ),
        .I_rst_n         ( S_hdmi_rst_n       ),
        .I_video_vsync   ( S_hdmi_vsync       ),
        .I_video_hsync   ( S_hdmi_hsync       ),
        .I_video_de      ( S_hdmi_de          ),
        .I_video_user    ( S_hdmi_user        ),
        .I_video_last    ( S_hdmi_last        ),
        .I_debug_status  ( S_hdmi_debug_status),
        .I_algo_mode     ( S_algo_mode        ),
        .I_edge_threshold( S_edge_threshold),
        .I_ae_target_level(S_ae_level_hdmi_sync2),
        .I_ae_value(S_sw2_hdmi_sync2[0] ? S_ae : S_ag),
        .I_ae_mode(S_sw2_hdmi_sync2[0]),
        .I_tracking_mode(S_sw3_hdmi_sync2),
        .I_osd_enable(S_sw4_hdmi_sync2),
        .I_capture_frame_id(S_capture_frame_id_hdmi),
        .I_display_frame_id(S_display_frame_id_hdmi),
        .I_target_valid  ( S_target_valid_hdmi),
        .I_target_x_min  ( S_target_x_min_hdmi),
        .I_target_y_min  ( S_target_y_min_hdmi),
        .I_target_x_max  ( S_target_x_max_hdmi),
        .I_target_y_max  ( S_target_y_max_hdmi),
        .I_target_center_x(S_target_center_x_hdmi),
        .I_target_center_y(S_target_center_y_hdmi),
        .I_motion_count  ( S_motion_count_hdmi),
        .I_motion_valid  ( S_motion_valid_hdmi),
        .I_motion_x_min  ( S_motion_x_min_hdmi),
        .I_motion_y_min  ( S_motion_y_min_hdmi),
        .I_motion_x_max  ( S_motion_x_max_hdmi),
        .I_motion_y_max  ( S_motion_y_max_hdmi),
        .I_hand_enable   ( S_sw1_hdmi_sync2 && S_sw3_hdmi_sync2),
        .I_hand_count    ( S_hand_count_hdmi),
        .I_hand_valid    ( S_hand_valid_hdmi),
        .I_hand_error    ( S_hand_error_hdmi),
        .O_video_rd_en   ( S_hdmi_window_rd_en),
        .I_video_rd_data ( S_video_rd_data    ),
        .O_hdmi_vsync    ( S_hdmi_out_vsync   ),
        .O_hdmi_hsync    ( S_hdmi_out_hsync   ),
        .O_hdmi_de       ( S_hdmi_out_de      ),
        .O_hdmi_data     ( S_hdmi_out_data    )
    );

    hdmi_tx u_hdmi_tx(
        .I_pixel_clk        ( S_hdmi_pixel_clk  ),
        .I_serial_clk       ( S_hdmi_serial_clk ),
        .I_rst              ( ~S_hdmi_rst_n     ),
        .I_key_in           ( 1'b0              ),
        .I_edid_read_trig   ( 1'b0              ),
        .O_edid_read_valid  (                   ),
        .O_edid_read_data   (                   ),
        .I_video_rgb_enable ( 1'b1              ),
        .I_video_in_vs      ( S_hdmi_out_vsync  ),
        .I_video_in_de      ( S_hdmi_out_de     ),
        .I_video_in_user    ( 1'b0              ),
        .I_video_in_valid   ( 1'b0              ),
        .I_video_in_last    ( 1'b0              ),
        .O_video_in_ready   (                   ),
        .I_video_in_data    ( S_hdmi_out_data   ),
        .I_audio_valid      ( 1'b0              ),
        .I_audio_left_data  ( 24'd0             ),
        .I_audio_right_data ( 24'd0             ),
        .I_i2s_BCLK         ( 1'b0              ),
        .I_i2s_LRCK         ( 1'b0              ),
        .I_i2s_DOUT         ( 1'b0              ),
        .O_ddc_scl          (                   ),
        .O_hdmi_clk_p       (                   ),
        .O_hdmi_tx_p        (                   ),
        .O_tmds_ch0_p       ( O_tmds_ch0_p      ),
        .O_tmds_ch1_p       ( O_tmds_ch1_p      ),
        .O_tmds_ch2_p       ( O_tmds_ch2_p      ),
        .O_tmds_clk_p       ( O_tmds_clk_p      )
    );


/////////////////////////////

    
endmodule
