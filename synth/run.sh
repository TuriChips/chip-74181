#!/usr/bin/env bash
# Petra: generic Yosys synthesis of `top` (no process target). Usage: synth/run.sh
# Writes synth/report.txt (Yosys stat + longest path) and prints it.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
SRC=$(find rtl -name '*.v' | sort)
OUT=synth/report.txt
yosys -q -l synth/yosys.log -p "
read_verilog $(echo $SRC);
hierarchy -check -top top;
proc; flatten; opt; techmap; opt; abc -g AND,NAND,OR,NOR,XOR,XNOR,ANDNOT,ORNOT,MUX; opt_clean -purge;
check -assert;
write_verilog -noattr synth/top_gl.v;
tee -o $OUT stat;
tee -a $OUT ltp -noff
"
echo "--- warnings in synth/yosys.log ---"; grep -i warning synth/yosys.log || echo "none"
cat $OUT
