# Coverage: spec §5 behaviours vs Rook's checks (chip-74181)

Owner: Rook. Updated 2026-11-13. "Covered" means a check in `tests/random/run.sh` fails if the behaviour is wrong.
Every check compares against `ref/ref74181.py`, which is itself checked by `selftest` (independent §4 table model, §3 identities, plain arithmetic).

| ID | Behaviour | Covered by | How |
|----|-----------|------------|-----|
| B1 | `f` matches §3, all 32 functions, both `cn_n` | exhaustive (Verilator, Icarus) | all 16,384 inputs, `f` compared bit for bit |
| B2 | logic mode: `f` independent of `cn_n` | exhaustive + ref selftest | RTL equals ref on every input; ref equals the §4 table, where logic rows have no `cn_n` term |
| B3 | `cn4_n` matches §3, both modes | exhaustive; selftest (A+B carry, B3 example) | every input, both `m` |
| B4 | `x`, `y` match §3, independent of `m`, `cn_n` | exhaustive; selftest (§3 G/P identities) | every input; ref `x`/`y` use no `m`/`cn_n` term |
| B5 | `aeqb == (f == 1111)` | exhaustive; selftest | every input |
| B6 | comparator s=0110, m=0, cn_n=1 | exhaustive (subset); selftest (256 pairs) | |
| B7 | two-chip cascade, A+B and A−B, 65,536 pairs | cascade (Verilator) | all 2^22 (a8, b8, s, m, cn_n), wider than spec; ref cascade checked against 8-bit arithmetic |
| B8 | no X/Z on any output | exhaustive (Icarus, 4-state) | `$isunknown` on every output, every input |

**Unexercised behaviours: none.**

Known limits (not spec behaviours, listed so nobody over-reads the result):
- Cascade X/Z is checked only in 2-state Verilator. Single-chip X/Z is covered in Icarus, and the cascade is just two of the same chip.
- Acceptance test 2 (the TI datasheet table) is Quinn's (#4). The ref selftest checks §3 against **our** §4 copy, not against TI's document.
- RTL ports are bound by name to spec §2. A port renamed in `top` fails to compile, which counts as a FAIL.
