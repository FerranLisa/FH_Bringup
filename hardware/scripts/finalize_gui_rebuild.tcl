set root [file normalize [file join [file dirname [info script]] ..]]
source [file join $root scripts vivado_local_bootstrap.tcl]
if {[catch {
    open_project [file join $root FH_Carrier_Bringup.xpr]
    set bd [get_files */bd/design_1/design_1.bd]
    puts "GUI_BD_SYNTH_MODE: [get_property SYNTH_CHECKPOINT_MODE $bd]"
    if {[get_property SYNTH_CHECKPOINT_MODE $bd] ne "None"} {error "Global synthesis setting was not persisted"}
    foreach run {synth_1 impl_1} {
        puts "GUI_RUN_STATUS: $run [get_property STATUS [get_runs $run]]"
    }
    if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {error "Synthesis state mismatch"}
    if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {error "Implementation state mismatch"}
    set_property DESCRIPTION {v24 rebuilt from consolidated sources; synthesis passed} [get_runs synth_1]
    set_property DESCRIPTION {v24 fresh GUI-flow rebuild; bitstream and timing passed; board test pending} [get_runs impl_1]
    close_project
    puts "GUI_REBUILD_FINALIZED"
} problem]} {
    puts stderr $problem
    exit 1
}
exit 0
