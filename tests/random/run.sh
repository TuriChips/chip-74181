#!/usr/bin/env bash
# Rook's exhaustive comparison: RTL vs ref model, all 16,384 inputs, in two simulators.
#   Verilator (2-state, same flags as the toolchain) and Icarus (4-state, so B8's X/Z check is real).
# Usage: tests/random/run.sh      Logs: logs/<run>/random-*.log  (logs/latest -> run)
set -u
cd "$(git rev-parse --show-toplevel)"
run="logs/$(date -u +%Y%m%dT%H%M%SZ)"; mkdir -p "$run" build/random
ok=0
step() { # name log cmd...
  local name=$1 log=$2; shift 2
  if "$@" >"$log" 2>&1 && grep -q '^PASS' "$log" && ! grep -q 'FAIL' "$log"; then echo "PASS $name"
  else echo "FAIL $name ($log)"; ok=1; fi
}
step ref-selftest "$run/random-ref-selftest.log" python3 ref/ref74181.py selftest
python3 ref/ref74181.py vectors build/random/expected.hex || { echo "FAIL vector generation"; exit 1; }
step exhaustive-verilator "$run/random-exhaustive-verilator.log" bash -c \
  'verilator --binary --timing -Wall -Wno-DECLFILENAME --Mdir build/random/vl -f tests/random/exhaustive/files.f --top tb && build/random/vl/Vtb'
step exhaustive-iverilog "$run/random-exhaustive-iverilog.log" bash -c \
  'iverilog -g2012 -o build/random/iv.vvp -c tests/random/exhaustive/files.f && vvp -n build/random/iv.vvp'
ln -sfn "$(basename "$run")" logs/latest
exit $ok
