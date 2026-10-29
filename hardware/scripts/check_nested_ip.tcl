# Empty generated subdesigns elaborate without errors, then fail INBB-3.
# Catch that condition before a lengthy synthesis run.
foreach name {design_1_axi_smc_0 design_1_gmax_ddr_smc_0 design_1_pl_ddr_smc_0 design_1_system_ila_0_0} {
    set files [glob -nocomplain [file join $root FH_Carrier_Bringup.gen sources_1 bd design_1 ip $name bd_0 synth bd_*.v]]
    if {[llength $files] != 1} {error "Missing generated nested RTL for $name"}
    set f [open [lindex $files 0] r]
    set rtl [read $f]; close $f
    if {![regexp {numBlks=([0-9]+)} $rtl -> count] || $count == 0} {error "Empty generated nested design: $name"}
    puts "NESTED_IP_PASS: $name blocks=$count"
}
