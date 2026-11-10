# Bộ phân tích dựa trên giáo trình, code và database

Bản VPP hiện tại: **Sieu-thi-Phan-Tich-Giao-Trinh-Va-Code.vpp**.

Đây là **mô hình phân tích có thiết kế đề xuất**, không khẳng định cấu trúc Java hiện tại đã cài đặt toàn bộ mô hình. Code và database là căn cứ dữ liệu/luồng xử lý; giáo trình là căn cứ trích lớp, thuộc tính giao diện và phân công trách nhiệm. Các điểm cần thay đổi khi triển khai được ghi rõ trong tài liệu 03 và trang 4 của VPP. Không sửa code ứng dụng hoặc schema trong lần lập tài liệu này.

## Phần đưa vào báo cáo

- **01-Hai-module-theo-3.2.3.md**: thuyết minh hai module lần lượt theo ba bước của bài giảng. Phần A là đăng ký; phần B là thống kê.
- **Dang-ky-thanh-vien.png**: sơ đồ hoàn chỉnh module đăng ký, tương ứng trang **1.3** trong VPP.
- **Thong-ke-hang-hoa.png**: sơ đồ hoàn chỉnh module thống kê, tương ứng trang **2.3**.
- **04-Thuc-the-3.2.2-dong-bo.md** và trang **0.1**: phần thực thể tham chiếu dùng chung, đã đồng bộ tên ItemRevenue1.

## Phần đối chiếu và sửa code

- **02-Bang-doi-chieu-code-db.md**: lớp nào có file Java, lớp nào trích từ bảng, lớp nào là GD/kết quả; nguồn dữ liệu của từng phần.
- **03-Chi-tiet-de-xuat-sua-code.md**: file và phương thức cần điều chỉnh nếu cài đặt đúng quan hệ kế thừa và phân công trách nhiệm. Phân biệt thay đổi cần cho kế thừa, thay đổi phương thức và những việc không bắt buộc.

## Các trang VPP

- 0: hướng dẫn, phạm vi và cách đọc trạng thái hiện tại/đề xuất.
- 0.1: mô hình thực thể tham chiếu, 16 thực thể theo schema và 2 lớp kết quả.
- 1.1 → 1.2 → 1.3: trích GD → thuộc tính giao diện → sơ đồ đăng ký hoàn chỉnh.
- 2.1 → 2.2 → 2.3: các bước tương ứng của thống kê hàng hóa.
- 3: xác thực quản lý hỗ trợ điều kiện bắt đầu.
- 4: đối chiếu và thay đổi code được đề xuất.

Thuộc tính có dấu `-`, phương thức có dấu `+`; các đường nối vuông góc. Tổng 25 model lớp gồm 16 thực thể theo schema, 2 lớp kết quả và 7 lớp GD. Database vẫn có 16 bảng. Các trang dùng chung model, không tạo các lớp/bảng trùng lặp.

Điểm quan trọng: ItemRevenue1 kế thừa Item1 là thiết kế đề xuất theo mẫu lớp thống kê; Java hiện dùng record độc lập. RelatedTransaction1 không bị ép kế thừa giao dịch bán. Ảnh của đủ 10 trang nằm trong thư mục preview, xuất từ chính VPP bằng Visual Paradigm.
