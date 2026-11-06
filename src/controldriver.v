// ============================================================================
//  controldriver: bo dieu khien trung tam - FSM + thuat toan SCAN
//
//  SCAN: cabin chay theo 1 huong, dung o moi tang co yeu cau cung chieu
//  (nut cabin hoac nut goi cung huong), het yeu cau phia truoc moi dao chieu.
//  Tang xa nhat theo huong di luon duoc dung; cham tang 1 / tang 4 thi dung.
//
//  Vao : xung/muc tu module floor, step_done tu stepdrive, door_done tu doordrive
//  Ra  : step_run, dir_up -> stepdrive ; door_open -> doordrive ;
//        cur (tang hien tai 0..3), moving -> display
// ============================================================================
module controldriver #(
    parameter CLK_HZ        = 27_000_000,
    parameter ALIGN_STEPS   = 200,     // so buoc di them sau khi gap Hall de dung giua nam cham (>=1)
    parameter DOOR_DWELL_MS = 3000     // thoi gian giu cua mo
)(
    input        clk,
    input        rst,

    // tu module floor
    input  [3:0] hall_a,
    input  [3:0] hall_p,
    input  [3:0] car_p,
    input  [3:0] up_p,
    input  [3:0] dn_p,
    input        open_p,
    input        close_p,

    // tu stepdrive / doordrive
    input        step_done,
    input        door_done,

    // ra stepdrive / doordrive / display
    output       step_run,
    output reg   dir_up,
    output reg   door_open,
    output reg [1:0] cur,
    output       moving
);

    // ------------------------------------------------------------------
    // Tick 1 ms
    // ------------------------------------------------------------------
    localparam MS_DIV = CLK_HZ / 1000;
    reg [15:0] ms_cnt = 16'd0;
    wire tick_ms = (ms_cnt == MS_DIV - 1);
    always @(posedge clk) ms_cnt <= tick_ms ? 16'd0 : ms_cnt + 1'b1;

    // ------------------------------------------------------------------
    // Ham tien ich
    // ------------------------------------------------------------------
    function [3:0] above(input [1:0] f);     // cac tang o tren f
        above = 4'b1110 << f;
    endfunction
    function [3:0] below(input [1:0] f);     // cac tang o duoi f
        below = ~(4'b1111 << f);
    endfunction
    function [1:0] enc(input [3:0] v);       // one-hot -> chi so tang
        enc = v[0] ? 2'd0 : v[1] ? 2'd1 : v[2] ? 2'd2 : 2'd3;
    endfunction

    // ------------------------------------------------------------------
    // Trang thai
    // ------------------------------------------------------------------
    localparam S_INIT  = 3'd0,   // vua cap nguon: chay xuong tim cam bien
               S_IDLE  = 3'd1,   // dung, cua dong
               S_MOVE  = 3'd2,   // dang chay
               S_ALIGN = 3'd3,   // di them de can giua nam cham
               S_OPEN  = 3'd4,   // dang mo cua
               S_WAIT  = 3'd5,   // cua mo, cho khach
               S_CLOSE = 3'd6;   // dang dong cua

    reg [2:0]  state     = S_INIT;
    reg [15:0] tmr       = 16'd0;     // dem lui (ms) cho thoi gian giu cua
    reg [15:0] align_cnt = 16'd0;

    reg [3:0] req_car = 4'd0;         // yeu cau trong cabin
    reg [3:0] req_up  = 4'd0;         // goi len
    reg [3:0] req_dn  = 4'd0;         // goi xuong

    assign step_run = (state == S_INIT) || (state == S_MOVE) || (state == S_ALIGN);
    assign moving   = (state == S_INIT) || (state == S_MOVE);

    wire [3:0] cur_oh  = 4'b0001 << cur;
    wire       stopped = (state == S_IDLE) || (state == S_OPEN) ||
                         (state == S_WAIT) || (state == S_CLOSE);

    // bam nut cua tang dang dung -> coi nhu nut mo cua
    wire cur_press  = |((car_p | up_p | dn_p) & cur_oh);
    wire open_pulse = open_p | (stopped & cur_press);

    // cam bien tang moi (khac tang hien tai) vua gap
    wire [3:0] arr_v   = hall_p & ~cur_oh;
    wire [1:0] arr_idx = enc(arr_v);
    wire [3:0] arr_oh  = 4'b0001 << arr_idx;

    // bien tam (gan blocking trong khoi always)
    reg [3:0] nc, nu, nd, mask, allr;
    reg       ahead, car_h, match, here, limit;

    always @(posedge clk) begin
        if (tick_ms && tmr != 16'd0) tmr <= tmr - 1'b1;

        if (rst) begin
            state     <= S_INIT;
            cur       <= 2'd0;
            dir_up    <= 1'b0;
            door_open <= 1'b0;
            tmr       <= 16'd0;
            align_cnt <= 16'd0;
            req_car   <= 4'd0;
            req_up    <= 4'd0;
            req_dn    <= 4'd0;
        end else begin
            // --- ghi nhan yeu cau moi ---
            // INIT: bo qua tat ca. Dung/ALIGN: bo qua nut cua tang dang dung
            mask = (state == S_INIT) ? 4'hF :
                   ((stopped || state == S_ALIGN) ? cur_oh : 4'h0);
            nc = req_car | (car_p & ~mask);
            nu = req_up  | (up_p  & ~mask);
            nd = req_dn  | (dn_p  & ~mask);

            case (state)
            // ---------------- tim ve tang 1 ----------------
            S_INIT: begin
                dir_up <= 1'b0;
                if (|hall_a) begin
                    cur       <= enc(hall_a);
                    align_cnt <= 16'd0;
                    state     <= S_ALIGN;
                end
            end

            // ---------------- dung cho lenh ----------------
            S_IDLE: begin
                allr = nc | nu | nd;
                if (open_pulse || (|(allr & cur_oh))) begin
                    nc = nc & ~cur_oh;
                    nu = nu & ~cur_oh;
                    nd = nd & ~cur_oh;
                    door_open <= 1'b1;
                    state     <= S_OPEN;
                end else if (dir_up) begin
                    if      (|(allr & above(cur))) state <= S_MOVE;
                    else if (|(allr & below(cur))) begin dir_up <= 1'b0; state <= S_MOVE; end
                end else begin
                    if      (|(allr & below(cur))) state <= S_MOVE;
                    else if (|(allr & above(cur))) begin dir_up <= 1'b1; state <= S_MOVE; end
                end
            end

            // ---------------- dang chay: SCAN ----------------
            S_MOVE: begin
                if (arr_v != 4'd0) begin
                    cur   <= arr_idx;
                    allr  = nc | nu | nd;
                    ahead = dir_up ? |(allr & above(arr_idx)) : |(allr & below(arr_idx));
                    car_h = |(nc & arr_oh);
                    match = dir_up ? |(nu & arr_oh) : |(nd & arr_oh);
                    here  = |(allr & arr_oh);
                    limit = dir_up ? (arr_idx == 2'd3) : (arr_idx == 2'd0);

                    // dung neu: co nut cabin / co goi cung chieu /
                    // la tang xa nhat theo huong di / cham tang cuoi
                    if (car_h | match | (~ahead & here) | limit) begin
                        state     <= S_ALIGN;
                        align_cnt <= 16'd0;
                        nc = nc & ~arr_oh;
                        if (dir_up) begin
                            nu = nu & ~arr_oh;
                            if (!ahead && !match) nd = nd & ~arr_oh;
                        end else begin
                            nd = nd & ~arr_oh;
                            if (!ahead && !match) nu = nu & ~arr_oh;
                        end
                    end
                end
            end

            // ---------------- can giua nam cham ----------------
            S_ALIGN: begin
                if (step_done) begin
                    if (align_cnt >= ALIGN_STEPS - 1) begin
                        door_open <= 1'b1;
                        state     <= S_OPEN;
                    end else
                        align_cnt <= align_cnt + 1'b1;
                end
            end

            // ---------------- cua ----------------
            S_OPEN: begin
                if (door_done) begin            // servo da mo het
                    tmr   <= DOOR_DWELL_MS;
                    state <= S_WAIT;
                end
            end

            S_WAIT: begin
                if (open_pulse)
                    tmr <= DOOR_DWELL_MS;                 // gia han thoi gian mo
                else if (close_p || tmr == 16'd0) begin   // nut dong hoac het gio
                    door_open <= 1'b0;
                    state     <= S_CLOSE;
                end
            end

            S_CLOSE: begin
                if (open_pulse) begin                     // bam mo khi dang dong
                    door_open <= 1'b1;
                    state     <= S_OPEN;
                end else if (door_done)
                    state <= S_IDLE;
            end

            default: state <= S_INIT;
            endcase

            req_car <= nc;
            req_up  <= nu;
            req_dn  <= nd;
        end
    end

endmodule
