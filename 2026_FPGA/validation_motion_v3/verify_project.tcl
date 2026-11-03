# Verify the standalone project sources and all top-level module bindings.
set root [file normalize [file join [file dirname [info script]] ..]]
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
} result options]} {
    puts stderr "PROJECT_VERIFY_FAILED: $result"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "RELEASE_PROJECT_ELABORATION_PASS"
exit 0
