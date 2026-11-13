# synth/ (Petra)
`synth/run.sh` runs generic Yosys synthesis of `top` (no process target) and writes `synth/report.txt`.
Needs `rtl/` merged (top.v + datapath blocks). Gate set: AND/NAND/OR/NOR/XOR/XNOR/ANDNOT/ORNOT/MUX.

First result (RTL from PRs #8 + #9): 48 cells, longest path 11 cells (s[1] -> aeqb).
TI quotes "75 equivalent gates"; counting differs (our cells include 8 MUXes and the aeqb AND tree), so treat it as a rough comparison.
