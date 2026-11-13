// Result bits. Spec section 3. Purely combinational.
module alu181_sum (
    input  wire [3:0] p,
    input  wire [3:0] g,
    input  wire [3:0] c,
    input  wire       m,
    output wire [3:0] f
);
    wire [3:0] h = p & ~g;

    assign f = m ? ~h : (h ^ c);
endmodule
