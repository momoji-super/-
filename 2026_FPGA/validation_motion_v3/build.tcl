# Launch with td_commands_prompt.exe; paths are relative to this script.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root validation_motion_v3]
cd [file join $root td_project]
if {[catch {
    import_device ph1_35p.db -package PH1P35MDG324 -speed 3
    open_project camera_720p_v1.al
    elaborate -top design_top_wrapper
    read_adc ../user_source/constraints_source/pin.adc
    read_adc -ip ddr2 -file ../user_source/hdl_source/ph1p35_ddr/ddr2/src/adc/ddr2.adc
    read_sdc camera_to_dsi_display.sdc
    read_sdc -ip ddr2 ../user_source/hdl_source/ph1p35_ddr/ddr2/src/sdc/ddr2.sdc
    read_sdc -ip w128_d512_fifo ../user_source/ip_source/w128_d512_fifo/w128_d512_fifo.tcl
    optimize_rtl
    optimize_gate -packarea $out/camera_motion_v3_gate.area
    legalize_phy_inst
    update_timing
    report_timing_summary -file $out/camera_motion_v3_gate.timing
    export_db $out/camera_motion_v3_gate.db
    source $out/physical_steps.tcl
} result options]} {
    puts stderr "BUILD_FAILED: $result"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "BUILD_MOTION_V3_COMPLETE"
exit 0
