# Vivado GUI build repair — 29 October 2026

The failed GUI implementation stopped at `opt_design` with four `INBB-3` errors. The nested designs `bd_afc3`, `bd_decf`, `bd_56d7` and `bd_f60c` had no internal logic. Their generated RTL declared `numBlks=0`; regenerating outputs without forcing parameter propagation reproduced the empty designs.

The repair forces `validate_bd_design -force`, saves the block design, regenerates output products and uses global synthesis (`SYNTH_CHECKPOINT_MODE=None`). The regenerated nested designs contain 125, 32, 40 and 12 blocks respectively. Both build helpers now check for empty nested RTL before synthesis. Functional RTL and the tested release artifacts were preserved. DDR layout and routed-address-baseline checks still pass.

The native synthesis and implementation scripts were run again from source. Windows Script Host could not load its settings in the automated execution account, so the same generated scripts were executed directly with Vivado, including all four debug-core child runs. Completion markers were written only after each actual script returned success and its output checkpoint existed. No previous completed run was substituted for the rebuild.

Verified results:

- Synthesis: zero reported black boxes, zero errors and zero critical warnings.
- Design link: zero errors and zero critical warnings.
- The formerly failing initial implementation DRC: zero errors.
- Placement and routing: successful; zero unrouted nets.
- Routed timing report: all user-specified constraints met; WNS +0.273 ns, WHS +0.004 ns, TNS/THS zero.
- Routed DRC report: no errors or critical warnings.

Primary evidence is under `hardware/FH_Carrier_Bringup.runs/impl_1/`, including `FH_Carrier_Bringup_top.vds`, `direct_run_console.txt`, `FH_Carrier_Bringup_top_timing_summary_routed.rpt` and `FH_Carrier_Bringup_top_drc_routed.rpt`. The original failure log is `docs/gui-failure-20261029.log`.

Bitstream generation completed successfully. Reopening the completed implementation and checking timing returned `GUI_BITSTREAM_REBUILD_PASS: WNS=0.273 WHS=0.004`. The native bus-skew report has no violations. This new bitstream has not been tested on the physical board.

Outputs:

- `hardware/FH_Carrier_Bringup.runs/impl_1/FH_Carrier_Bringup_top.bit`
- `hardware/FH_Carrier_Bringup.runs/impl_1/FH_Carrier_Bringup_top.ltx`
- `docs/gui-rebuild-artifacts-sha256.json`

These are fresh build outputs. The historical release under `artifacts/v24-tested/` and the working v24 exports are unchanged. The Vitis launch still uses its existing working-export bitstream; it was not reconfigured or launched by this repair.
