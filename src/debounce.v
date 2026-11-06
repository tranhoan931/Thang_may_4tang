// ============================================================================
//  debounce: chong doi 1 bit (dong bo 2 FF + dem on dinh N bit)
//  in_n : ngo vao active LOW      q : ngo ra active HIGH da loc
//  N=18 @27MHz ~ 9.7 ms ; N=14 ~ 0.6 ms
// ============================================================================
module debounce #(parameter N = 18) (
    input  clk,
    input  in_n,
    output reg q
);
    reg [1:0]   s   = 2'b11;
    reg [N-1:0] cnt = {N{1'b0}};
    initial q = 1'b0;

    wire act = ~s[1];

    always @(posedge clk) begin
        s <= {s[0], in_n};
        if (act == q) cnt <= {N{1'b0}};
        else begin
            cnt <= cnt + 1'b1;
            if (&cnt) q <= act;
        end
    end
endmodule
