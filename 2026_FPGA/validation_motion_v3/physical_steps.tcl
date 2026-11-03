place
update_timing -mode manhattan
report_timing_summary -file $out/camera_motion_v3_place.timing
export_db $out/camera_motion_v3_place.db
route
update_timing -mode final
report_area -io_info -file $out/camera_motion_v3_phy.area
report_timing_status -file $out/camera_motion_v3_phy.ts
report_timing_summary -file $out/camera_motion_v3_pr.timing
check_timing -verbose -file $out/camera_motion_v3_check.timing
report_clock_utilization -file $out/camera_motion_v3_clocks.txt
export_db $out/camera_motion_v3_pr.db
bitgen -bit $out/camera_motion_v3.bit
