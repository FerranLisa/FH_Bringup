param([switch]$SynthesisOnly,[switch]$CheckOnly,[switch]$PlanOnly,[switch]$FullRebuild)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$vivado='C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat'
if(!(Test-Path -LiteralPath $vivado)){throw "Vivado executable missing: $vivado"}
New-Item -ItemType Directory -Force -Path "$root/hardware/results" | Out-Null
if($CheckOnly) {
    foreach($file in @('execute-native-run.ps1')) {
        $tokens=$null;$parseErrors=$null
        [void][System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/$file",[ref]$tokens,[ref]$parseErrors)
        if($parseErrors.Count){throw ($parseErrors | Out-String)}
    }
    & $vivado -mode batch -nolog -nojournal -notrace -source "$root/hardware/scripts/check_build_launch.tcl"
    if($LASTEXITCODE -ne 0){throw "Vivado launch failed: $LASTEXITCODE"}
    Write-Host 'BUILD_LAUNCH_CHECK_PASS: no synthesis or implementation started'
    exit 0
}
function Invoke-Vivado([string]$Script,[string]$Stage,[string[]]$Argument=@()) {
    $opts=@('-mode','batch','-source',"$root/hardware/scripts/$Script",'-log',"$root/hardware/results/$Stage.log",'-journal',"$root/hardware/results/$Stage.jou")
    if($Argument){$opts+=@('-tclargs')+$Argument}
    Write-Host "`n=== $Stage ==="
    Write-Host "Log: $root/hardware/results/${Stage}_console.txt"
    $savedPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        & $vivado @opts 2>&1 | Tee-Object -FilePath "$root/hardware/results/${Stage}_console.txt"
        $exitCode=$LASTEXITCODE
    } finally {$ErrorActionPreference=$savedPreference}
    if($exitCode -ne 0){throw "$Stage failed (exit $exitCode); inspect hardware/results/${Stage}_console.txt"}
}

function Get-InputFingerprint([string[]]$Paths) {
    $lines=foreach($path in ($Paths | Sort-Object -Unique)) {
        if(!(Test-Path -LiteralPath $path)){return ''}
        $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        "$path=$hash"
    }
    $sha=[Security.Cryptography.SHA256]::Create()
    try {return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))))).Replace('-','')}
    finally {$sha.Dispose()}
}
$statePath="$root/hardware/results/build_state.json"
$state=[pscustomobject]@{Schema=1;Preparation='';Export='';ExportOutputs=''}
if(Test-Path -LiteralPath $statePath) {
    try {
        $saved=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if($saved.Schema -eq 1){$state=$saved}
    } catch {Write-Warning 'Build receipt unreadable; preparation/export will be checked again.'}
}
function Save-BuildState {
    $temporary="$statePath.tmp"
    $state | ConvertTo-Json | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $statePath -Force
}
function Get-PreparationFingerprint {
    $paths=@(Get-ChildItem "$root/hardware/ip" -Recurse -File | Where-Object {
        $_.Extension -in '.v','.sv','.vh','.svh','.vhd','.vhdl','.xdc','.tcl','.xml','.mem','.coe','.hex','.dat','.mif'
    } | Select-Object -ExpandProperty FullName)
    $paths+=@(Get-ChildItem "$root/hardware/FH_Carrier_Bringup.srcs/sources_1/new" -File | Select-Object -ExpandProperty FullName)
    $paths+=@('prepare_dual_stream.tcl','integrate_dual_stream.tcl','package_gmax3412_emulator.tcl','package_gmax3412_capture.tcl') | ForEach-Object {"$root/hardware/scripts/$_"}
    return Get-InputFingerprint $paths
}
# Only this build driver's instances share this lock. Native run state is checked too.
$buildLock=$null
try {
    $buildLock=[IO.File]::Open("$root/hardware/results/build-hardware.lock",[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $preparation=Get-PreparationFingerprint
    $needsPreparation=$FullRebuild -or !$preparation -or $state.Preparation -ne $preparation
    if($PlanOnly) {
        if($needsPreparation) {
            Write-Host 'PLAN: refresh packaged IP/module references (changed inputs or no successful preparation receipt).'
            Write-Host 'PLAN: reevaluate native run freshness after preparation; dependent runs may need rebuilding.'
        }
        Invoke-Vivado 'prepare_changed_stage.tcl' 'dual_build_plan' @('plan',([int][bool]$SynthesisOnly).ToString(),([int][bool]$FullRebuild).ToString())
        Write-Host 'PLAN_ONLY_PASS: no preparation, synthesis, implementation or export executed'
        exit 0
    }
    if($needsPreparation) {
        # Check for GUI/native builds before packaging can change project inputs.
        Invoke-Vivado 'prepare_changed_stage.tcl' 'dual_preflight' @('plan',([int][bool]$SynthesisOnly).ToString(),'0')
        Invoke-Vivado 'prepare_dual_stream.tcl' 'dual_prepare'
        # Packaging writes metadata; record the final successful inputs, not the old XML.
        $state.Preparation=Get-PreparationFingerprint
        $state.Export='';$state.ExportOutputs=''
        Save-BuildState
    } else {Write-Host 'SKIP: IP packaging and integration inputs unchanged'}
    $force=[int][bool]$FullRebuild
    $ranSynth=$false;$ranImpl=$false
    while($true) {
        Invoke-Vivado 'prepare_changed_stage.tcl' 'dual_build_plan' @('apply',([int][bool]$SynthesisOnly).ToString(),$force.ToString(),([int]$ranSynth).ToString(),([int]$ranImpl).ToString())
        $force=0
        $action=(Get-Content "$root/hardware/results/next_build_stage.txt" -Raw).Trim()
        if($action -eq 'done'){break}
        if($action -notin @('synth_1','impl_1')){throw "Invalid build action: $action"}
        if(($action -eq 'synth_1' -and $ranSynth) -or ($action -eq 'impl_1' -and $ranImpl)) {
            throw "Completed $action remains stale/incomplete; inspect native logs instead of looping"
        }
        $state.Export='';$state.ExportOutputs='';Save-BuildState
        & "$PSScriptRoot/execute-native-run.ps1" -Run $action
        if($action -eq 'synth_1'){$ranSynth=$true}else{$ranImpl=$true}
    }
    if($SynthesisOnly){Write-Host 'SYNTHESIS_ONLY_PASS: current synthesis retained; implementation/export not run';exit 0}
    $exportInputs=@("$root/hardware/FH_Carrier_Bringup.runs/impl_1/FH_Carrier_Bringup_top.bit",
        "$root/hardware/FH_Carrier_Bringup.runs/impl_1/FH_Carrier_Bringup_top_routed.dcp")
    $exportInputs+=@(Get-ChildItem "$root/hardware/scripts" -File | Where-Object {
        $_.Name -match 'export|finalize|verify'
    } | Select-Object -ExpandProperty FullName)
    $exportKey=Get-InputFingerprint $exportInputs
    $stem="$root/hardware/exports/gmax3412_pl_ddr/FH_Carrier_Bringup_GMAX3412_PL_DDR"
    $outputs=@("$stem.bit","$stem.xsa","$stem.ltx","$root/hardware/exports/gmax3412_pl_ddr/BUILD_COMPLETE.txt")
    $outputKey=Get-InputFingerprint $outputs
    if($exportKey -and $outputKey -and $state.Export -eq $exportKey -and $state.ExportOutputs -eq $outputKey) {
        Write-Host 'SKIP: verified hardware export unchanged'
    } else {
        Invoke-Vivado 'export_gui_hardware.tcl' 'dual_export'
        $state.Export=Get-InputFingerprint $exportInputs
        $state.ExportOutputs=Get-InputFingerprint $outputs
        Save-BuildState
    }
    Write-Host 'HARDWARE_BUILD_PASS: native runs current and hardware exported'
} finally {
    if($buildLock){$buildLock.Dispose()}
}
