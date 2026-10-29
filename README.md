# FH Bring-up — v24 consolidated workspace

Vivado/Vitis **2025.2**, Puzhi ZU7EV carrier, GMAX3412 emulator and PL DDR4 rolling buffer. Consolidated on 29 October 2026 from the existing VIVADO and VITIS projects. The original folders were left intact.

## Open the projects

- **Vivado:** open `hardware/FH_Carrier_Bringup.xpr`.
- **Vitis:** select `C:\Projects\FH_Bringup\software` as the workspace. It contains `FH_Carrier_platform` and `FH_Carrier_Test`.
- **Application source to edit:** `software/FH_Carrier_Test/src/BringupTest.c`.
- **Application linker script:** `software/FH_Carrier_Test/src/lscript.ld`.

The application and platform retain their component names so existing debug configurations remain usable. Launch configuration paths now point into this workspace. The selected XSA is the v24 PL-DDR export. A hardware debug launch programs the board; no hardware launch was performed during consolidation.

## Structure

| Location | Purpose |
|---|---|
| `hardware/FH_Carrier_Bringup.srcs/` | Native Vivado block design, HDL and constraints |
| `hardware/ip/` | Reusable emulator, capture, scheduler and PL-ring IP |
| `hardware/scripts/` | Native Vivado build, IP packaging, simulation and validation helpers |
| `hardware/audit/` | Vendor pinout, address baseline and recorded hardware-test evidence |
| `hardware/exports/gmax3412_pl_ddr/` | Working hardware/software exports; rebuilt outputs may replace these |
| `software/` | Vitis workspace, authoritative application source, platform and BSP |
| `scripts/` | Top-level build and validation entry points |
| `tests/rtl/` | Existing simulation testbenches and host regression harness |
| `tests/support/` | Ring-code fixture checked against the current application before host testing |
| `artifacts/v24-tested/` | Preserved original v24 exports, checkpoints, reports, ELF and build evidence |
| `docs/` | Consolidation report, provenance and SHA-256 manifests |

Native Vivado names and its internal script layout are retained to avoid fragile rewrites of tool-managed references. Add future applications as separate Vitis components under `software/`, reusable hardware under `hardware/ip/`, and tests under `tests/`.

GUI build repair (29 October): use global synthesis for `design_1.bd` (`SYNTH_CHECKPOINT_MODE=None`). A clean regeneration must force block-design parameter propagation before generating output products. Otherwise cached validation can produce empty nested SmartConnect/System ILA designs that pass synthesis but fail implementation with `INBB-3`. The build helpers now force validation and check that these nested designs contain internal blocks. `hardware/scripts/rebuild_gui_bitstream.tcl` rebuilds the native project runs; `scripts/execute-native-run.ps1` can execute a generated native run when Windows Script Host is unavailable.

## Build and validate

Run from this directory in PowerShell:

```powershell
.\scripts\validate.ps1
.\scripts\build-software.ps1
.\scripts\build-hardware.ps1
```

`build-software.ps1` compiles the maintained application source against the local BSP, validates its memory layout, and updates the ELF used by the Vitis launch. It does not regenerate the application from v23 or earlier sources. Vitis's normal CMake/Ninja application build is also supported and was tested after relocation.

`build-hardware.ps1` runs full synthesis/implementation and updates the working exports. It does not overwrite `artifacts/v24-tested/`. After a hardware interface change, update/rebuild the Vitis platform before rebuilding the application. The existing helper is:

```powershell
.\hardware\scripts\prepare_vitis_v24.ps1 -ValidateOnly
# When intentionally updating the platform from the working XSA:
.\hardware\scripts\prepare_vitis_v24.ps1
```

The preparation helper preserves application sources and creates a recovery backup outside the Vitis workspace. Its checks deliberately require compatible PS initialization; investigate a mismatch instead of bypassing it. After changing the linker reservation, rebuild software exports before running preparation checks.

AMD tools are expected at `C:\AMDDesignTools\2025.2`. Tool-managed Vitis metadata contains absolute paths to this consolidated location. Moving the workspace again requires another path migration or platform regeneration.

## Tested hardware results

The original v24 hardware tests cover 4–170 frames in the 4 GiB PL DDR4 bank, wraparound, continuous capture/stop, and the PS-DDR capture path. See `hardware/audit/pl_ddr4/v24_hardware_tests.txt` and `artifacts/v24-tested/VALIDATION.md` for the original evidence and limitations.

Generated Vivado run folders and old GUI caches were not imported. The tested synthesis and routed checkpoints are preserved in `artifacts/v24-tested/` and the working exports. Open a DCP directly to inspect a tested design. To restore completed runs and reports in the project GUI, close Vivado and use `hardware/scripts/sync_v24_gui_results.ps1`; that optional restoration was not run during consolidation. Otherwise rebuild from source.

## Version control and backup

Old v20/v21 backup components, old version-generation chains, obsolete exports, nested Git directories and unrelated historical root scripts were omitted. Required current RTL, receiver logic, BSP/FSBL and validation evidence were retained. The original Git repositories and histories remain in the untouched source folders; no new repository or remote was initialized here.

The root `.gitignore` excludes working build outputs and large release artifacts from a future source repository. **Back up `artifacts/v24-tested/` separately:** Git will not include it by default. `docs/tested-artifact-sha256.json` records its checksums. `docs/copy-manifest.json` records incoming files and hashes before relocation edits; it is provenance, not a final-tree checksum manifest.
