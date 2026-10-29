$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
& "$root/hardware/scripts/build_bringup_v24.ps1" -Workspace "$root/software"
Copy-Item "$root/hardware/exports/gmax3412_pl_ddr/software/BringupTest_v24.elf" "$root/software/FH_Carrier_Test/build/FH_Carrier_Test.elf" -Force
