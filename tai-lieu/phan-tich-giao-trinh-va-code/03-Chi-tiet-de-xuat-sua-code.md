# Đối chiếu lớp phân tích với cài đặt

## Lớp Java và DAO

`Customer1`, `Item1`, `ItemRevenue1` và `RelatedTransaction1` là class Java. `ItemRevenue1` kế thừa `Item1` trong mô hình phân tích theo mẫu lớp thống kê. Cài đặt dùng hai class độc lập.

| Trách nhiệm phân tích | Cài đặt |
| --- | --- |
| Kiểm tra dữ liệu đăng ký | `doMemberRegistration.jsp` kiểm tra trường nhập, chuẩn hóa thông tin liên hệ, băm mật khẩu. |
| Đăng ký riêng trên web | `CustomerDAO1.register(customer)` gọi `register_member1`, trả mã kết quả. |
| Xác thực quản lý | `ManagerDAO1.authenticate` trả `Long` hoặc `null`. Trang báo cáo kiểm tra quyền ở mỗi yêu cầu. |
| Thống kê theo kỳ | `ItemRevenueDAO1.summarize` trả `ArrayList<ItemRevenue1>`. |
| Chi tiết hàng hóa | `ItemRevenueDAO1.findItem` trả `Item1` hoặc `null`. |
| Giao dịch liên quan | `ItemRevenueDAO1.findTransactions` trả `ArrayList<RelatedTransaction1>`. |

Các DAO kế thừa `DAO1` và gọi hàm PostgreSQL bằng `CallableStatement`. Các lớp GD mô tả giao diện JSP. Trang 4 của VPP cập nhật ghi chú tương ứng.

## Quy tắc nghiệp vụ

- Khách đăng ký riêng trên web hoặc được ghi nhận thành viên khi cung cấp số điện thoại lúc mua hàng. Mua tại quầy không cung cấp số được ghi nhận là giao dịch vãng lai.
- Quản lý có phiên hợp lệ mở báo cáo từ trang chủ. Đăng nhập thành công chuyển trực tiếp tới menu báo cáo.
- Thống kê tính trọn ngày kết thúc. Doanh thu bằng tiền hàng trừ giảm giá và khoản hoàn thành công. Khoản hoàn được ghi vào ngày hoàn. Chi tiết giữ mã hàng và bộ lọc ngày của bảng thống kê.

Kiểm thử SQL nằm trong `supermarket/database/verify-workflows.sql`.
