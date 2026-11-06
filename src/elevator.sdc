# ============================================================================
#  elevator.sdc - Timing constraints (Gowin)
#  Clock he thong 27 MHz tren board Tang Nano 20K (chu ky 37.037 ns)
# ============================================================================

create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]

# Cac ngo vao la tin hieu bat dong bo (nut bam, cam bien Hall, reset):
# da duoc dong bo 2 FF + chong doi trong module debounce / elevator_top
# -> khong can rang buoc thoi gian.
set_false_path -from [get_ports {rst_n}]
set_false_path -from [get_ports {hall_n[*]}]
set_false_path -from [get_ports {cab_n[*]}]
set_false_path -from [get_ports {up1_n up2_n dn2_n up3_n dn3_n dn4_n}]
set_false_path -from [get_ports {btn_open_n btn_close_n}]

# Cac ngo ra (STEP coil, servo PWM, 74HC595) chay cham so voi clock,
# khong can rang buoc thoi gian.
set_false_path -to [get_ports {motor_in[*]}]
set_false_path -to [get_ports {servo}]
set_false_path -to [get_ports {ser srclk rclk}]
