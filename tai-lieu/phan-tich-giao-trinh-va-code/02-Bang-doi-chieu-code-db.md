# Bảng đối chiếu mô hình phân tích với code và database

## Phạm vi

Mô hình phân tích theo giáo trình và cấu trúc cài đặt là hai mức khác nhau. Bảng dưới giúp đối chiếu từng lớp mà không hiểu nhầm lớp phân tích đã có đủ thuộc tính/phương thức trong Java. Đây là thiết kế phân tích có các thay đổi đề xuất, chưa phải mô tả rằng code đã cài đặt toàn bộ thiết kế.

## Lớp dữ liệu/nghiệp vụ

| Lớp phân tích | Bảng/nguồn dữ liệu | Java hiện có | Điểm cần lưu ý |
| --- | --- | --- | --- |
| Customer1 | customers1 | Có: Customer1.java | Class hiện có 5 trường nhập. isMember được SQL gán true và createdAt được DB cấp; chúng có trong trạng thái thực thể phân tích, chưa nằm trong DTO nhập. |
| Employee1 | employees1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| Supplier1 | suppliers1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| Item1 | items1 | Có: Item1.java | Class hiện có id, code, name, unit, description. Phân tích có thêm currentPrice, stockQuantity, active, trackLots từ bảng; ID kỹ thuật được lược trên hình. |
| GoodsReceipt1 | goods_receipts1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| GoodsReceiptDetail1 | goods_receipt_details1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| OnlineOrder1 | online_orders1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| OnlineOrderDetail1 | online_order_details1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| SaleTransaction1 | sale_transactions1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| SaleTransactionDetail1 | sale_transaction_details1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| SalePayment1 | sale_payments1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| SaleRefund1 | sale_refunds1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| SaleRefundPayment1 | sale_refund_payments1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| InventoryMovement1 | inventory_movements1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| InventoryLot1 | inventory_lots1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| InventoryLotMovement1 | inventory_lot_movements1 | Chưa có | Chưa có file Java cùng tên; được trích từ schema, không tự khẳng định code đã triển khai lớp. |
| ItemRevenue1 | Kết quả truy vấn, không có bảng riêng | Có: ItemRevenue1.java | Java đã có class kết quả thống kê; chưa extends Item1, chưa có getItemStatistics(). Kế thừa trên hình là đề xuất cần refactor nếu triển khai. |
| RelatedTransaction1 | Kết quả truy vấn, không có bảng riêng | Có: RelatedTransaction1.java | Record kết quả bán/hoàn đã có; không có bảng riêng, không kế thừa giao dịch bán. getRelatedTransactions() là trách nhiệm đề xuất. |

## Lớp giao diện GD

| Lớp GD | Nguồn giao diện |
| --- | --- |
| GDCustomerHome1 | index.jsp khi chưa đăng nhập quản lý |
| GDMemberRegistration1 | gdMemberRegistration.jsp |
| GDManagerHome1 | index.jsp khi quản lý đã đăng nhập |
| GDStatisticsMenu1 | gdStatisticsMenu.jsp |
| GDItemStatistics1 | gdItemStatistics.jsp, gồm nhập ngày và bảng kết quả |
| GDItemDetails1 | gdItemDetails.jsp, gồm thông tin hàng và bảng giao dịch |
| GDManagerLogin1 | gdManagerLogin.jsp |

GD là tiền tố giao diện như giáo trình. Đây không phải tên các lớp Java đã được viết sẵn. Các input/output/submit là thành phần giao diện, không phải cột database. Không tạo trang kết quả đăng ký hoặc trang danh sách giao dịch mới vì code đang hiển thị chúng trên cùng trang tương ứng.

## Quan hệ

25 association/composition giữa 16 thực thể được giữ từ schema và ràng buộc nghiệp vụ. Các quan hệ bắt buộc/tùy chọn tiếp tục bao quát trạng thái nháp và trạng thái hoàn tất. Ba composition thể hiện chi tiết thuộc chứng từ, không có nghĩa mọi khóa ngoại đều ON DELETE CASCADE.

Kế thừa ItemRevenue1 → Item1 là đề xuất theo mẫu lớp thống kê của bài giảng; code hiện dùng class độc lập. RelatedTransaction1 phụ thuộc dữ liệu từ Item1, SaleTransaction1, SaleTransactionDetail1, SaleRefund1 để tạo kết quả; đây không phải các khóa ngoại mới.

Các thuộc tính id/*_id, cột cưỡng chế vai trò, revision và line_sequence là chi tiết kỹ thuật được lược khỏi ngăn thuộc tính pha phân tích; liên kết thể hiện các tham chiếu nghiệp vụ. Bảng DB vẫn có 16 bảng; hai lớp kết quả và bảy lớp GD không phải bảng mới.

Nguồn được kiểm tra là Java, JSP và schema trên đĩa. Chưa đối chiếu catalog PostgreSQL đang chạy. Đơn trực tuyến mới gắn với hồ sơ thành viên theo số điện thoại giao hàng.


Ở mức thiết kế cơ sở dữ liệu, `place_online_order1` gắn đơn vào hồ sơ thành viên theo số điện thoại. Số mới tạo hồ sơ cùng giao dịch với đơn. Ứng dụng JSP triển khai Đăng ký thành viên và Thống kê hàng hóa theo doanh thu.
