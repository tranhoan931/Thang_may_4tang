// ============================================================================
//  display: hien thi so tang tren LED 7 doan anode chung qua 74HC595
//  - Q0..Q7 cua 74HC595 = a, b, c, d, e, f, g, dp  (segment active LOW)
//  - floor_idx : 0..3  -> hien thi 1..4
//  - moving    : 1 -> sang dau cham (dp) khi cabin dang chay
//  - Day lien tuc du lieu 8 bit ra 74HC595 (MSB truoc), chot bang rclk
// ============================================================================
module display (
    input        clk,
    input  [1:0] floor_idx,
    input        moving,
    output reg   ser,
    output reg   srclk,
    output reg   rclk
);

    // bit7=dp g f e d c b a bit0 (muc 0 = sang)
    reg [7:0] seg;
    always @* begin
        case (floor_idx)
            2'd0:    seg = 8'hF9;   // 1
            2'd1:    seg = 8'hA4;   // 2
            2'd2:    seg = 8'hB0;   // 3
            default: seg = 8'h99;   // 4
        endcase
        if (moving) seg[7] = 1'b0;  // dp sang
    end

    reg [5:0] sdiv  = 6'd0;         // chia clk: srclk ~ 27MHz/64/2 ~ 210 kHz
    reg [4:0] sph   = 5'd0;
    reg [7:0] shdat = 8'hFF;

    wire       s_tick = (sdiv == 6'd63);
    wire [2:0] bidx   = 3'd7 - sph[3:1];

    initial begin
        ser   = 1'b1;
        srclk = 1'b0;
        rclk  = 1'b0;
    end

    always @(posedge clk) begin
        sdiv <= sdiv + 1'b1;
        if (s_tick) begin
            if (sph < 5'd16) begin
                if (!sph[0]) begin
                    srclk <= 1'b0;
                    ser   <= shdat[bidx];
                end else
                    srclk <= 1'b1;
                sph <= sph + 1'b1;
            end else if (sph == 5'd16) begin
                srclk <= 1'b0;
                rclk  <= 1'b1;      // chot du lieu ra LED
                sph   <= 5'd17;
            end else begin
                rclk  <= 1'b0;
                shdat <= seg;       // nap du lieu moi cho vong ke tiep
                sph   <= 5'd0;
            end
        end
    end

endmodule
