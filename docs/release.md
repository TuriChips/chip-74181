# 74181 4-bit ALU: release write-up

**Status: DRAFT.** Every row below now has a log from one run on main. Not marked RELEASED until Vera and Sai have reviewed it.

## What this is
The TI 74181 (1970) is a 4-bit ALU on one chip: 16 logic and 16 arithmetic functions, selected by S0–S3 and M (arithmetic functions also take the carry input). It was our Phase 0 dry run: the whole pipeline (spec, RTL, tests, synthesis, demo, write-up) on a chip small enough to check exhaustively. Simulation only; nothing was manufactured.

- Spec: `docs/spec.md` (checked against the TI datasheet SDLS136, spec section 9)
- RTL: `rtl/top.v` plus `rtl/datapath/` (pg, carry, sum blocks)

## Evidence
One `make test` run on main commit `6de6829` (`logs/20261114T020139542877335Z/summary.md`: 8 entries, 8 pass, 0 fail; the random entry includes the gate-level checks). Spec mapping follows `tests/coverage.md`.

| Check | Result | Log |
|-------|--------|-----|
| Block tests: pg (4,096 checks), carry (162), sum (2,592) | 0 mismatches | `logs/20261114T020139542877335Z/pg.log`, `carry.log`, `sum.log` |
| Acceptance 1: `top_exhaustive`, all input combinations vs spec section 3 (28,672 checks) | 0 mismatches | `logs/20261114T020139542877335Z/top_exhaustive.log` |
| Acceptance 2: `top_table`, TI function table and directed B1–B6 (21,249 checks) | 0 mismatches | `logs/20261114T020139542877335Z/top_table.log` |
| Acceptance 3: `top_cascade`, two cascaded chips (131,072 checks) | 0 mismatches | `logs/20261114T020139542877335Z/top_cascade.log` |
| B8, no X/Z: the same three top-level tests re-run in Icarus (4-state). Verilator is 2-state, so only this run can fail the check | 0 mismatches | `logs/20261114T020139542877335Z/4state-top_table.log`, `4state-top_exhaustive.log`, `4state-top_cascade.log` |
| Rook's exhaustive check, all 16,384 combinations vs the reference model | 0 mismatches, 0 X/Z (Icarus) | `logs/20261114T020139542877335Z/random-exhaustive-iverilog.log` |
| Same in Verilator | 0 mismatches (X/Z not meaningful in Verilator) | `logs/20261114T020139542877335Z/random-exhaustive-verilator.log` |
| Rook's cascade check: two cascaded chips, every function, all 4,194,304 input combinations | 0 mismatches | `logs/20261114T020139542877335Z/random-cascade-verilator.log` |
| Gate-level: Rook's exhaustive check on the synthesized netlist `synth/top_gl.v`, all 16,384 combinations (Icarus) | 0 mismatches, 0 X/Z | `logs/20261114T020139542877335Z/random-gl-exhaustive-iverilog.log` |
| Gate-level: cascade check on the netlist, all 4,194,304 combinations (Verilator) | 0 mismatches (X/Z not meaningful in Verilator) | `logs/20261114T020139542877335Z/random-gl-cascade-verilator.log` |
| Reference model self-test | 0 mismatches | `logs/20261114T020139542877335Z/random-ref-selftest.log` |

## Size and speed
Generic Yosys synthesis, no process target (`synth/report.txt`, `synth/yosys.log`, as committed on main at `6de6829`):
- **48 cells** (12 AND, 11 NAND, 8 MUX, 5 OR, 4 XNOR, 4 ORNOT, 3 NOR, 1 ANDNOT)
- **Longest path: 11 cells**, from `s[1]` to `aeqb`

TI quotes "75 equivalent gates". Our count is not comparable one to one (our cells include 8 MUXes and the `aeqb` AND tree), so treat it as a rough comparison only (`synth/README.md`).

## Demo
An 8-bit calculator built from two cascaded 74181s, in simulation. From a fresh clone: `./sw/run_demo.sh`. Output: `logs/demo/calculator.log`.

```
add            25,  17  ->   42  (0x2a)  carry-out=0
add           200, 100  ->   44  (0x2c)  carry-out=1
subtract      100,  58  ->   42  (0x2a)  carry-out=1
subtract        5,   9  ->  252  (0xfc)  carry-out=0
AND           240,  60  ->   48  (0x30)
OR            240,  15  ->  255  (0xff)
XOR           170, 255  ->   85  (0x55)
NOT A          15,   0  ->  240  (0xf0)
```
The demo is a show-and-tell, not a test. Rook checked all 8 lines against plain 8-bit arithmetic (comment on issue #7). On the subtract lines `carry-out=1` means *no borrow*. The tests above are what judge the chip.

## What went wrong along the way
- The first draft of the spec used the wrong equations on pins 15 and 17 (it called them P̄ and Ḡ, which only applies to active-low data). Vera caught it while checking the spec against the datasheet logic diagram (`docs/spec.md` section 9).
- Verification found **no RTL bugs**: the RTL matched the spec on the first run. It did find holes in the safety nets, all fixed before release: chip-74181#15 (the B8 X/Z check could never fail under 2-state Verilator; fixed by the Icarus run), toolchain#3 review (stale random logs could be attached to a new run), toolchain#10 (the chip's toolchain pin was ignored in CI), toolchain#13 (the v0.4 tag's CI actually ran v0.3).

## Not done
- Open-source layout (not planned for this chip).
- Electrical behaviour and the 74182 lookahead chip are out of scope (spec section 1).
