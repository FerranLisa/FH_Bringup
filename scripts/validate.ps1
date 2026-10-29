$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$python='C:/AMDDesignTools/2025.2/tps/win64/python-3.13.0/python.exe'
$manifest=Get-Content "$root/docs/tested-artifact-sha256.json" -Raw | ConvertFrom-Json
foreach($entry in $manifest.PSObject.Properties){
    if((Get-FileHash -LiteralPath "$root/artifacts/v24-tested/$($entry.Name)" -Algorithm SHA256).Hash -ne $entry.Value){throw "Tested baseline changed: $($entry.Name)"}
}
Write-Host 'TESTED_BASELINE_INTEGRITY_PASS'
& "$root/hardware/scripts/prepare_vitis_v24.ps1" -Workspace "$root/software" -ValidateOnly
foreach($script in @('verify_pl_ddr_layout.py','verify_pl_ddr_handoff_map.py')) {
    & $python "$root/hardware/scripts/$script"
    if($LASTEXITCODE -ne 0){throw "$script failed"}
}
& $python "$root/hardware/scripts/verify_gmax3412_pl_ring_elf.py" "$root/software/FH_Carrier_Test/build/FH_Carrier_Test.elf"
if($LASTEXITCODE -ne 0){throw 'ELF validation failed'}
Write-Host 'CONSOLIDATION_VALIDATION_PASS'
