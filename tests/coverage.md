# Spec coverage: 74181 (Quinn)

Every behaviour in `docs/spec.md` §5 and the acceptance tests in §6, with the test that covers it.
A row counts as covered only once its test has a passing log in `logs/`.

| Spec item | Test(s) | Status |
|-----------|---------|--------|
| B1 f for all 32 functions, both cn_n | `top_table`, `top_exhaustive` | PASS (logs/20261113T173730Z/) |
| B2 logic mode ignores cn_n | `top_table` | PASS (logs/20261113T173730Z/) |
| B3 cn4_n both modes, worked example, comparator table | `top_table`, `top_exhaustive` | PASS (logs/20261113T173730Z/) |
| B4 x, y independent of m and cn_n | `top_exhaustive` | PASS (logs/20261113T173730Z/) |
| B5 aeqb == (f == 1111) | `top_table`, `top_exhaustive` | PASS (logs/20261113T173730Z/) |
| B6 comparator | `top_table` | PASS (logs/20261113T173730Z/) |
| B7 8-bit cascade | `top_cascade` | PASS (logs/20261113T173730Z/) |
| B8 no X/Z | `top_table`, `top_exhaustive` run in Icarus (4-state) via `tests/run_4state.sh`; Verilator is 2-state so its run cannot fail this check | PASS (logs/4state/), mutant `aeqb = &f ? 1 : x` caught |
| Acceptance 1 (16,384 vs §3) | `top_exhaustive` | PASS (logs/20261113T173730Z/) |
| Acceptance 2 (TI table) | `top_table` | PASS (logs/20261113T173730Z/) |
| Acceptance 3 (cascade) | `top_cascade` | PASS (logs/20261113T173730Z/) |
| Block conformance | `pg`, `carry`, `sum` | PASS (logs/20261113T173730Z/) |
