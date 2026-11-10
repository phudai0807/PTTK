# Biểu đồ lớp hai module theo mục 3.2.3

**Bản cập nhật theo yêu cầu kết hợp giáo trình, code/DB và nêu rõ đề xuất sửa code:** xem [bộ phân tích mới](../phan-tich-giao-trinh-va-code/README.md). Bộ mới dùng tên ItemRevenue1 đã có trong code và phân biệt rõ cấu trúc hiện tại với thiết kế đề xuất. Các file trong thư mục này là bản trước.

Mở bản mới nhất `Sieu-thi-GD-Theo-Tung-Buoc-3.2.3.vpp` bằng Visual Paradigm 18.1.

- Trang 0: hướng dẫn làm lần lượt 3 bước theo giáo trình.
- Trang 1.1, 1.2, 1.3: lần lượt trích lớp GD, bổ sung thuộc tính giao diện và sơ đồ hoàn chỉnh module đăng ký thành viên.
- Trang 2.1, 2.2, 2.3: các bước tương ứng cho module thống kê hàng hóa theo doanh thu.
- Trang 3: xác thực quản lý, hỗ trợ điều kiện đầu vào của module thống kê.

Các lớp giao diện dùng **tiền tố GD** như mẫu: GDCustomerHome1, GDMemberRegistration1, GDManagerHome1, GDStatisticsMenu1, GDItemStatistics1, GDItemDetails1, GDManagerLogin1. Phần tên phía sau GD bằng tiếng Anh và kết thúc bằng số `1`. Các sơ đồ dùng ô lớp nền trắng, đường nối vuông góc; thuộc tính có dấu `-`, phương thức có dấu `+`. Các thành phần giao diện có tiền tố `in`, `out`, `sub`, `outsub`.

Theo mẫu Hình 3.6 và Hình 3.8, các phương thức được gán cho lớp thực thể theo đầu ra/đầu vào; không tự thêm các lớp Controller/DAO vào sơ đồ phân tích chính. Các phương thức này là phân công trong pha phân tích, không khẳng định record Java đã có đủ phương thức tương ứng. Code hiện triển khai bằng JSP và DAO.

Thuyết minh mới theo từng module và lần lượt từng bước, gồm các thành phần giao diện, input/output, cơ sở gán phương thức và ánh xạ code: `Trich-lop-GD-lan-luot-theo-3.2.3.md`. Nội dung cũng nằm trong Documentation của các sơ đồ trong VPP.

Hai sơ đồ hoàn chỉnh để đưa vào báo cáo là trang **1.3** và **2.3**. Ảnh tương ứng: `GD-Module-1-Dang-ky-thanh-vien.png`, `GD-Module-2-Thong-ke-hang-hoa.png`. Ảnh đủ 8 trang nằm trong `GD-theo-tung-buoc-preview`, xuất từ chính VPP bằng bộ xuất Visual Paradigm. Các trang từng bước dùng chung model lớp, không tạo các lớp/bảng trùng lặp.

File VPP và thuyết minh không có GD trong tên là bản trước khi điều chỉnh theo yêu cầu đặt tên GD và thể hiện từng bước.

Đây là mô hình phân tích cho hai module, không bổ sung bảng database và không sửa code Java/JSP/schema. ItemStatistics1 giữ quan hệ kế thừa Item1 từ bản thực thể 3.2.2; trong code, dữ liệu thống kê đang được mang bởi record ItemRevenue1. RelatedTransaction1 là kết quả truy vấn bán/hoàn, không có bảng riêng.
