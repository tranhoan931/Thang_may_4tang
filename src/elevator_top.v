// ============================================================================
//  THANG MAY 4 TANG - TANG NANO 20K (clk 27 MHz) - THUAT TOAN SCAN
//
//  floor ----> controldriver ----> stepdrive ----> ULN2003 + 28BYJ-48 (cabin)
//                    |  \--------> doordrive ----> servo SG90 (cua)
//                    \-----------> display   ----> 74HC595 -> LED 7 doan
//
//  Tat ca nut bam va cam bien A3144 : active LOW (keo len bang pull-up)
// ============================================================================
module elevator_top #(
    parameter CLK_HZ         = 27_000_000,
    // dong co buoc
    parameter STEP_CYCLES    = 45_000,   // 600 buoc/s (28BYJ-48 nen <= ~800)
    parameter STEP_HOLD      = 1,        // 1 = giu dong khi dung
    parameter DIR_INVERT     = 0,        // 1 = dao chieu quay
    parameter ALIGN_STEPS    = 200,      // buoc di them sau khi gap Hall
    // cua
    parameter SERVO_OPEN_US  = 2000,
    parameter SERVO_CLOSE_US = 1000,
    parameter SERVO_RAMP_US  = 10,
    parameter DOOR_DWELL_MS  = 3000
)(
    input        clk,                    // 27 MHz (chan 4)
    input        rst_n,                  // nut reset, active LOW (chan 15)

    input  [3:0] hall_n,                 // hall_n[0]=tang1 ... hall_n[3]=tang4
    input        up1_n,
    input        up2_n, dn2_n,
    input        up3_n, dn3_n,
    input        dn4_n,
    input  [3:0] cab_n,                  // cab_n[0]=tang1 ... cab_n[3]=tang4
    input        btn_open_n,
    input        btn_close_n,

    output [3:0] motor_in,               // {IN4,IN3,IN2,IN1} cua ULN2003
    output       servo,                  // chan tin hieu SG90
    output       ser,                    // 74HC595 DS
    output       srclk,                  // 74HC595 SH_CP
    output       rclk                    // 74HC595 ST_CP
);

    // ------------------------------------------------------------------
    // Reset: tu dong khi cap nguon + nut rst_n (active LOW, dong bo 2 FF)
    // ------------------------------------------------------------------
    reg [7:0] por   = 8'd0;
    reg [1:0] rst_s = 2'b00;
    always @(posedge clk) begin
        if (!por[7]) por <= por + 1'b1;
        rst_s <= {rst_s[0], rst_n};
    end
    wire rst = ~por[7] | ~rst_s[1];

    // ------------------------------------------------------------------
    // Day noi giua cac module
    // ------------------------------------------------------------------
    wire [3:0] hall_a, hall_p, car_p, up_p, dn_p;
    wire       open_p, close_p;

    wire       step_run, dir_up, step_done;
    wire       door_open, door_done;
    wire [1:0] cur;
    wire       moving;

    // ------------------------------------------------------------------
    floor u_floor (
        .clk     (clk),
        .hall_n  (hall_n),
        .up1_n   (up1_n),
        .up2_n   (up2_n),  .dn2_n (dn2_n),
        .up3_n   (up3_n),  .dn3_n (dn3_n),
        .dn4_n   (dn4_n),
        .cab_n   (cab_n),
        .open_n  (btn_open_n),
        .close_n (btn_close_n),
        .hall_a  (hall_a),
        .hall_p  (hall_p),
        .car_p   (car_p),
        .up_p    (up_p),
        .dn_p    (dn_p),
        .open_p  (open_p),
        .close_p (close_p)
    );

    controldriver #(
        .CLK_HZ        (CLK_HZ),
        .ALIGN_STEPS   (ALIGN_STEPS),
        .DOOR_DWELL_MS (DOOR_DWELL_MS)
    ) u_ctrl (
        .clk       (clk),
        .rst       (rst),
        .hall_a    (hall_a),
        .hall_p    (hall_p),
        .car_p     (car_p),
        .up_p      (up_p),
        .dn_p      (dn_p),
        .open_p    (open_p),
        .close_p   (close_p),
        .step_done (step_done),
        .door_done (door_done),
        .step_run  (step_run),
        .dir_up    (dir_up),
        .door_open (door_open),
        .cur       (cur),
        .moving    (moving)
    );

    stepdrive #(
        .STEP_CYCLES (STEP_CYCLES),
        .HOLD        (STEP_HOLD),
        .DIR_INVERT  (DIR_INVERT)
    ) u_step (
        .clk       (clk),
        .run       (step_run),
        .dir_up    (dir_up),
        .coil      (motor_in),
        .step_done (step_done)
    );

    doordrive #(
        .CLK_HZ   (CLK_HZ),
        .OPEN_US  (SERVO_OPEN_US),
        .CLOSE_US (SERVO_CLOSE_US),
        .RAMP_US  (SERVO_RAMP_US)
    ) u_door (
        .clk  (clk),
        .open (door_open),
        .pwm  (servo),
        .done (door_done)
    );

    display u_disp (
        .clk       (clk),
        .floor_idx (cur),
        .moving    (moving),
        .ser       (ser),
        .srclk     (srclk),
        .rclk      (rclk)
    );

endmodule
