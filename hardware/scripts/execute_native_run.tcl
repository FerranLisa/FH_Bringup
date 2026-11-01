# Execute a Vivado-generated native run without the Windows Script Host wrapper.
set root [file normalize [file join [file dirname [info script]] ..]]
source [file join $root scripts vivado_local_bootstrap.tcl]
# Each native run is a separate process: the preparation process's setting
# does not propagate here. Enable parallel work in the actual build process.
set_param general.maxThreads 8
set run [lindex $argv 0]
if {$run ni {synth_1 impl_1}} {error "Expected synth_1 or impl_1"}
cd [file join $root FH_Carrier_Bringup.runs $run]
if {[catch {source FH_Carrier_Bringup_top.tcl} problem]} {
    puts stderr $problem
    puts stderr $::errorInfo
    exit 1
}
exit 0
