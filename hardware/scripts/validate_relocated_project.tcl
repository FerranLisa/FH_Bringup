set root [file normalize [file join [file dirname [info script]] ..]]
source [file join $root scripts vivado_local_bootstrap.tcl]
if {[catch {
    open_project [file join $root FH_Carrier_Bringup.xpr]
    update_ip_catalog
    foreach f [get_files -of_objects [get_filesets sources_1]] {
        if {![file exists $f]} {error "Missing source: $f"}
    }
    set hook [get_property STEPS.INIT_DESIGN.TCL.POST [get_runs impl_1]]
    if {![file exists $hook]} {error "Missing implementation hook: $hook"}
    open_bd_design [get_files */bd/design_1/design_1.bd]
    validate_bd_design -force
    close_project
    puts "CONSOLIDATED_PROJECT_PASS"
} problem]} {
    puts stderr $problem
    exit 1
}
exit 0
