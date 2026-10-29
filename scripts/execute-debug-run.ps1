param([Parameter(Mandatory=$true)][string]$RunRoot,[Parameter(Mandatory=$true)][ValidateSet('dbg_hub','ila_rx_d0','ila_rx_d1','ila_rx_words')][string]$Core)
$ErrorActionPreference='Stop'
$root=Join-Path (Split-Path $PSScriptRoot -Parent) 'hardware'
$dir=(Resolve-Path (Join-Path $RunRoot ($Core+'_synth_1'))).Path
if(!$dir.StartsWith((Resolve-Path $root).Path+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Run must be inside consolidated hardware workspace'}
Push-Location $dir
try {
    & 'C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat' -mode batch -log "$Core.vds" -messageDb vivado.pb -source "$root/scripts/execute_debug_run.tcl" -tclargs $dir $Core *> direct_run_console.txt
    if($LASTEXITCODE -ne 0){throw "Debug core failed: $Core"}
    if(!(Test-Path "$Core.dcp")){throw 'Debug checkpoint missing'}
    New-Item -ItemType File -Path .vivado.end.rst -Force | Out-Null
    Write-Host "DEBUG_RUN_PASS: $Core"
} finally {Pop-Location}
