# FH_Bringup

Hardware and software handoff · 1 November 2026. Current capture implementation: **V30**, plus
software-only chronological LUT display. Workspace: `C:\Projects\FH_Bringup`.


## 1. Current state and scope

This is the consolidated FH_Carrier bring-up project for the Puzhi PZ-ZU7EV
(XCZU7EV-FFVC1156-2-I), built with AMD Vivado and Vitis 2025.2 on Windows.
It contains board diagnostics, GMAX3412 emulation, image capture/checking,
AXI DMA, PS-DDR tests, and a stereo rolling buffer in 4 GiB of PL DDR4.

The current main feature is two synchronized emulators, a free-running 250 Hz
capture-slot timer during acquisition, a repeating FULL + R ROI sequence, fixed
exposure, and ordered circular image storage with software-readable metadata.
The latest reported V30 board test passed capture, retained image verification,
and FrameID/TimerPulse retrieval. Physical GMAX3412 stereo capture has NOT been
qualified by these emulator tests.

`docs/DUAL_STREAM.md` contains historical V24–V27 descriptions.
In particular, independent F_FPS/R_FPS scheduling, four separate FULL/ROI rings,
and normal exposure/readout overlap are superseded for menu U. Use this handoff
and current sources for the present behavior.

## 2. Open the existing projects

- Vivado: `hardware/FH_Carrier_Bringup.xpr`.
- Vitis workspace: `software`; existing platform `FH_Carrier_platform`, application
  `FH_Carrier_Test`. Update these components rather than creating another platform.
- Main application: `software/FH_Carrier_Test/src/BringupTest.c`.
- Linker script: `software/FH_Carrier_Test/src/lscript.ld`.
- Tools expected at `C:\AMDDesignTools\2025.2`.

Keep the existing directory layout. Native GUI projects and scripts share the
maintained sources. Some Vitis metadata uses absolute workspace paths; relocation
requires checking those paths and platform/debug configurations.

## 3. Hardware features

### Board integration and diagnostics

The Vivado block design integrates the Zynq UltraScale+ processing system,
AXI interconnect/SmartConnect, GPIO control/status, I2C interfaces, clocks/resets,
PL DDR4 controller, capture DMAs, and debug instrumentation. The application uses
PS I2C0 for EEPROM and PS I2C1 through EMIO for PAC1944. GPIO supports power-good,
sensor sidebands, reset and sensor SPI diagnostics.

Supporting RTL includes I2C I/O buffers, DDR DCI reset handling, GMAX clock probing,
a receiver adapter, and a PCIe reference-clock monitor. The latter divides the
100 MHz reference to 50 MHz and transfers a Gray-coded counter through XPM CDC
logic into the PL domain. Receiver/debug infrastructure is present, but its
presence is not evidence that the physical sensor path meets the V30 tests.

### GMAX3412 emulator and parameter tables

- Two emulator instances with a common stereo trigger and coordinated readout.
- FULL: 4096 x 3072; ROI: 4096 x 1024, starting at sensor row 1024.
- Deterministic 10-bit pixel pattern, sensor-specific seeds, and on-chip checking
  of pixels, lines, checksum and completed/error frame counts.
- Current configuration: 16 channels/pixels per 120 MHz clock, represented by a
  192-bit emulator bus (16 x 12-bit channel slots).
- Capture converts pixels to 16-bit values on a 256-bit AXI stream. DMA stores
  simple row-major little-endian 16-bit pixels; this is not packed 10-bit storage.
- Programmable exposure and line blanking; frame-overhead and trailing-row timing.
  Production tests check 789,504 FULL and 263,168 ROI FV readout cycles with the
  configured line timing. Frame transfer overhead and trailing rows also affect
  the busy interval; FV alone is not a sufficient readiness test.
- Double-banked, 256-entry capture and readout parameter tables. Capture entries
  contain exposure cycles, flash flag, 8-bit analog-gain and 16-bit digital-gain
  fields. Readout entries select FULL/ROI. Software edits the inactive bank;
  commits and mode changes are restricted while active. A length encoding of
  zero represents 256 entries.
- Frame-side parameter snapshots preserve association between settings and image.
- Autonomous FV timing: receiver readiness is acknowledged in advance; missing
  readiness produces a fault instead of delaying FV indefinitely.

### Fixed exposure and 250 Hz slot policy

The controller emits a stereo timer pulse every 4,000 us. R is configurable from
0 through 24: accept one FULL, then R ROI captures, and repeat. Default R=24.

A sensor accepts a pulse only while idle. Pulses during exposure, frame overhead,
pixel readout, line blanking or trailing readout rows are discarded. They are not
queued, delayed, or replayed. Skipped pulses do not advance the parameter-table
sequence. Unexpected exposure extension is a fault, not normal operation.

Default exposure is 1,000 us. The menu accepts 1..35,791,394 us, corresponding to
120 MHz cycle programming. Long exposures skip additional slots. A constant
250 Hz timer does NOT imply 250 captured frames/s. At R=24 and 1 ms exposure,
one tick after each FULL is skipped: 25 captures per 26 slots, approximately
240.38 stereo pairs/s (9.62 FULL + 230.77 ROI).

### Stereo rolling DDR4 storage

| Item | Value |
|---|---|
| Total PL DDR4 aperture | 4 GiB starting at 0x1000000000 |
| Sensor 0 aperture | 0x1000000000..0x107FFFFFFF |
| Sensor 1 aperture | 0x1080000000..0x10FFFFFFFF |
| FULL image size per sensor | 25,165,824 bytes (24 MiB) |
| ROI image size per sensor | 8,388,608 bytes (8 MiB) |
| Allocation overhead | 128 bytes per frame |
| Pixel address within allocation | Allocation base + 64 bytes |
| Metadata capacity | 256 shared stereo entries |

The two apertures are logical partitions of one DDR memory interface, not an
assignment of one physical DDR chip to each sensor. FULL and ROI images are
stored in acquisition order within each aperture. An allocation wraps to its
aperture base when it cannot fit before the end.

Before either DMA overwrites a region, every overlapping old LUT entry is
invalidated. A new entry becomes valid only after both sensors complete the
capture/checking path. A partial stereo pair must never be published.
At most 255 smallest ROI allocations fit in 2 GiB, so 256 metadata entries suffice.
Retention varies with the FULL/ROI mixture and wrap location.

### Frame storage LUT and counters

Each valid stereo entry exposes FrameID, TimerPulse, pixel address, byte count,
FULL/ROI flag and pattern seed. A Valid bit is authoritative; metadata in invalid
slots must not be used. Sensor 1 addresses are sensor 0 addresses plus 2 GiB.

- **FrameID:** 32-bit identity assigned to a capture allocation; preserved across
  acquisition restarts until PL reset. Hardware stops at exhaustion instead of
  reusing IDs. Faulted allocations may not publish an entry.
- **TimerPulse:** 32-bit, one-based count of generated timer pulses within an
  acquisition, including ignored busy pulses. Resets for a new acquisition and
  wraps modulo 2^32. The accepted pulse value is latched, compared between
  sensors, and stored with the frame; it is not the later DMA-completion count.
- Slots are reused circularly. Physical slot order is not chronological order.
- Restarting acquisition clears LUT validity and begins writing at the base.
- Live metadata lookup does not reserve or pin image data against overwrite.

### Key control addresses and version checks

| Block | Base address |
|---|---|
| Sensor 0 emulator | 0xA0030000 |
| Sensor 0 capture GPIO | 0xA0040000 |
| Sensor 0 AXI DMA | 0xA0050000 |
| Legacy PL ring GPIO | 0xA0070000 |
| Sensor 1 emulator | 0xA0080000 |
| Sensor 1 capture GPIO | 0xA0090000 |
| Sensor 1 AXI DMA | 0xA00A0000 |
| Stereo ring GPIO | 0xA00B0000 |

V30 emulator capability register at +0x68 is 0x44530030; stereo ring diagnostic
bank 0 returns 0x3412D030. The older base emulator identity remains 0x34120025.
Emulator +0x90 reports skipped pulses; +0x94 fault; +0xB0/+0xB4 extension counters;
+0xB8 the accepted frame's full 32-bit pulse number.

Stereo GPIO command 6 snapshots a LUT slot; command 7 exits lookup mode.
In lookup mode, diagnostic banks 2/3/5/6/7/8/9/10 return FrameID, address low,
address high, length, flags, sensor 0 seed, sensor 1 seed and TimerPulse.
Serialize all users of this command/status interface. Use the C API rather than
mixing direct GPIO commands with an active software transaction.

## 4. Software features and UART menu

The standalone Cortex-A53 application includes startup diagnostics, interactive
UART control, DDR mapping/cache maintenance, timeout/error handling and DMA
ownership protection. Unresolved DMA ownership blocks further tests until reset.

| Command | Function |
|---|---|
| 1 | Read power-good signals |
| 2 | EEPROM full dump |
| 3 | Read board EUI-48 |
| 4 | PAC1944 identification over PS I2C1/EMIO |
| 5 | PAC1944 rail measurements |
| 6 | Repeat complete startup diagnostics, including clocks |
| 7 | Complete reference-clock diagnostics |
| 8 | FH_Sen4K / GMAX3412-A diagnostics |
| U | V30 stereo FULL + R ROI capture and retained-image verification |
| L | Valid frame LUT inventory, oldest to newest FrameID |
| R | External reset test |
| H / ESC | Show menu / exit |

The supported main menu no longer exposes historical single-stream tests
`9`, `D`, `T`, `Q`, `S`, `B`, or `P`; their old command keys fall through to
Unknown command. Legacy implementations and shared helpers remain in the source
for reference, and the associated RTL is unchanged. Command 8 is a separate
physical-sensor diagnostic submenu; its local keys are not the removed main-menu
tests and do not run the V30 emulator acquisition.

For U, enter R, exposure and duration; duration 0 means continuous acquisition.
ESC requests stop, after which the controller drains work and software verifies
all retained image pixels by FrameID. Reports include FULL/ROI pair totals,
elapsed time, timer pulses, skipped ticks and extension counters for each sensor.
Only retained images are CPU-verified; overwritten images cannot be rechecked.

L requires stopped acquisition for a stable inventory. It filters Valid entries,
sorts by FrameID (which does not wrap), and prints chronological Index, physical
Slot, FrameID, TimerPulse, type, both DDR addresses and bytes per sensor. It also
prints retained count and oldest/newest IDs. It is non-destructive: displaying a
frame does not pop it or invalidate its storage. Invalid slots are omitted.

### Public frame access API

Declared in `software/FH_Carrier_Test/src/fh_frame_buffer.h` and implemented in
`dual_stream.h`, included by BringupTest.c:

```c
FhFrameAddress frame;
if (fh_frame_read_slot(slot, sensor, &frame)) {
    /* slot 0..255; sensor 0 or 1; frame.Addr points to pixels. */
}
if (fh_frame_lookup(frame_id, sensor, &frame)) {
    /* Valid retained frame; inspect Bytes, ROI, TimerPulse and Seed. */
}
```

A zero return means invalid, unavailable, or an invalid argument. Do not use the
returned address on failure. Serialize access. During active acquisition, look
up again after copying and discard the copy if the frame/address is no longer
valid. Guaranteed retention while reading would require a new locking/pinning
protocol; this is not implemented.

`fh_sensor_control.h` provides shared SPI write, gain and ROI helpers plus
parameter-LUT write/commit helpers. Physical sensor SPI requires configured PL,
proper power/reset/clock and exclusive GPIO ownership. Helpers do not imply
automatic per-frame SPI programming or validated physical capture. The FSBL and
platform sources are retained in the existing Vitis workspace.

## 5. Maintained source locations

| Path | Responsibility |
|---|---|
| hardware/ip/gmax3412_emulator/hdl | Emulator, sequence/tables, pattern/timing/checker |
| hardware/ip/gmax3412_capture/hdl | Capture, stream conversion and buffering |
| hardware/ip/gmax3412_scheduler | Legacy autonomous scheduler |
| hardware/ip/gmax3412_pl_ring | Legacy PL rolling-buffer controller |
| hardware/FH_Carrier_Bringup.srcs/sources_1/new/gmax3412_dual_ring.v | Stereo timer, DMA controller, circular allocation and LUT |
| hardware/FH_Carrier_Bringup.srcs/sources_1/bd/design_1/design_1.bd | Native system integration |
| hardware/FH_Carrier_Bringup.srcs/constrs_1/new | Board and implementation constraints |
| software/FH_Carrier_Test/src/dual_stream.h | U/L, frame lookup and verification |
| tests/rtl | RTL regression testbenches |
| hardware/scripts | IP packaging, integration, simulation, export and validation |
| hardware/results | Build/simulation logs and checked checkpoint |
| artifacts/v24-tested | Historical baseline; not the current V30 release |

## 6. Build, simulate and export

Run from PowerShell. Close conflicting GUI builds before running scripts.

```powershell
Set-Location C:\Projects\FH_Bringup
# Software only; compile/link, ELF layout checks, update launch ELF:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build-software.ps1
# Simulations only:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/verify-fixed-exposure.ps1 -SimulationOnly
# Simulations followed by synthesis, NO implementation/export:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/verify-fixed-exposure.ps1
# Plan build without performing the selected build stages:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build-hardware.ps1 -PlanOnly
# Full hardware build, timing/DRC/methodology checks and XSA export:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build-hardware.ps1
```

The hardware driver fingerprints preparation inputs and reuses completed current
runs. `-SynthesisOnly`, `-CheckOnly`, `-PlanOnly` and `-FullRebuild` are supported.
A failed/interrupted implementation may restart that run; do not assume each
individual placement/routing substage resumes. General Vivado thread limit is
configured to 8. Native-run helpers support environments where the generated
Windows run launcher is unreliable.

The software script retains historical filenames such as `BringupTest_v24.elf`;
it compiles current sources, not a V24 source snapshot. The launch ELF is
`software/FH_Carrier_Test/build/FH_Carrier_Test.elf`. GUI CMake/Ninja builds use the
same maintained application source. GUI hardware rebuilds must refresh packaged
IP/output products after RTL changes; use the maintained preparation flow rather
than reusing stale generated files. The block design uses global synthesis.

### Current deliverables

Working export stem:
`hardware/exports/gmax3412_pl_ddr/FH_Carrier_Bringup_GMAX3412_PL_DDR`
with `.bit`, `.ltx` and `.xsa` files. Update the existing Vitis platform hardware
specification with this XSA, rebuild platform/application, and ensure the debug
launch programs the matching bitstream. Do not assume
`hardware/FH_Carrier_Bringup_top.xsa` is automatically updated by these scripts.

### PCIe constraint correction and checked-checkpoint export

The fresh V30 implementation generated a bitstream but its normal export was
blocked by TIMING-6/7. Both a custom alias and native `pcie_refclk_odiv2` existed
on the same ODIV2 pin. The final fix uses the native name with explicit /2 and
keeps the PCIe clock family asynchronous to clk_pl_0. The Gray CDC bus has a
10 ns skew constraint. Do not suppress methodology failures to obtain an XSA.

The successful recovery flow was:

```powershell
& C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat -mode batch -notrace `
  -source C:\Projects\FH_Bringup\hardware\scripts\fix_pcie_native_clock.tcl `
  -log C:\Projects\FH_Bringup\hardware\results\pcie_clock_fix.log `
  -journal C:\Projects\FH_Bringup\hardware\results\pcie_clock_fix.jou
& C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat -mode batch -notrace `
  -source C:\Projects\FH_Bringup\hardware\scripts\export_pcie_checked.tcl `
  -log C:\Projects\FH_Bringup\hardware\results\pcie_checked_export.log `
  -journal C:\Projects\FH_Bringup\hardware\results\pcie_checked_export.jou
```

The fix validates the existing route, updates source XDC, saves
`hardware/results/FH_Carrier_Bringup_pcie_checked.dcp`, reopens it, and checks the
clock duplication does not recur. The export checks that checkpoint again,
generates BIT/LTX, creates the XSA and verifies the embedded BIT matches delivery.
Neither step performs placement/routing. Checkpoint writing can take minutes.
Do not substitute an old checked checkpoint after design changes.

This recovery does not mark the original native impl_1 run current after an XDC
change. The next normal build may legitimately rebuild implementation. The final
native-name source correction passed checkpoint-reload validation; a subsequent
fresh implementation with it remains a separate validation step.

Historical export text still labels BUILD_COMPLETE.txt as V28 and says board test
pending. That text is stale: use the V30 capability IDs, actual logs and the board
evidence below. Do not identify firmware by a legacy filename or label alone.

## 7. Verification evidence at handoff

### Simulation/software

The V30 regression passed 11 cases: parameter tables, AXI control, production-size
sensor timing, five normal stereo configurations, two fault cases and one stereo
pulse-counter rollover case. Normal configurations cover R=0/1/24 at 1 ms and
R=1 at 4/9 ms exposure. Tests check exact pulses, busy-slot accounting, no exposure
extension, metadata association, stereo publication, DDR wrapping/overlap
invalidation, retained pixels, FrameID exhaustion and DMA fault handling.

The stereo DDR simulations use reduced geometry/time scaling for runtime. The
separate sensor timing test uses production 4096-wide FULL/ROI geometry. Rollover
tests seed counters near their maximum; they are not 199-day endurance tests.
Current software compiled with -Wall -Wextra -Werror and passed ELF memory-layout
checks. The final chronological L change was software-only and rebuilt successfully.

### Synthesis/implementation/export, 31 October 2026

- Synthesis completed at 11:58:36. LUTs 42.52%, registers 30.02%, BRAM 49.04%,
  DSPs 0.75% (synthesis utilization, not a guarantee of future timing).
- V30 route: 222,963 routable nets fully routed, zero routing errors.
- Corrected checkpoint: WNS +0.274 ns, WHS +0.010 ns.
- Final checked export completed at 15:36:41 with PCIE_CHECKED_EXPORT_PASS.
- Embedded BIT and delivered BIT matched; DDR map/MIG checks passed.
- Original pre-correction implementation/export logs and failed backup logs are
  retained. Distinguish those from the final passing checked-checkpoint reports.

### Reported V30 board run

R=24, exposure=1,000 us, approximately ten seconds:

| Metric | Result |
|---|---|
| Timer pulses | 2,501 |
| Stored stereo pairs | 2,404 = 97 FULL + 2,307 ROI |
| Busy ticks skipped | 97 per sensor |
| Exposure extensions | 0 on both sensors |
| Retained frames verified | 235 per sensor |
| Retained FrameIDs | 2169..2403 |

Example: FULL FrameID 2325 has TimerPulse 2419; pulse 2420 is skipped and ROI
FrameID 2326 has pulse 2421. Buffer wrap is visible at FrameID 2360 returning to
sensor 0 pixel address 0x1000000040. This demonstrates the required timer-gap
metadata and ordered storage on hardware. The user subsequently confirmed that
L lists only valid entries. Physical exposure duration was not independently
measured on a real sensor in this test.

## 8. Remaining limits and resumption checklist

- Current stereo tests validate emulators and DDR storage, not real sub-LVDS
  sensor acquisition, pixel deserialization/reordering, or physical IR timing.
- Gain/flash parameter fields and SPI helpers do not establish full automatic
  per-frame physical sensor/illuminator control.
- No frame pinning, destructive consumer FIFO or guaranteed concurrent image
  read ownership is implemented. Validity can expire while software reads.
- L is a stopped-acquisition snapshot; the complete multi-entry table is not
  atomically snapshotted during live capture.
- Full-rate trigger generation and fixed exposure intentionally sacrifice slots.
  Do not restore overlap to force an apparent 250 captured frames/s.
- Old V24/V28 passes are historical and do not replace tests on current hardware.
- At resumption, confirm V30 IDs and matching BIT/XSA/ELF, run U then L, inspect
  zero extensions, timer accounting, pixel verification and TimerPulse gaps.
- Repeat simulations after RTL/metadata changes; resynthesize and implement before
  exporting changed hardware. Pure UART-display changes need a software rebuild
  and board check, not a new FPGA bitstream.
- Preserve source plus the final BIT/XSA/LTX/ELF, checked DCP, reports and logs.
  Generated outputs and historical artifacts may be excluded by .gitignore;
  a source-only Git backup is not a full hardware handoff backup.

