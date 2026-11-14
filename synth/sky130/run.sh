#!/usr/bin/env bash
# Leo: sky130 flow for top: Yosys map -> OpenROAD place+route -> KLayout GDS + PNG.
# Usage: source <toolchain>/scripts/eda-env.sh; synth/sky130/run.sh   (outputs in synth/sky130/, logs in synth/sky130/logs/)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
D=synth/sky130; mkdir -p $D/logs; W=$(mktemp -d)
S=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd
python3 -I $D/filter_lib.py $S/lib/sky130_fd_sc_hd__tt_025C_1v80.lib $W/f.lib | tee $D/logs/filter_lib.log
yosys -l $D/logs/yosys_full.log -q -p "read_liberty -lib $W/f.lib; read_verilog $(find rtl -name '*.v'|sort|tr '\n' ' ');
 hierarchy -check -top top; synth -flatten -top top; abc -liberty $W/f.lib; opt_clean; check -assert;
 tee -o $D/logs/stat.txt stat -liberty $W/f.lib; write_verilog -noattr -noexpr $D/top_sky130.v"
OUT=$W NETLIST=$D/top_sky130.v LIB=$W/f.lib openroad -no_init -exit $D/flow.tcl 2>&1 | grep -v Nesterov | tee $D/logs/openroad.log
cp $W/top.def $D/top.def; cp $W/route_drc.rpt $D/logs/route_drc.rpt
klayout -b -r $D/render.py -rd def=$D/top.def -rd gds=$D/top.gds -rd png=$D/layout.png -rd pdk=$PDK_ROOT/sky130A 2>&1 | tee $D/logs/klayout.log
echo "DRC (router) violations: $(grep -c violation $D/logs/route_drc.rpt || true)"
