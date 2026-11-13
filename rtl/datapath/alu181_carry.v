// Ripple carries plus cn4_n, x, y. Spec section 3. Purely combinational.
module alu181_carry (
    input  wire [3:0] p,
    input  wire [3:0] g,
    input  wire       cn_n,
    output wire [3:0] c,     // carry into each bit
    output wire       cn4_n,
    output wire       x,
    output wire       y
);
    wire c0, c1, c2, c3, c4;   // scalars: avoids false vector loop warning

    assign c0 = ~cn_n;
    assign c1 = g[0] | (p[0] & c0);
    assign c2 = g[1] | (p[1] & c1);
    assign c3 = g[2] | (p[2] & c2);
    assign c4 = g[3] | (p[3] & c3);
    assign c  = {c3, c2, c1, c0};

    assign cn4_n = ~c4;
    assign x = g[0] | g[1] | g[2] | g[3];
    assign y = ~(~p[3]
               | (~g[3] & ~p[2])
               | (~g[3] & ~g[2] & ~p[1])
               | (~g[3] & ~g[2] & ~g[1] & ~p[0]));
endmodule
