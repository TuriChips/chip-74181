# 74181 4-bit ALU: release write-up

**Status: DRAFT.** Directed tests and acceptance tests 1–3 (Quinn, PR #14) are not on main yet, so this is not a release. Sections marked PENDING get filled in when their logs land. Everything else below links to a log.

## What this is
The TI 74181 (1970) is a 4-bit ALU on one chip: 16 logic and 16 arithmetic functions picked by 5 control pins. It was our Phase 0 dry run: the whole pipeline (spec, RTL, tests, synthesis, demo, write-up) on a chip small enough to check exhaustively. Simulation only; nothing was manufactured.

- Spec: `docs/spec.md` (checked against the TI datasheet SDLS136, spec section 9)
- RTL: `rtl/top.v` plus `rtl/datapath/` (pg, carry, sum blocks)

## Evidence
All runs below are on main commit `56390eb` (`logs/random/main-56390eb/run-info.txt`).

| Check | Result | Log |
|-------|--------|-----|
| Exhaustive, all 16,384 input combinations vs reference model (iverilog) | 0 mismatches, 0 X/Z | `logs/random/main-56390eb/random-exhaustive-iverilog.log` |
| Same, Verilator | 0 mismatches, 0 X/Z | `logs/random/main-56390eb/random-exhaustive-verilator.log` |
| Two cascaded chips as an 8-bit adder/subtractor, 4,194,304 cases (Verilator) | 0 mismatches, 0 X/Z | `logs/random/main-56390eb/random-cascade-verilator.log` |
| Reference model self-test (16,384 cases, plus 65,536 pairs x add, add+1, sub for the cascade) | 0 mismatches | `logs/random/main-56390eb/random-ref-selftest.log` |
| Directed tests B1–B8 | PENDING (PR #14) | |
| Acceptance 2: TI function table | PENDING (PR #14) | |

## Size and speed
Generic Yosys synthesis, no process target (`synth/report.txt`, `synth/yosys.log`):
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
The demo is a show-and-tell, not a test. The results were checked by hand; the tests above are what judge the chip.

## What went wrong along the way
- The first draft of the spec used the wrong equations on pins 15 and 17 (it called them P̄ and Ḡ, which only applies to active-low data). Vera caught it while checking the spec against the datasheet logic diagram (`docs/spec.md` section 9).
- PENDING: bugs found by verification before release (from GitHub issues).

## Not done
- Open-source layout (not planned for this chip).
- Electrical behaviour and the 74182 lookahead chip are out of scope (spec section 1).
