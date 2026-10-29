# Consolidation record — 29 October 2026

The retained baseline is **v24**, the hardware-tested PL-DDR rolling-buffer version. Original projects remain at `C:\Projects\VIVADO\FH_Carrier_Bringup` and `C:\Projects\VITIS\FH_Carrier_Bringup`.

## Changes

- Curated the Vivado source-controlled design, current custom IP, constraints, testbenches and audit evidence; excluded old backups, stale archives and previous milestone export trees.
- Retained the Vitis platform, BSP libraries, hardware initialization, FSBL and application component. Excluded duplicate backup components and old Git directories.
- Replaced operational references to both the original paths and the older `FH_Carrier_Bringup_Linux` paths.
- Made `software/FH_Carrier_Test/src/BringupTest.c` the maintained source. Its initial bytes match the tested v24 source exactly. The application no longer depends on generating v24 by patching v23.
- Added root build/validation entry points and a source/output directory convention.
- Preserved 25 original release files, including BIT/XSA/LTX, synthesis/routed DCPs, ELF, reports and build evidence, with SHA-256 checksums.
- Updated the host regression fixture from the actual v24 application. The previous fragment omitted the upper DMA address-register write added by later source generation. The application itself was not changed. The host test now checks fixture/source agreement before compiling.

## Verification performed

| Check | Result |
|---|---|
| Original incoming files | 5,946 distinct original files rehashed; unchanged |
| Preserved release | 25 files match recorded checksums |
| Vivado 2025.2 project | Opens; registered top-level sources and implementation hook exist |
| Block design | Forced `validate_bd_design -force` completed successfully |
| Direct application build | GCC compile/link with `-Wall -Wextra -Werror` passed |
| Vitis application build | Relocated CMake/Ninja configured, compiled and linked successfully |
| Export consistency | XSA embedded BIT matches; PS/DMA maps and MIG geometry pass |
| Memory/address checks | PL-DDR layout, routed address baseline and ELF reservations pass |
| Host ring regression | Wrap, backpressure, overlap, overrun protection, recovery and injected fault checks pass |

Vivado printed installation-level Tcl Store and unused board-catalog warnings, plus existing interface metadata/user-width warnings. These did not prevent project loading or forced block-design validation. No tool installation or user-profile settings were changed. See `hardware/results/relocation.log` for the complete output.

A full FPGA synthesis/implementation, complete platform/FSBL rebuild, GUI run restoration, RTL simulation suite and new physical-board qualification were **not** performed. The tested hardware checkpoints and binaries were preserved; hardware behavior is supported by the original v24 test evidence, not a new board run.

## Provenance files

- `copy-manifest.json`: source and initial destination paths and incoming SHA-256 hashes. Tests were subsequently moved from the initial hardware directory into `tests/rtl`; this is a migration record, not a live inventory.
- `relocated-files.json`: files whose original paths were rewritten in the initial relocation pass. Subsequent build/test fixes are described above.
- `tested-artifact-sha256.json`: release checksums, checked by `scripts/validate.ps1`.
- `preservation-check.json`: original-file and preserved-release verification counts.
- `validation-output.txt`: final baseline/export/memory validation output.

The original repositories retain their Git history. The consolidated destination has no newly initialized Git repository and no configured remote. Release artifacts are excluded by the supplied root `.gitignore`; retain them in the external backup alongside the originals.
