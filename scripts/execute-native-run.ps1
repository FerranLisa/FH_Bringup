param([Parameter(Mandatory=$true)][ValidateSet('synth_1','impl_1')][string]$Run)
$ErrorActionPreference='Stop'
$root=Join-Path (Split-Path $PSScriptRoot -Parent) 'hardware'
$dir=Join-Path $root "FH_Carrier_Bringup.runs/$Run"
Push-Location $dir
try {
    & 'C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat' -mode batch -log FH_Carrier_Bringup_top.vds -messageDb vivado.pb -source "$root/scripts/execute_native_run.tcl" -tclargs $Run *> direct_run_console.txt
    if($LASTEXITCODE -ne 0){throw "Native $Run failed; see $dir/direct_run_console.txt"}
    $output=if($Run -eq 'synth_1'){'FH_Carrier_Bringup_top.dcp'}else{'FH_Carrier_Bringup_top.bit'}
    if(!(Test-Path -LiteralPath $output)){throw "Expected output missing: $output"}
    # Same successful completion marker as Vivado's ISEWrap.js, only after the
    # actual native script succeeds. The waiting project run can now advance.
    New-Item -ItemType File -Path .vivado.end.rst -Force | Out-Null
    Write-Host "NATIVE_RUN_PASS: $Run"
} finally {Pop-Location}
