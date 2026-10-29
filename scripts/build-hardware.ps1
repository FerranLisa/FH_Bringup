$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
& "$root/hardware/scripts/run_pl_ddr_build.ps1"
exit $LASTEXITCODE
