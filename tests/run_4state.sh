#!/usr/bin/env bash
# 4-state (Icarus) run of the X/Z-sensitive testbenches. Verilator is 2-state, so
# its $isunknown checks (B8) can never fail; this run is the real B8 evidence.
# Usage: tests/run_4state.sh   -> logs/4state/<block>.log, exit 1 on any failure
set -u
cd "$(git rev-parse --show-toplevel)"
mkdir -p logs/4state build/4state; rc=0
for b in top_table top_exhaustive top_cascade; do
  log=logs/4state/$b.log
  if iverilog -g2012 -o build/4state/$b -s tb $(cat tb/$b/files.f) >"$log" 2>&1 \
     && vvp build/4state/$b >>"$log" 2>&1 && grep -q '^PASS' "$log" && ! grep -q 'FAIL' "$log"
  then echo "PASS $b (4-state)"; else echo "FAIL $b (4-state), see $log"; rc=1; fi
done
exit $rc
