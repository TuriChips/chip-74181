// Exhaustive check: RTL top vs ref/ref74181.py on all 2^14 inputs (spec 6, test 1).
// Owner: Rook. Expected values: build/random/expected.hex (generated, see run.sh).
module tb;
  logic [3:0] a, b, s; logic m, cn_n;
  wire  [3:0] f; wire cn4_n, x, y, aeqb;
  logic [7:0] exp_mem [0:16383];
  logic [7:0] got;
  integer i, bad, xz;

  top dut (.a(a), .b(b), .s(s), .m(m), .cn_n(cn_n),
           .f(f), .cn4_n(cn4_n), .x(x), .y(y), .aeqb(aeqb));

  initial begin
    $readmemh("build/random/expected.hex", exp_mem);
    bad = 0; xz = 0;
    for (i = 0; i < 16384; i = i + 1) begin
      {a, b, s, m, cn_n} = i[13:0];
      #1;
      got = {f, cn4_n, x, y, aeqb};
      if ($isunknown(got)) begin
        xz = xz + 1;
        if (xz <= 10) $display("XZ  a=%b b=%b s=%b m=%b cn_n=%b got=%b", a, b, s, m, cn_n, got);
      end else if (got !== exp_mem[i]) begin
        bad = bad + 1;
        if (bad <= 20)
          $display("MISMATCH a=%b b=%b s=%b m=%b cn_n=%b  got f=%b cn4_n=%b x=%b y=%b aeqb=%b  exp f=%b cn4_n=%b x=%b y=%b aeqb=%b",
                   a, b, s, m, cn_n, got[7:4], got[3], got[2], got[1], got[0],
                   exp_mem[i][7:4], exp_mem[i][3], exp_mem[i][2], exp_mem[i][1], exp_mem[i][0]);
      end
    end
    $display("exhaustive: cases=16384 mismatches=%0d xz=%0d", bad, xz);
    if (bad == 0 && xz == 0) $display("PASS");
    else $display("FAIL");
    $finish;
  end
endmodule
