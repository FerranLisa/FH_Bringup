param([string]$Workspace=(Join-Path $PSScriptRoot '../../software'))
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$bsp=Join-Path $Workspace 'FH_Carrier_platform/export/FH_Carrier_platform/sw/standalone_psu_cortexa53_0'
$out=Join-Path $root 'exports/gmax3412_pl_ddr/software'
$gcc='C:/AMDDesignTools/2025.2/Vitis/gnu/aarch64/nt/aarch64-none/bin/aarch64-none-elf-gcc.exe'
$python='C:/AMDDesignTools/2025.2/tps/win64/python-3.13.0/python.exe'
New-Item -ItemType Directory -Path $out -Force | Out-Null
Copy-Item (Join-Path $Workspace 'FH_Carrier_Test/src/BringupTest.c') (Join-Path $out 'BringupTest_v24.c') -Force
Copy-Item (Join-Path $Workspace 'FH_Carrier_Test/src/lscript.ld') (Join-Path $out 'lscript_v24.ld') -Force
& $gcc -std=gnu11 -DSDT -mcpu=cortex-a53 -Wall -Wextra -Werror -O0 -g3 "-specs=$bsp/Xilinx.spec" -I "$bsp/include" (Join-Path $Workspace 'FH_Carrier_Test/src/BringupTest.c') -o "$out/BringupTest_v24.elf" "-Wl,-T,$out/lscript_v24.ld" "-Wl,-Map,$out/BringupTest_v24.map" "-L$bsp/lib" '-Wl,--start-group' -lxilstandalone -lxiltimer -lxil -lgcc -lc '-Wl,--end-group'
if($LASTEXITCODE -ne 0){throw 'A53 compile/link failed'}
& $python (Join-Path $PSScriptRoot 'verify_gmax3412_pl_ring_elf.py') "$out/BringupTest_v24.elf"
if($LASTEXITCODE -ne 0){throw 'ELF memory validation failed'}
Copy-Item (Join-Path $Workspace 'FH_Carrier_Test/src/dual_stream.h') (Join-Path $out 'dual_stream.h') -Force
Copy-Item (Join-Path $Workspace 'FH_Carrier_Test/src/fh_sensor_control.h') (Join-Path $out 'fh_sensor_control.h') -Force
Copy-Item (Join-Path $Workspace 'FH_Carrier_Test/src/fh_frame_buffer.h') (Join-Path $out 'fh_frame_buffer.h') -Force
$hashes=foreach($name in @('BringupTest_v24.c','dual_stream.h','fh_sensor_control.h','fh_frame_buffer.h','BringupTest_v24.elf','lscript_v24.ld')) {
    $hash=Get-FileHash -LiteralPath (Join-Path $out $name) -Algorithm SHA256
    [pscustomobject]@{File=$name;SHA256=$hash.Hash}
}
$hashes | ConvertTo-Json | Set-Content (Join-Path $out 'SHA256.json') -Encoding utf8
Write-Output 'BRINGUP_V24_BUILD_PASS'

