# synth/ (Petra)
`synth/run.sh` runs generic Yosys synthesis of `top` (no process target) and writes `synth/report.txt`.
Needs `rtl/` merged (top.v + datapath blocks). Gate set: AND/NAND/OR/NOR/XOR/XNOR/ANDNOT/ORNOT/MUX.

First result (RTL from PRs #8 + #9): 48 cells, longest path 11 cells (s[1] -> aeqb).
TI quotes "75 equivalent gates"; counting differs (our cells include 8 MUXes and the aeqb AND tree), so treat it as a rough comparison.

## sky130 layout (Leo)
`synth/sky130/run.sh` runs the whole flow (needs `source <toolchain>/scripts/eda-env.sh`): Yosys maps `top` to `sky130_fd_sc_hd` (typical corner, `lpflow_*`/probe/delay cells filtered out by `filter_lib.py`), OpenROAD places and routes (`flow.tcl`), KLayout writes `top.gds` and `layout.png`.
Tools: OpenROAD 2.0_3175 (2022 build), KLayout 0.30.13, sky130A PDK 1.0.471 (pins in toolchain `VERSIONS`).

| Item | Result | Log |
|------|--------|-----|
| Cells after mapping | 44 (generic Yosys: 48) | `sky130/logs/stat.txt` |
| Cell area | 295.3 µm² | `sky130/logs/stat.txt` |
| Floorplan | 37.17 × 37.17 µm die, 40% target, 46% actual after 5 tap cells (302 µm² placed), core 26.7 × 24.5 µm | `sky130/logs/openroad.log` |
| Routed wire length | 968 µm, 356 vias, layers li1 to met4 | `sky130/logs/openroad.log` |
| Longest path (typical corner, unconstrained) | 1.014 ns, b[0] → aeqb, 6 cells | `sky130/logs/openroad.log` |
| Router DRC violations | 0 | `sky130/logs/route_drc.rpt` |

Not done: timing closure, power, signoff DRC (KLayout/Magic) and LVS. The router's own DRC count is not a signoff. Power is met1 rails plus met4 straps, with 5 `tapvpwrvgnd_1` tap cells (physical only, not in `top_sky130.v`), no fill or decap; fine for a picture and a first run, not for fabrication.
The mapped netlist `sky130/top_sky130.v` passes the gate-level check against the reference model, using the pinned PDK functional cell models in Icarus: all 16,384 inputs (`cases=16384 mismatches=0 xz=0`, `logs/20261114T091952Z/random-gl-sky130-exhaustive-iverilog.log`) and the two-chip cascade over all 4,194,304 inputs (`mismatches=0 xz=0`, `logs/20261114T091952Z/random-gl-sky130-cascade-iverilog.log`). Tap cells are physical only, so they do not change this result.
