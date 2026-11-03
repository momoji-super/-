`include "rgb_area_2_3.v"
`include "target_detect_track.v"
`include "frame_luma_stats.v"

module isp_top (
    input 			axi4s_video_aclk,
    input           hand_analysis_clk,
    input 			I_rst_n			,
    input 			I_tlast			,
    input 			I_tuser			,
    input [39:0] 	I_tdata			,
    input 			I_tvalid		,
    input [9:0] 	I_tdest			,
    input [1:0]     I_diag_mode,
    input [2:0]     I_algo_mode,
    input [7:0]     I_algo_threshold,
    input           I_vivid_enable,
    input           I_hand_enable,
    input           I_luma_ack_toggle,
    output          O_luma_frame_toggle,
    output [7:0]    O_avg_luma,
    output [19:0]   O_highlight_count,
    output          O_target_frame_toggle,
    output          O_target_valid,
    output [10:0]   O_target_x_min,
    output [10:0]   O_target_y_min,
    output [10:0]   O_target_x_max,
    output [10:0]   O_target_y_max,
    output [10:0]   O_target_center_x,
    output [10:0]   O_target_center_y,
    output [11:0]   O_motion_count,
    output          O_motion_valid,
    output [10:0]   O_motion_x_min,
    output [10:0]   O_motion_y_min,
    output [10:0]   O_motion_x_max,
    output [10:0]   O_motion_y_max,
    output          O_hand_frame_toggle,
    output [3:0]    O_hand_count,
    output          O_hand_valid,
    output [3:0]    O_hand_error,
    output          O_hand_present,
    output          O_hand_busy,
    output [127:0] 	O_tdata			,
    output 			O_tlast			,
    output 			O_tuser			,
    output 			O_tvalid		,
    output 			I_tready
);
 
wire         m_aixs_tvalid;  //synthesis keep 
  wire [127:0] m_aixs_tdata;  //synthesis keep 
  wire         m_aixs_tuser;  //synthesis keep 
  wire         m_aixs_tlast;  //synthesis keep 
  wire         m_aixs_tready;  //synthesis keep 
  
  wire [ 95:0] m_aixs_tdata_96;  //synthesis keep 


  wire         awb_O_tlast;  //synthesis keep 
  wire         awb_O_tuser;  //synthesis keep 
  wire [ 95:0] awb_O_tdata;  //synthesis keep 
  wire         awb_O_tvalid;  //synthesis keep 
  wire         awb_O_tready;  //synthesis keep 
  wire [95:0]  algo_O_tdata;
  wire         algo_O_tlast;
  wire         algo_O_tuser;
  wire         algo_O_tvalid;
  wire [11:0]  target_motion_count;

  wire         awb_O_tuser_128;  //synthesis keep 
  wire         awb_O_tlast_128;
  wire         awb_O_tvalid_128;  //synthesis keep 
  wire [127:0] awb_O_tdata_128;  //synthesis keep 

  wire [95:0] awb_pre_data;
  wire awb_pre_valid,awb_pre_user,awb_pre_last;
  reg [95:0] awb_pipe_data;
  reg awb_pipe_valid,awb_pipe_user,awb_pipe_last;
  wire [95:0] scaled_data;
  reg [95:0] red_detect_data_d0,red_detect_data_d1,red_detect_data_d2;
  assign awb_O_tdata=awb_pipe_data;
  assign awb_O_tvalid=awb_pipe_valid;
  assign awb_O_tuser=awb_pipe_user;
  assign awb_O_tlast=awb_pipe_last;
  always @(posedge axi4s_video_aclk or negedge I_rst_n) begin
    if(!I_rst_n) begin
      awb_pipe_data<=0;awb_pipe_valid<=0;awb_pipe_user<=0;awb_pipe_last<=0;
      red_detect_data_d0<=0;red_detect_data_d1<=0;red_detect_data_d2<=0;
    end else begin
      awb_pipe_data<=awb_pre_data;
      awb_pipe_valid<=awb_pre_valid;
      awb_pipe_user<=awb_pre_user;
      awb_pipe_last<=awb_pre_last;
      red_detect_data_d0<=scaled_data;
      red_detect_data_d1<=red_detect_data_d0;
      red_detect_data_d2<=red_detect_data_d1;
    end
  end
  assign awb_O_tready = 1'b1;
  assign O_tdata  = awb_O_tdata_128;
  assign O_tuser  = awb_O_tuser_128    ;
  assign O_tvalid = awb_O_tvalid_128   ;

  wire hand_frame_start;
  wire hand_sample_valid;
  wire hand_sample_skin;
  wire [7:0] hand_sample_x, hand_sample_y;
  wire [3:0] hand_stable_count, hand_raw_count, hand_error;
  wire hand_display_valid, hand_raw_valid, hand_present, hand_done, hand_busy;
  wire hand_camera_waiting;
  wire [7:0] hand_palm_x, hand_palm_y, hand_palm_radius;
  wire [7:0] hand_wrist_x, hand_wrist_y;
  reg hand_result_toggle;
  reg [4:0] hand_publish_delay;
  // Disable clears queued frames and temporal history. Reset release is
  // synchronized independently by hand_pipeline in both clock domains.
  wire hand_arst_n = I_rst_n && I_hand_enable;

  hand_mask_frontend #(.IMG_WIDTH(1280),.IMG_HEIGHT(720),.MIN_SKIN_PIXELS(8)) u_hand_mask_frontend (
    .clk(axi4s_video_aclk), .rst_n(I_rst_n), .enable(I_hand_enable),
    .rgb_data(awb_O_tdata), .valid(awb_O_tvalid),
    .user(awb_O_tuser), .last(awb_O_tlast),
    .frame_start(hand_frame_start), .sample_valid(hand_sample_valid),
    .sample_skin(hand_sample_skin), .sample_x(hand_sample_x), .sample_y(hand_sample_y)
  );

  hand_pipeline #(.WIDTH(160),.HEIGHT(90),.REQUIRE_WRIST(0)) u_hand_pipeline (
    .cam_clk(axi4s_video_aclk), .analysis_clk(hand_analysis_clk), .arst_n(hand_arst_n),
    .frame_start(hand_frame_start), .sample_valid(hand_sample_valid),
    .sample_skin(hand_sample_skin), .sample_x(hand_sample_x), .sample_y(hand_sample_y),
    .stable_count(hand_stable_count), .raw_count(hand_raw_count), .error(hand_error),
    .support(), .display_valid(hand_display_valid), .raw_valid(hand_raw_valid),
    .present(hand_present), .result_done(hand_done), .busy(hand_busy),
    .camera_waiting(hand_camera_waiting), .palm_x(hand_palm_x), .palm_y(hand_palm_y),
    .palm_radius(hand_palm_radius), .wrist_x(hand_wrist_x), .wrist_y(hand_wrist_y),
    .tip0(), .tip1(), .tip2(), .tip3(), .tip4(),
    .analysis_rst_n(), .cam_rst_n()
  );

  always @(posedge hand_analysis_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
      hand_result_toggle <= 1'b0;
      hand_publish_delay <= 5'd0;
    end else begin
      // The vote scanner commits up to eight clocks after analyzer done.
      // Publish only after that data is stable for the HDMI toggle crossing.
      if (hand_done) hand_publish_delay <= 5'd16;
      else if (hand_publish_delay != 0) begin
        hand_publish_delay <= hand_publish_delay - 1'b1;
        if (hand_publish_delay == 1) hand_result_toggle <= ~hand_result_toggle;
      end
    end
  end

  assign O_hand_frame_toggle = hand_result_toggle;
  assign O_hand_count = hand_stable_count;
  assign O_hand_valid = hand_display_valid;
  assign O_hand_error = hand_error;
  assign O_hand_present = hand_present;
  assign O_hand_busy = hand_busy | hand_camera_waiting;
  
  //assign m_aixs_tready = O_tready;
  //assign O_tdata  = m_aixs_tdata;
  //assign O_tlast  = m_aixs_tlast    ;
  //assign O_tuser  = m_aixs_tuser    ;
  //assign O_tvalid = m_aixs_tvalid   ;
 
 
wire [39:0] diag_raw_data;
wire [95:0] diag_rgb_data;
video_stripe_diag #(.RAW_WIDTH(1920),.RGB_WIDTH(1280)) u_video_stripe_diag (
 .clk(axi4s_video_aclk),.rst_n(I_rst_n),.mode(I_diag_mode),
 .raw_data(I_tdata),.raw_valid(I_tvalid),.raw_user(I_tuser),
 .rgb_data(awb_O_tdata),.rgb_valid(awb_O_tvalid),.rgb_user(awb_O_tuser),
 .raw_out(diag_raw_data),.rgb_out(diag_rgb_data)
);
demosaic #(
    .IMG_HEIGHT          (1080),  // 图像高度
    .IMG_WIDTH           (1920),   // 图像宽度
    .data_complete_delay (50  ),
    .BAYER_MODE          ("BGGR")
)
u_demosaic
(
    .I_clk   			(axi4s_video_aclk)	,   // 时钟信号
    .I_rst_n 			(I_rst_n)	,   // 复位信号，低有效
    .axi4s_video_tdata 	(diag_raw_data)	,  // AXI4-Stream视频数据
    .axi4s_video_tdest 	(I_tdest)	,
    .axi4s_video_tlast 	(I_tlast)	,  // 行结束信号
    .axi4s_video_tvalid	(I_tvalid)	,  // 数据有效信号
    .axi4s_video_tuser 	(I_tuser)	,  // 帧开始信号
    .axi4s_video_tready	(I_tready)	,  // 从模块准备好接受数据
    .O_tlast  			(m_aixs_tlast)	,  // 输出行结束信号
    .O_tuser  			(m_aixs_tuser)	,  // 输出帧开始信号
    .O_tdata  			(m_aixs_tdata)	,  // 输出数据
    .O_tvalid 			(m_aixs_tvalid)	,  // 输出数据有效信号
    .O_tready   		(m_aixs_tready)	   // 输出数据准备好信号
);
 
data128_96 u_data128_96 (
    .I_tdata(m_aixs_tdata),
    .O_tdata(m_aixs_tdata_96)
);


wire scaled_valid,scaled_user,scaled_last;
rgb_area_2_3 #(.IN_WIDTH(1920),.IN_HEIGHT(1080)) u_rgb_area_2_3 (
 .clk(axi4s_video_aclk),.rst_n(I_rst_n),
 .I_data(m_aixs_tdata_96),.I_valid(m_aixs_tvalid),
 .I_user(m_aixs_tuser),.I_last(m_aixs_tlast),
 .O_data(scaled_data),.O_valid(scaled_valid),
 .O_user(scaled_user),.O_last(scaled_last)
);

frame_awb #(.IMG_HEIGHT(720),.IMG_WIDTH(1280)) u_awb (
 .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),
 .I_last(scaled_last),.I_user(scaled_user),
 .I_data(scaled_data),.I_valid(scaled_valid),
 .I_update_enable(I_diag_mode==0),
 .O_last(awb_pre_last),.O_user(awb_pre_user),
 .O_data(awb_pre_data),.O_valid(awb_pre_valid)
);
assign m_aixs_tready=1'b1;

target_detect_track #(
    .IMG_WIDTH  (1280),
    .IMG_HEIGHT (720)
) u_target_detect_track (
    .I_clk           (axi4s_video_aclk),
    .I_rst_n         (I_rst_n),
    .I_tdata         (awb_O_tdata),
    .I_red_tdata     (red_detect_data_d2),
    .I_tvalid        (awb_O_tvalid),
    .I_tuser         (awb_O_tuser),
    .I_tlast         (awb_O_tlast),
    .O_frame_toggle  (O_target_frame_toggle),
    .O_target_valid  (O_target_valid),
    .O_x_min         (O_target_x_min),
    .O_y_min         (O_target_y_min),
    .O_x_max         (O_target_x_max),
    .O_y_max         (O_target_y_max),
    .O_center_x      (O_target_center_x),
    .O_center_y      (O_target_center_y),
    .O_motion_count  (target_motion_count),
    .O_motion_valid  (O_motion_valid),
    .O_motion_x_min  (O_motion_x_min),
    .O_motion_y_min  (O_motion_y_min),
    .O_motion_x_max  (O_motion_x_max),
    .O_motion_y_max  (O_motion_y_max)
);

assign O_motion_count = target_motion_count;

frame_luma_stats #(.IMG_WIDTH(1280),.IMG_HEIGHT(720)) u_frame_luma_stats (
    .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),
    .I_tdata(awb_O_tdata),.I_tvalid(awb_O_tvalid && I_diag_mode==0),.I_tuser(awb_O_tuser),
    .I_ack_toggle(I_luma_ack_toggle),.O_frame_toggle(O_luma_frame_toggle),
    .O_avg_luma(O_avg_luma),.O_highlight_count(O_highlight_count)
);

image_algo_switch #(.IMG_WIDTH(1280),.IMG_HEIGHT(720)) u_image_algo_switch (
    .I_clk          (axi4s_video_aclk),
    .I_rst_n        (I_rst_n),
    .I_tdata        (diag_rgb_data),
    .I_tvalid       (awb_O_tvalid),
    .I_tuser        (awb_O_tuser),
    .I_tlast        (awb_O_tlast),
    .I_tready       (),
    .O_tdata        (algo_O_tdata),
    .O_tvalid       (algo_O_tvalid),
    .O_tuser        (algo_O_tuser),
    .O_tlast        (algo_O_tlast),
    .I_algo_mode    (I_algo_mode),
    .I_threshold    (I_algo_threshold),
    .I_vivid_enable (I_vivid_enable)
);

    data_96bit_to_128bit u_data_96bit_to_128bit(
        .I_clk              ( axi4s_video_aclk  ),
        .I_rst_n            ( I_rst_n           ),
	
        .I_96b_frame_start  ( algo_O_tuser	    ),
        .I_96b_valid        ( algo_O_tvalid 		),
        .I_96b_last         ( algo_O_tlast       ),
        .I_96b_data         ( algo_O_tdata		),
	
        .O_128b_frame_start ( awb_O_tuser_128  	),
        .O_128b_valid       ( awb_O_tvalid_128 	),
        .O_128b_last        ( awb_O_tlast_128   ),
        .O_128b_data        ( awb_O_tdata_128  	)
    );

    assign O_tlast = awb_O_tlast_128;


//data96_128 u_data96_128 (
//    .I_tdata(awb_O_tdata),
//    .O_tdata(awb_O_tdata_128)
//);
	
endmodule
