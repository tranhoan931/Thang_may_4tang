// ============================================================================
//  stepdrive: dieu khien dong co buoc 28BYJ-48 (5V) qua mach ULN2003
//  - Che do nua buoc (half-step), 8 pha. 28BYJ-48: ~4096 nua buoc / 1 vong truc ra
//  - coil = {IN4, IN3, IN2, IN1} noi truc tiep toi IN1..IN4 cua mach ULN2003
//  - run    : 1 = quay, 0 = dung
//  - dir_up : 1 = chieu cabin di len (dao bang DIR_INVERT neu quay nguoc)
//  - step_done : xung 1 chu ky clk moi khi phat 1 buoc
//  - HOLD   : 1 = giu dong qua cuon day khi dung (giu cabin, nong hon)
//             0 = ngat dong khi dung
// ============================================================================
module stepdrive #(
    parameter STEP_CYCLES = 45_000,   // chu ky 1 buoc (clk) : 27MHz/45000 = 600 buoc/s
    parameter HOLD        = 1,
    parameter DIR_INVERT  = 0
)(
    input            clk,
    input            run,
    input            dir_up,
    output reg [3:0] coil,
    output           step_done
);

    reg [19:0] cnt = 20'd0;
    reg [2:0]  ph  = 3'd0;

    wire dir  = dir_up ^ (DIR_INVERT != 0);
    wire tick = run && (cnt == STEP_CYCLES - 1);

    assign step_done = tick;

    always @(posedge clk) begin
        if (!run || tick) cnt <= 20'd0;
        else              cnt <= cnt + 1'b1;

        if (tick) ph <= dir ? ph + 1'b1 : ph - 1'b1;
    end

    reg [3:0] pat;
    always @* begin
        case (ph)
            3'd0: pat = 4'b0001;   // IN1
            3'd1: pat = 4'b0011;   // IN1+IN2
            3'd2: pat = 4'b0010;   // IN2
            3'd3: pat = 4'b0110;   // IN2+IN3
            3'd4: pat = 4'b0100;   // IN3
            3'd5: pat = 4'b1100;   // IN3+IN4
            3'd6: pat = 4'b1000;   // IN4
            default: pat = 4'b1001;// IN4+IN1
        endcase
    end

    always @(posedge clk) begin
        if (!run && (HOLD == 0)) coil <= 4'b0000;
        else                     coil <= pat;
    end

endmodule
