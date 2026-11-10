# Đối chiếu bản theo mẫu bài giảng

Bản bàn giao: `Sieu-thi-Lop-thuc-the-Theo-Mau-Bai-Giang.vpp`.

## Những điểm theo mẫu Hình 3.5

- Ô lớp hình chữ nhật nền trắng, tên lớp in đậm, ngăn thuộc tính riêng.
- Dấu `-` là visibility private của thuộc tính UML, không nằm trong tên thuộc tính.
- Chưa ghi kiểu dữ liệu, ID kỹ thuật và phương thức trong pha phân tích.
- Giữ các lớp trung gian để tách quan hệ nhiều–nhiều; biểu diễn bội số ở hai đầu liên kết nghiệp vụ.
- Hình thoi đen ở đầu chứng từ trong ba quan hệ composition với chi tiết.
- Thêm lớp thống kê ItemStatistics1 kế thừa Item1 theo cách bài giảng biểu diễn lớp thống kê kế thừa thực thể tương ứng. Tam giác rỗng hướng về Item1, không ghi bội số trên quan hệ kế thừa.
- ItemStatistics1 chỉ khai báo supplierLabels, quantity, returnedQuantity, transactionCount, grossAmount, discountAmount, refundAmount, /revenue; thông tin hàng hóa được kế thừa, không ghi lặp trong ngăn thuộc tính.
- Các lớp được bố trí theo cụm nghiệp vụ, đường nối vuông góc; có các góc nhìn nhỏ để theo dõi từng nghiệp vụ.

## Những điểm điều chỉnh theo dự án

| Phạm vi | Giải thích |
| --- | --- |
| Mô hình phân tích | 17 lớp: 16 thực thể lưu trữ và 1 lớp thống kê. Sơ đồ 1 có 25 association/composition và 1 generalization. |
| Database | Vẫn 16 bảng. ItemStatistics1 không có bảng riêng vì biểu diễn kết quả tính toán thống kê. Quan hệ giữa 16 thực thể lưu trữ giữ nguyên ý nghĩa từ schema. |
| Mã Java | Customer1, Item1, ItemRevenue1, RelatedTransaction1 là các record thực tế. Java hiện chưa có ItemStatistics1; chưa cài đặt kế thừa Item1. |
| Ánh xạ báo cáo | ItemStatistics1 là khái niệm phân tích. ItemRevenue1 là cấu trúc kết quả truy vấn đang được ItemRevenueDAO1 sử dụng khi cài đặt chức năng thống kê. Hai tên không khẳng định cùng một kiểu Java. |
| Dòng giao dịch liên quan | RelatedTransaction1 vẫn là record gom sự kiện bán và hoàn, không ép kế thừa SaleTransaction1. |
| Họ tên và địa chỉ | Giữ fullName/address làm thuộc tính, phù hợp dữ liệu hiện lưu. Bài giảng cho phép tách riêng nhưng không bắt buộc; không đề xuất thêm các bảng mới. |
| Vai trò nhân viên | Giữ Employee1.role vì mô hình hiện phân loại nhân viên bằng vai trò; không thêm các lớp con chỉ vì ví dụ trường đại học có các lớp nhân viên chuyên biệt. |

Hai record báo cáo Java nằm ở sơ đồ 7 (phụ lục), không trộn vào sơ đồ thực thể phân tích chính. Sơ đồ 6 minh họa riêng quan hệ kế thừa thống kê.

Nguồn: yêu cầu bài toán, bài giảng mục 3.2.2/Hình 3.5, `supermarket/database/schema.sql`, các record và DAO trong mã nguồn hiện tại. Chưa đối chiếu catalog một PostgreSQL đang chạy. Không thay đổi code Java hoặc schema ứng dụng.
