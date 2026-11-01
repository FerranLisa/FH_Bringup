param([Parameter(Mandatory=$true)][ValidateSet('synth_1','impl_1')][string]$Run,[switch]$RegisterOnly)
$ErrorActionPreference='Stop'
$root=Join-Path (Split-Path $PSScriptRoot -Parent) 'hardware'
$dir=Join-Path $root "FH_Carrier_Bringup.runs/$Run"
Push-Location $dir
try {
    if(!$RegisterOnly) {
        Write-Host "`n=== Native $Run (8-thread limit) ==="
        Write-Host "Log: $dir/direct_run_console.txt"
        $savedPreference=$ErrorActionPreference
        try {
            $ErrorActionPreference='Continue'
            & 'C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat' -mode batch -log FH_Carrier_Bringup_top.vds -messageDb vivado.pb -source "$root/scripts/execute_native_run.tcl" -tclargs $Run 2>&1 | Tee-Object -FilePath direct_run_console.txt
            $exitCode=$LASTEXITCODE
        } finally {$ErrorActionPreference=$savedPreference}
        if($exitCode -ne 0){throw "Native $Run failed (exit $exitCode); see $dir/direct_run_console.txt"}
    }
    $output=if($Run -eq 'synth_1'){'FH_Carrier_Bringup_top.dcp'}else{'FH_Carrier_Bringup_top.bit'}
    if(!(Test-Path -LiteralPath $output)){throw "Expected output missing: $output"}
    $log=Get-Content FH_Carrier_Bringup_top.vds -Raw
    $proof=if($Run -eq 'synth_1'){'Synthesis finished with 0 errors'}else{'Bitgen Completed Successfully'}
    if(!$log.Contains($proof)){throw "Native completion evidence missing: $proof"}
    # Match the native wrapper's process metadata, using this actual completed
    # Vivado process. scripts_only does not create the wrapper's begin marker.
    $journal=Get-Content vivado.jou -Raw
    if($journal -notmatch '# Process ID\s*:\s*(\d+)'){throw 'Native process ID missing'}
    $nativePid=$Matches[1]
    $processXml='<?xml version="1.0"?><ProcessHandle Version="1" Minor="0"><Process Command="vivado.exe" Owner="'+[Security.SecurityElement]::Escape($env:USERNAME)+'" Host="'+[Security.SecurityElement]::Escape($env:COMPUTERNAME)+'" Pid="'+$nativePid+'" /></ProcessHandle>'
    Set-Content -LiteralPath .vivado.begin.rst -Value $processXml
    Copy-Item -LiteralPath FH_Carrier_Bringup_top.vds -Destination runme.log -Force
    New-Item -ItemType File -Path .vivado.end.rst -Force | Out-Null
    Write-Host "NATIVE_RUN_PASS: $Run"
} finally {Pop-Location}
