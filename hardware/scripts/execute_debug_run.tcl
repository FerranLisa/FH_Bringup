set root [file normalize [file join [file dirname [info script]] ..]]
source [file join $root scripts vivado_local_bootstrap.tcl]
set dir [file normalize [lindex $argv 0]]
set core [lindex $argv 1]
if {$core ni {dbg_hub ila_rx_d0 ila_rx_d1 ila_rx_words}} {error "Unexpected debug core"}
cd $dir
if {[catch {source ${core}.tcl} problem]} {
    puts stderr $problem
    puts stderr $::errorInfo
    exit 1
}
exit 0
