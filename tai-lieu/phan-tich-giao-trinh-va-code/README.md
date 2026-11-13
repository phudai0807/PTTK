# Bộ phân tích dựa trên giáo trình, code và database

Bản VPP cập nhật để đưa vào báo cáo là [Sieu-thi-Phan-Tich-Giao-Trinh-Va-Code-Cap-Nhat.vpp](../../output/so-do/Sieu-thi-Phan-Tich-Giao-Trinh-Va-Code-Cap-Nhat.vpp). Báo cáo Word và ảnh SVG nằm trong `output`.

Đây là mô hình phân tích toàn hệ thống và hai module chi tiết. Trang 4 trong VPP cập nhật ánh xạ JSP, DAO và PostgreSQL, gồm luồng ghi nhận thành viên theo số điện thoại khi mua hàng. Các ảnh PNG trong thư mục này thuộc lần xuất của bản VPP trước.

## Phần đưa vào báo cáo

- **01-Hai-module-theo-3.2.3.md**: thuyết minh hai module lần lượt theo ba bước của bài giảng. Phần A là đăng ký; phần B là thống kê.
- **Dang-ky-thanh-vien.png**: sơ đồ hoàn chỉnh module đăng ký, tương ứng trang **1.3** trong VPP.
- **Thong-ke-hang-hoa.png**: sơ đồ hoàn chỉnh module thống kê, tương ứng trang **2.3**.
- **04-Thuc-the-3.2.2-dong-bo.md** và trang **0.1**: phần thực thể tham chiếu dùng chung, đã đồng bộ tên ItemRevenue1.

## Phần đối chiếu và sửa code

- **02-Bang-doi-chieu-code-db.md**: lớp nào có file Java, lớp nào trích từ bảng, lớp nào là GD/kết quả; nguồn dữ liệu của từng phần.
- **03-Chi-tiet-de-xuat-sua-code.md**: bảng ánh xạ trách nhiệm phân tích sang JSP, DAO và PostgreSQL đang dùng.

## Các trang VPP

- 0: hướng dẫn, phạm vi và cách đọc trạng thái hiện tại/đề xuất.
- 0.1: mô hình thực thể tham chiếu, 16 thực thể theo schema và 2 lớp kết quả.
- 1.1 → 1.2 → 1.3: trích GD → thuộc tính giao diện → sơ đồ đăng ký hoàn chỉnh.
- 2.1 → 2.2 → 2.3: các bước tương ứng của thống kê hàng hóa.
- 3: xác thực quản lý hỗ trợ điều kiện bắt đầu.
- 4: đối chiếu với code hiện hành và các quy tắc nghiệp vụ.

Thuộc tính có dấu `-`, phương thức có dấu `+`; các đường nối vuông góc. Tổng 25 model lớp gồm 16 thực thể theo schema, 2 lớp kết quả và 7 lớp GD. Database vẫn có 16 bảng. Các trang dùng chung model, không tạo các lớp/bảng trùng lặp.

ItemRevenue1 kế thừa Item1 ở pha phân tích theo mẫu lớp thống kê. Cài đặt Java dùng hai class độc lập. RelatedTransaction1 là lớp kết quả gồm các dòng bán và hoàn. Các lớp DAO gọi hàm PostgreSQL bằng CallableStatement.
