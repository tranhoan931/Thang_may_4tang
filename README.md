# Thang máy 4 tầng trên FPGA Tang Nano 20K


## Demo


## Tính năng
- Điều khiển thang máy 4 tầng bằng Verilog
- Thuật toán lập lịch SCAN
- Điều khiển động cơ bước (step motor) di chuyển cabin
- Servo đóng/mở cửa
- Hiển thị bằng LED/7 đoạn qua 74HC595
- Cảm biến Hall A3144 xác định vị trí tầng

## Phần cứng
- Tang Nano 20K | Board FPGA chính 
- Step motor | Di chuyển cabin 
- Servo | Cửa thang 
- 74HC595 | Mở rộng đầu ra 
- A3144 | Cảm biến vị trí 

## Sơ đồ khối / FSM

## Cấu trúc thư mục
- src/  – mã Verilog
- Physical constraints/  – file gán chân (.cst)
- img/  – hình ảnh, sơ đồ

## Cách build và nạp
1. Mở Gowin IDE, tạo project cho GW2AR-18
2. Thêm file trong `src/` và `Physical constraints/`
3. Synthesize → Place & Route → nạp qua USB

## Tác giả
hoan931