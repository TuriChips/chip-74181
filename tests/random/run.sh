#!/usr/bin/env bash
# Rook's exhaustive comparison: RTL vs ref model, all 16,384 inputs, in two simulators,
# plus the B7 two-chip cascade on all 2^22 inputs (Verilator).
#   Verilator (2-state, same flags as the toolchain) and Icarus (4-state, so B8's X/Z check is real).
# Usage: tests/random/run.sh      Logs: logs/<run>/random-*.log  (logs/latest -> run)
# If RUN_DIR is set (toolchain run_tests.sh), logs go there and logs/latest is left alone.
set -u
cd "$(git rev-parse --show-toplevel)"
run="${RUN_DIR:-logs/$(date -u +%Y%m%dT%H%M%SZ)}"; mkdir -p "$run" build/random
[ -z "${RUN_DIR:-}" ] && ln -sfn "$(basename "$run")" logs/latest
ok=0
step() { # name log cmd...
  local name=$1 log=$2; shift 2
  if "$@" >"$log" 2>&1 && grep -q '^PASS' "$log" && ! grep -q 'FAIL' "$log"; then echo "PASS $name"
  else echo "FAIL $name ($log)"; ok=1; fi
}
step ref-selftest "$run/random-ref-selftest.log" python3 ref/ref74181.py selftest
python3 ref/ref74181.py vectors build/random/expected.hex >"$run/random-vectors.log" 2>&1 \
  || { echo "FAIL vector generation ($run/random-vectors.log)"; exit 1; }
python3 ref/ref74181.py cascade build/random/cascade.hex >>"$run/random-vectors.log" 2>&1 \
  || { echo "FAIL cascade vector generation ($run/random-vectors.log)"; exit 1; }
step exhaustive-verilator "$run/random-exhaustive-verilator.log" bash -c \
  'verilator --binary --timing -Wall -Wno-DECLFILENAME --Mdir build/random/vl -f tests/random/exhaustive/files.f --top tb && build/random/vl/Vtb'
step exhaustive-iverilog "$run/random-exhaustive-iverilog.log" bash -c \
  'iverilog -g2012 -o build/random/iv.vvp -c tests/random/exhaustive/files.f && vvp -n build/random/iv.vvp'
# B7 cascade, 2^22 cases. Verilator only: Icarus takes minutes here, and X/Z is already covered above.
step cascade-verilator "$run/random-cascade-verilator.log" bash -c \
  'verilator --binary --timing -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL --Mdir build/random/vlc -f tests/random/cascade/files.f --top tb && build/random/vlc/Vtb'
exit $ok
