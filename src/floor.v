// ============================================================================
//  floor: xu ly toan bo ngo vao
//   - 4 cam bien Hall A3144 (active LOW)
//   - 6 nut goi tang: up1, up2, dn2, up3, dn3, dn4 (active LOW)
//   - 4 nut chon tang trong cabin, nut mo cua, nut dong cua (active LOW)
//  Ngo ra: muc da loc (hall_a) va xung 1 chu ky clk khi vua nhan (_p)
//  Chi so tang: bit0 = tang 1 ... bit3 = tang 4
// ============================================================================
module floor #(
    parameter BTN_N  = 18,     // do dai chong doi nut   (~9.7 ms @27MHz)
    parameter HALL_N = 14      // do dai chong doi Hall  (~0.6 ms @27MHz)
)(
    input        clk,

    input  [3:0] hall_n,
    input        up1_n,
    input        up2_n, dn2_n,
    input        up3_n, dn3_n,
    input        dn4_n,
    input  [3:0] cab_n,
    input        open_n,
    input        close_n,

    output [3:0] hall_a,       // 1 = nam cham dang o tang do (muc)
    output [3:0] hall_p,       // xung: vua vao vung nam cham
    output [3:0] car_p,        // xung: vua bam nut trong cabin
    output [3:0] up_p,         // xung: vua bam nut goi len   (bit3 = 0)
    output [3:0] dn_p,         // xung: vua bam nut goi xuong (bit0 = 0)
    output       open_p,       // xung: vua bam nut mo cua
    output       close_p       // xung: vua bam nut dong cua
);

    wire [3:0] car_l, up_l, dn_l;
    wire       open_l, close_l;

    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : G_HALL
            debounce #(.N(HALL_N)) d (.clk(clk), .in_n(hall_n[g]), .q(hall_a[g]));
        end
        for (g = 0; g < 4; g = g + 1) begin : G_CAR
            debounce #(.N(BTN_N)) d (.clk(clk), .in_n(cab_n[g]), .q(car_l[g]));
        end
    endgenerate

    assign up_l[3] = 1'b0;     // tang 4 khong co nut len
    assign dn_l[0] = 1'b0;     // tang 1 khong co nut xuong

    debounce #(.N(BTN_N)) d_up1 (.clk(clk), .in_n(up1_n), .q(up_l[0]));
    debounce #(.N(BTN_N)) d_up2 (.clk(clk), .in_n(up2_n), .q(up_l[1]));
    debounce #(.N(BTN_N)) d_up3 (.clk(clk), .in_n(up3_n), .q(up_l[2]));
    debounce #(.N(BTN_N)) d_dn2 (.clk(clk), .in_n(dn2_n), .q(dn_l[1]));
    debounce #(.N(BTN_N)) d_dn3 (.clk(clk), .in_n(dn3_n), .q(dn_l[2]));
    debounce #(.N(BTN_N)) d_dn4 (.clk(clk), .in_n(dn4_n), .q(dn_l[3]));
    debounce #(.N(BTN_N)) d_opn (.clk(clk), .in_n(open_n),  .q(open_l));
    debounce #(.N(BTN_N)) d_cls (.clk(clk), .in_n(close_n), .q(close_l));

    // phat hien canh len
    reg [3:0] hall_prev = 4'd0, car_prev = 4'd0, up_prev = 4'd0, dn_prev = 4'd0;
    reg       open_prev = 1'b0, close_prev = 1'b0;

    always @(posedge clk) begin
        hall_prev  <= hall_a;
        car_prev   <= car_l;
        up_prev    <= up_l;
        dn_prev    <= dn_l;
        open_prev  <= open_l;
        close_prev <= close_l;
    end

    assign hall_p  = hall_a & ~hall_prev;
    assign car_p   = car_l  & ~car_prev;
    assign up_p    = up_l   & ~up_prev;
    assign dn_p    = dn_l   & ~dn_prev;
    assign open_p  = open_l  & ~open_prev;
    assign close_p = close_l & ~close_prev;

endmodule
