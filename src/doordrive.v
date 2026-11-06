// ============================================================================
//  doordrive: dieu khien servo SG90 mo/dong cua
//  - PWM 50 Hz (chu ky 20 ms), do rong xung 1000..2000 us (chinh bang tham so)
//  - Do rong xung tang/giam dan (RAMP_US moi chu ky 20 ms) de cua chay em, khong dap
//  - open : 1 = mo cua, 0 = dong cua
//  - done : 1 khi servo da toi vi tri muc tieu
//  SG90 thuc te nhan xung ~0.5..2.4 ms, chinh OPEN_US / CLOSE_US cho dung goc cua
// ============================================================================
module doordrive #(
    parameter CLK_HZ   = 27_000_000,
    parameter OPEN_US  = 2000,
    parameter CLOSE_US = 1000,
    parameter RAMP_US  = 10          // 10 us / 20 ms -> quet 1000 us mat ~2 giay
)(
    input  clk,
    input  open,
    output pwm,
    output done
);

    localparam [7:0]  US      = CLK_HZ / 1_000_000;   // so clk trong 1 us
    localparam [19:0] PER     = CLK_HZ / 50;          // so clk trong 20 ms
    localparam [11:0] OPEN_W  = OPEN_US;
    localparam [11:0] CLOSE_W = CLOSE_US;
    localparam [11:0] RAMP    = RAMP_US;

    reg  [19:0] fc   = 20'd0;           // dem trong 1 chu ky 20 ms
    reg  [11:0] w_us = CLOSE_W;         // do rong xung hien tai (us), luc khoi dong coi nhu cua dong

    wire [11:0] tgt       = open ? OPEN_W : CLOSE_W;
    wire        frame_end = (fc == PER - 1'b1);

    wire [11:0] diff_up = tgt  - w_us;  // chi dung khi w_us < tgt
    wire [11:0] diff_dn = w_us - tgt;   // chi dung khi w_us > tgt

    always @(posedge clk) begin
        fc <= frame_end ? 20'd0 : fc + 1'b1;

        if (frame_end) begin
            if (w_us < tgt)
                w_us <= (diff_up > RAMP) ? (w_us + RAMP) : tgt;
            else if (w_us > tgt)
                w_us <= (diff_dn > RAMP) ? (w_us - RAMP) : tgt;
        end
    end

    wire [19:0] width_clk = w_us * US;

    assign pwm  = (fc < width_clk);
    assign done = (w_us == tgt);

endmodule