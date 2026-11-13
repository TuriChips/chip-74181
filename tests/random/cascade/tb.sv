// Spec B7 / acceptance test 3, exhaustive: two `top` instances, low cn4_n -> high cn_n,
// all 2^22 (a8, b8, s, m, cn_n) vs ref/ref74181.py cascade8. Owner: Rook.
module tb;
  logic [7:0] a, b; logic [3:0] s; logic m, cn_n;
  wire  [3:0] flo, fhi; wire clo, chi;
  wire  xl, yl, el, xh, yh, eh;  // not checked here (single-chip test covers them)
  logic [8:0] exp_mem [0:4194303];
  logic [8:0] got;
  integer i, bad, xz;

  top lo (.a(a[3:0]), .b(b[3:0]), .s(s), .m(m), .cn_n(cn_n),
          .f(flo), .cn4_n(clo), .x(xl), .y(yl), .aeqb(el));
  top hi (.a(a[7:4]), .b(b[7:4]), .s(s), .m(m), .cn_n(clo),
          .f(fhi), .cn4_n(chi), .x(xh), .y(yh), .aeqb(eh));

  initial begin
    $readmemh("build/random/cascade.hex", exp_mem);
    bad = 0; xz = 0;
    for (i = 0; i < 4194304; i = i + 1) begin
      {a, b, s, m, cn_n} = i[21:0];
      #1;
      got = {fhi, flo, chi};
      if ($isunknown(got)) begin
        xz = xz + 1;
        if (xz <= 10) $display("XZ  a=%b b=%b s=%b m=%b cn_n=%b got=%b", a, b, s, m, cn_n, got);
      end else if (got !== exp_mem[i]) begin
        bad = bad + 1;
        if (bad <= 20)
          $display("MISMATCH a=%b b=%b s=%b m=%b cn_n=%b  got f=%b cn8_n=%b  exp f=%b cn8_n=%b",
                   a, b, s, m, cn_n, got[8:1], got[0], exp_mem[i][8:1], exp_mem[i][0]);
      end
    end
    $display("cascade: cases=4194304 mismatches=%0d xz=%0d", bad, xz);
    if (bad == 0 && xz == 0) $display("PASS");
    else $display("FAIL");
    $finish;
  end
endmodule
