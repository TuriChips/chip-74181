#!/usr/bin/env bash
# Beru's exhaustive comparison: RTL vs ref model, all 16,384 inputs, in two simulators,
# plus the B7 two-chip cascade on all 2^22 inputs (Verilator), and the same checks on the
# synthesized netlists synth/top_gl.v and synth/sky130/top_sky130.v when they exist.
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
# Gate level: the synthesized netlist (Petra, synth/top_gl.v) against the same vectors.
# Icarus for the 16,384 single-chip cases (4-state), Verilator for the 2^22 cascade.
# Skipped, and reported as SKIP rather than PASS, when there is no netlist.
GL=synth/top_gl.v
if [ -f "$GL" ]; then
  mkdir -p build/random/gl
  printf '%s\ntests/random/exhaustive/tb.sv\n' "$GL" > build/random/gl/exhaustive.f
  printf '%s\ntests/random/cascade/tb.sv\n'    "$GL" > build/random/gl/cascade.f
  step gl-exhaustive-iverilog "$run/random-gl-exhaustive-iverilog.log" bash -c \
    'iverilog -g2012 -o build/random/gl/iv.vvp -c build/random/gl/exhaustive.f && vvp -n build/random/gl/iv.vvp'
  step gl-cascade-verilator "$run/random-gl-cascade-verilator.log" bash -c \
    'verilator --binary --timing -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL --Mdir build/random/gl/vlc -f build/random/gl/cascade.f --top tb && build/random/gl/vlc/Vtb'
else
  echo "SKIP gate-level (no $GL)"
fi
# Gate level, sky130: Leo's mapped netlist synth/sky130/top_sky130.v (the routed DEF has the same
# 44 cells and nets) with the PDK's functional cell models, zero delay. Icarus for both runs:
# Verilator can't run the PDK's table UDPs (udp_mux_2to1, used by mux2/mux2i), and --bbox-unsup
# silently turns them into black boxes, which gives false mismatches.
# Needs PDK_ROOT (source <toolchain>/scripts/eda-env.sh). SKIP, not PASS, if the netlist or PDK is missing.
SKY=synth/sky130/top_sky130.v
CELLS="${PDK_ROOT:-/nonexistent}/sky130A/libs.ref/sky130_fd_sc_hd/verilog"
if [ -f "$SKY" ] && [ -f "$CELLS/sky130_fd_sc_hd.v" ]; then
  mkdir -p build/random/sky
  for t in exhaustive cascade; do
    printf '%s\n' "$CELLS/primitives.v" "$CELLS/sky130_fd_sc_hd.v" "$SKY" "tests/random/$t/tb.sv" > build/random/sky/$t.f
    step "gl-sky130-$t-iverilog" "$run/random-gl-sky130-$t-iverilog.log" bash -c \
      "iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY= -o build/random/sky/$t.vvp -c build/random/sky/$t.f && vvp -n build/random/sky/$t.vvp"
  done
else
  echo "SKIP gate-level sky130 (need $SKY and PDK_ROOT with sky130A cell models)"
fi
exit $ok
