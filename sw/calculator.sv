// Demo: 8-bit calculator from two cascaded 74181s (spec section 7). Owner: Juno.
// Low chip's cn4_n feeds the high chip's cn_n. Not a test; the tests live in tb/.
module calculator;
    reg  [7:0] a, b;
    reg  [3:0] s;
    reg        m, cn_n;
    wire [3:0] f_lo, f_hi;
    wire       cn4_lo, cn4_hi;
    wire [7:0] f = {f_hi, f_lo};

    top lo (.a(a[3:0]), .b(b[3:0]), .s(s), .m(m), .cn_n(cn_n),
            .f(f_lo), .cn4_n(cn4_lo), .x(), .y(), .aeqb());
    top hi (.a(a[7:4]), .b(b[7:4]), .s(s), .m(m), .cn_n(cn4_lo),
            .f(f_hi), .cn4_n(cn4_hi), .x(), .y(), .aeqb());

    integer shown = 0;
    task show(input [8*12-1:0] label, input [7:0] ta, input [7:0] tb,
              input [3:0] ts, input tm, input tcn);
        begin
            a = ta; b = tb; s = ts; m = tm; cn_n = tcn;
            #1;
            if (tm)
                $display("%0s  %3d, %3d  ->  %3d  (0x%02h)",
                         label, ta, tb, f, f);
            else
                $display("%0s  %3d, %3d  ->  %3d  (0x%02h)  carry-out=%0d",
                         label, ta, tb, f, f, ~cn4_hi);
            shown = shown + 1;
        end
    endtask

    initial begin
        $display("8-bit calculator from two 74181 chips");
        $display("op           a,   b      result");
        show("add         ", 8'd25,  8'd17,  4'b1001, 0, 1);
        show("add         ", 8'd200, 8'd100, 4'b1001, 0, 1);  // wraps, carry-out 1
        show("subtract    ", 8'd100, 8'd58,  4'b0110, 0, 0);  // A-B with cn_n=0
        show("subtract    ", 8'd5,   8'd9,   4'b0110, 0, 0);  // wraps below zero
        show("AND         ", 8'hF0,  8'h3C,  4'b1011, 1, 1);
        show("OR          ", 8'hF0,  8'h0F,  4'b1110, 1, 1);
        show("XOR         ", 8'hAA,  8'hFF,  4'b0110, 1, 1);
        show("NOT A       ", 8'h0F,  8'h00,  4'b0000, 1, 1);
        $finish;
    end
endmodule
