#!/usr/bin/env bash
# One command: build and run the calculator demo, log to logs/demo/calculator.log.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build logs/demo
iverilog -g2012 -s calculator -o build/calculator.vvp sw/calculator.sv rtl/top.v rtl/datapath/*.v
vvp build/calculator.vvp | tee logs/demo/calculator.log
