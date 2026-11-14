#!/usr/bin/env bash
# 4-state (Icarus) run of the X/Z-sensitive testbenches. Verilator is 2-state, so
# its $isunknown checks (B8) can never fail; this run is the real B8 evidence.
# Usage: tests/run_4state.sh   exit 1 on any failure
# Logs: $RUN_DIR/4state-<tb>.log when RUN_DIR is set (the toolchain's run_tests.sh), else
# build/4state/logs/<tb>.log (untracked), so a local run never dirties the tree or leaves
# stale logs that look like evidence.
set -u
cd "$(git rev-parse --show-toplevel)"
logdir="${RUN_DIR:-build/4state/logs}"; prefix=""; [ -n "${RUN_DIR:-}" ] && prefix="4state-"
mkdir -p "$logdir" build/4state; rc=0
for b in top_table top_exhaustive top_cascade; do
  log=$logdir/$prefix$b.log
  if iverilog -g2012 -o build/4state/$b -s tb $(cat tb/$b/files.f) >"$log" 2>&1 \
     && vvp build/4state/$b >>"$log" 2>&1 && grep -q '^PASS' "$log" && ! grep -q 'FAIL' "$log"
  then echo "PASS $b (4-state)"; else echo "FAIL $b (4-state), see $log"; rc=1; fi
done
exit $rc
