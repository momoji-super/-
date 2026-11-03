module hand_pipeline #(
    parameter WIDTH=160,HEIGHT=120, REQUIRE_WRIST=1
)(
    input wire cam_clk,analysis_clk,arst_n,
    input wire frame_start,sample_valid,sample_skin,
    input wire [7:0] sample_x,sample_y,
    output wire [3:0] stable_count,raw_count,error,support,
    output wire display_valid,raw_valid,present,result_done,busy,camera_waiting,
    output wire [7:0] palm_x,palm_y,palm_radius,wrist_x,wrist_y,
    output wire [6:0] tip0,tip1,tip2,tip3,tip4,
    output wire analysis_rst_n,cam_rst_n
);
    hand_reset_sync u_cam_reset(cam_clk,arst_n,cam_rst_n);
    hand_reset_sync u_analysis_reset(analysis_clk,arst_n,analysis_rst_n);
    wire start;wire [3:0] capture_error;wire [15:0] addr;wire pixel;
    hand_mask_buffer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) u_buffer(
        .cam_clk(cam_clk),
		  .cam_rst_n(cam_rst_n),
		  .frame_start(frame_start),
        .sample_valid(sample_valid),
		  .sample_skin(sample_skin),
		  .sample_x(sample_x),
		  .sample_y(sample_y),
        .analysis_clk(analysis_clk),
		  .analysis_rst_n(analysis_rst_n),
        .read_addr(addr),
		  .read_skin(pixel),
		  .analysis_start(start),
		  .capture_error(capture_error),
        .analysis_done(result_done),
		  .camera_waiting(camera_waiting)
		  );
		  
    hand_distance_circle #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.REQUIRE_WRIST(REQUIRE_WRIST)) u_analyzer(
        .clk(analysis_clk),
		  .rst_n(analysis_rst_n),
		  .start(start),
		  .capture_error(capture_error),
        .mask_addr(addr),
		  .mask_skin(pixel),
		  .busy(busy),
		  .done(result_done),
        .result_valid(raw_valid),
		  .present(present),
		  .count(raw_count),
		  .error(error),
        .palm_x(palm_x),
		  .palm_y(palm_y),
		  .palm_radius(palm_radius),
		  .wrist_x(wrist_x),
		  .wrist_y(wrist_y),
        .tip0(tip0),
		  .tip1(tip1),
		  .tip2(tip2),
		  .tip3(tip3),
		  .tip4(tip4)
			);
			
    hand_temporal_vote u_vote(
		  .clk(analysis_clk),
		  .rst_n(analysis_rst_n),
		  .done(result_done),
        .result_valid(raw_valid),
		  .present(present),
		  .raw_count(raw_count),
		  .palm_x(palm_x),
		  .palm_y(palm_y),
        .count(stable_count),
		  .display_valid(display_valid),
		  .support(support)
		  );
endmodule
