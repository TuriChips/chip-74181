// Bit propagate/generate. Spec section 3. Purely combinational.
module alu181_pg (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [3:0] s,
    output wire [3:0] p,
    output wire [3:0] g
);
    assign p = a | (b & {4{s[0]}}) | (~b & {4{s[1]}});
    assign g = (a & ~b & {4{s[2]}}) | (a & b & {4{s[3]}});
endmodule
