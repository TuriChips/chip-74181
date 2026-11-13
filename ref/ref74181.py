#!/usr/bin/env python3
"""Reference model of the 74181 4-bit ALU. Owner: Rook.

Written from docs/spec.md only, never from the RTL:
  model_eq()    - the normative equations of spec section 3, bit by bit.
  model_table() - an independent model from the section 4 function table
                  (plain arithmetic), used to cross-check model_eq on f.

Input index (14 bits), used by tests/random:  i = a<<10 | b<<6 | s<<2 | m<<1 | cn_n
Expected byte (8 bits):                        f<<4 | cn4_n<<3 | x<<2 | y<<1 | aeqb

Cascade (spec B7): two chips, low cn4_n -> high cn_n.
Input index (22 bits): i = a8<<14 | b8<<6 | s<<2 | m<<1 | cn_n
Expected (9 bits):     f8<<1 | cn8_n   (cn8_n = cn4_n of the high chip)

Usage:
  ref74181.py selftest              cross-check models, print PASS/FAIL
  ref74181.py vectors OUT.hex       write all 16,384 expected bytes ($readmemh format)
  ref74181.py cascade OUT.hex       write all 2^22 cascade expected values
"""
import sys

def bit(v, i):
    return (v >> i) & 1

def model_eq(a, b, s, m, cn_n):
    """Spec section 3, transcribed literally. Returns (f, cn4_n, x, y, aeqb)."""
    p = [0] * 4; g = [0] * 4; h = [0] * 4
    for i in range(4):
        ai, bi = bit(a, i), bit(b, i)
        p[i] = ai | (bi & bit(s, 0)) | ((1 - bi) & bit(s, 1))
        g[i] = (ai & (1 - bi) & bit(s, 2)) | (ai & bi & bit(s, 3))
        h[i] = p[i] & (1 - g[i])
    c = [1 - cn_n] + [0] * 4
    for i in range(4):
        c[i + 1] = g[i] | (p[i] & c[i])
    f = 0
    for i in range(4):
        fi = (1 - h[i]) if m else (h[i] ^ c[i])
        f |= fi << i
    n = lambda v: 1 - v
    cn4_n = n(c[4])
    x = g[0] | g[1] | g[2] | g[3]
    y = n(n(p[3]) | (n(g[3]) & n(p[2])) | (n(g[3]) & n(g[2]) & n(p[1]))
          | (n(g[3]) & n(g[2]) & n(g[1]) & n(p[0])))
    aeqb = bit(f, 0) & bit(f, 1) & bit(f, 2) & bit(f, 3)
    return f, cn4_n, x, y, aeqb

def model_table(a, b, s, m, cn_n):
    """Spec section 4 table: f only. Written as arithmetic, independent of section 3."""
    M = 0xF
    na, nb = ~a & M, ~b & M
    if m:
        logic = [na, ~(a | b), na & b, 0, ~(a & b), nb, a ^ b, a & nb,
                 na | b, ~(a ^ b), b, a & b, M, a | nb, a | b, a]
        return logic[s] & M
    cin = 1 - cn_n
    # Each arithmetic row is X + Y + cin, with X, Y read off the table
    # ("X - 1" rows are X + 1111). This is what "+1 means cn_n=0" says.
    rows = [(a, 0), (a | b, 0), (a | nb, 0), (0, M),
            (a, a & nb), (a | b, a & nb), (a, nb), (a & nb, M),
            (a, a & b), (a, b), (a | nb, a & b), (a & b, M),
            (a, a), (a | b, a), (a | nb, a), (a, M)]
    xx, yy = rows[s]
    return (xx + yy + cin) & M

def all_inputs():
    for i in range(1 << 14):
        yield i, (i >> 10) & 0xF, (i >> 6) & 0xF, (i >> 2) & 0xF, (i >> 1) & 1, i & 1

def pack(f, cn4_n, x, y, aeqb):
    return f << 4 | cn4_n << 3 | x << 2 | y << 1 | aeqb

def cascade8(a8, b8, s, m, cn_n):
    """Two chips chained as spec B7 describes. Returns (f8, cn8_n)."""
    flo, clo, *_ = model_eq(a8 & 0xF, b8 & 0xF, s, m, cn_n)
    fhi, chi, *_ = model_eq(a8 >> 4, b8 >> 4, s, m, clo)
    return fhi << 4 | flo, chi

def selftest_cascade():
    """B7 against plain 8-bit arithmetic, independent of section 3."""
    bad = 0
    for a in range(256):
        for b in range(256):
            for cn in (0, 1):
                cin = 1 - cn
                f, co = cascade8(a, b, 0b1001, 0, cn)          # A + B (+1)
                if f != (a + b + cin) & 0xFF or co != (0 if a + b + cin > 255 else 1):
                    bad += 1
                    if bad <= 10: print(f"MISMATCH cascade add a={a} b={b} cn_n={cn} f={f} cn8_n={co}")
            f, co = cascade8(a, b, 0b0110, 0, 0)               # A - B
            if f != (a - b) & 0xFF or co != (1 if a < b else 0):
                bad += 1
                if bad <= 10: print(f"MISMATCH cascade sub a={a} b={b} f={f} cn8_n={co}")
    print(f"selftest cascade: 65536 pairs x (add, add+1, sub), mismatches={bad}")
    return bad

def selftest():
    bad = 0
    for i, a, b, s, m, cn in all_inputs():
        f, cn4_n, x, y, aeqb = model_eq(a, b, s, m, cn)
        ft = model_table(a, b, s, m, cn)
        errs = []
        if f != ft: errs.append(f"f eq={f:04b} table={ft:04b}")
        # spec 3 notes: identities with group G, P, and comparator / B3 examples
        if aeqb != (f == 0xF): errs.append("aeqb")
        if errs:
            bad += 1
            if bad <= 10: print(f"MISMATCH a={a:04b} b={b:04b} s={s:04b} m={m} cn_n={cn}: {'; '.join(errs)}")
    # Arithmetic carry-out for A+B (s=1001, m=0) must equal the true carry.
    for a in range(16):
        for b in range(16):
            for cn in (0, 1):
                _, cn4_n, *_ = model_eq(a, b, 0b1001, 0, cn)
                if cn4_n != (0 if a + b + (1 - cn) > 15 else 1):
                    bad += 1; print(f"MISMATCH carry a={a} b={b} cn_n={cn}")
    # Spec 3 identities for x, y.
    for i, a, b, s, m, cn in all_inputs():
        p = [bit(a, k) | (bit(b, k) & bit(s, 0)) | ((1 - bit(b, k)) & bit(s, 1)) for k in range(4)]
        g = [bit(a, k) & (1 - bit(b, k)) & bit(s, 2) | bit(a, k) & bit(b, k) & bit(s, 3) for k in range(4)]
        G = g[3] | p[3] & g[2] | p[3] & p[2] & g[1] | p[3] & p[2] & p[1] & g[0]
        P = p[0] & p[1] & p[2] & p[3]
        _, cn4_n, x, y, _ = model_eq(a, b, s, m, cn)
        if y != (G | P) or (x & y) != G or cn4_n != 1 - (y & (x | (1 - cn))):
            bad += 1
            if bad <= 10: print(f"MISMATCH x/y identity i={i}")
    # B3 example from spec 5.
    assert model_eq(0b1111, 0b0001, 0b1001, 0, 1)[:2] == (0, 0), "B3 example"
    # B6 comparator.
    for a in range(16):
        for b in range(16):
            if model_eq(a, b, 0b0110, 0, 1)[4] != (a == b):
                bad += 1; print(f"MISMATCH comparator a={a} b={b}")
    print(f"selftest: {1 << 14} cases, mismatches={bad}")
    bad += selftest_cascade()
    print("PASS" if bad == 0 else "FAIL")
    return bad == 0

def write_cascade(path):
    with open(path, "w") as fh:
        fh.write("// 74181 x2 cascade expected, generated by ref/ref74181.py. line i: f8<<1|cn8_n,\n")
        fh.write("// i = a8<<14|b8<<6|s<<2|m<<1|cn_n\n")
        for i in range(1 << 22):
            r = cascade8((i >> 14) & 0xFF, (i >> 6) & 0xFF, (i >> 2) & 0xF, (i >> 1) & 1, i & 1)
            fh.write(f"{r[0] << 1 | r[1]:03x}\n")

def write_vectors(path):
    with open(path, "w") as fh:
        fh.write("// 74181 expected outputs, generated by ref/ref74181.py from docs/spec.md 3.\n")
        fh.write("// line i (0..16383): f<<4|cn4_n<<3|x<<2|y<<1|aeqb, i = a<<10|b<<6|s<<2|m<<1|cn_n\n")
        for i, a, b, s, m, cn in all_inputs():
            fh.write(f"{pack(*model_eq(a, b, s, m, cn)):02x}\n")

if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "selftest":
        sys.exit(0 if selftest() else 1)
    if len(sys.argv) == 3 and sys.argv[1] == "vectors":
        write_vectors(sys.argv[2]); sys.exit(0)
    if len(sys.argv) == 3 and sys.argv[1] == "cascade":
        write_cascade(sys.argv[2]); sys.exit(0)
    print(__doc__); sys.exit(2)
