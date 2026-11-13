// 74181 4-bit ALU, top level. Spec: docs/spec.md; interfaces: docs/blocks.md.
// Purely combinational. Owner: Theo.
module top (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [3:0] s,
    input  wire       m,
    input  wire       cn_n,
    output wire [3:0] f,
    output wire       cn4_n,
    output wire       x,
    output wire       y,
    output wire       aeqb
);
    wire [3:0] p, g, c;

    alu181_pg u_pg (
        .a(a), .b(b), .s(s),
        .p(p), .g(g)
    );

    alu181_carry u_carry (
        .p(p), .g(g), .cn_n(cn_n),
        .c(c), .cn4_n(cn4_n), .x(x), .y(y)
    );

    alu181_sum u_sum (
        .p(p), .g(g), .c(c), .m(m),
        .f(f)
    );

    assign aeqb = &f;
endmodule
