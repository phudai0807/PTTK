# Đối chiếu sơ đồ lớp thực thể với hệ thống

Bản bàn giao: `Sieu-thi-Lop-thuc-the-Giao-Trinh.vpp`. Sơ đồ 1 biểu diễn toàn bộ mô hình thực thể; sơ đồ 2–5 phóng tách theo nghiệp vụ và dùng chung các lớp, quan hệ; sơ đồ 6 dành cho dữ liệu báo cáo. Trang 0 giữ nội dung phân tích theo 5 bước mục 3.2.2.

## Sơ đồ đã khớp thiết kế hiện tại chưa?

**Khớp ở mức mô hình lớp thực thể phân tích dựa trên schema của dự án. Chưa đồng nhất từng lớp, từng trường với phần Java đã cài đặt.**

| Nội dung | Kết quả đối chiếu |
| --- | --- |
| Các thực thể lưu trữ | 16 lớp tương ứng 16 bảng trong `supermarket/database/schema.sql`; bảng đối chiếu chi tiết có trong bản phân tích 5 bước. |
| Quan hệ | 25 liên kết giữa các lớp thực thể; tham chiếu khóa ngoại được chuyển thành liên kết, có bội số ở hai đầu. |
| Các dòng chi tiết | GoodsReceiptDetail1, OnlineOrderDetail1, SaleTransactionDetail1 được giữ riêng, có thuộc tính số lượng và đơn giá; composition đặt hình thoi đen ở đầu chứng từ. |
| Vai trò nhân viên | Dùng Employee1.role và các liên kết warehouseStaff, deliveryStaff, saler; không dựng thêm các lớp kế thừa mà hệ thống chưa có. |
| Thành viên | Thể hiện bằng Customer1.isMember; không tạo thêm bảng/lớp Member1. |
| Dữ liệu báo cáo | ItemRevenue1 và RelatedTransaction1 là các record kết quả truy vấn trong Java; tách ở sơ đồ 6, không tính là hai bảng mới. |
| Java đã có | Bốn record Customer1, Item1, ItemRevenue1, RelatedTransaction1. Trong 16 lớp thực thể, Customer1 và Item1 có record Java; 14 lớp còn lại được phân tích từ bảng, chưa có file Java tương ứng. |
| Thuộc tính Customer1 và Item1 | Sơ đồ tổng thể bổ sung thuộc tính từ schema. Ví dụ Item1 có currentPrice, stockQuantity, active, trackLots; record Item1.java hiện chỉ có id, code, name, unit, description. |

## Quy ước trình bày theo pha phân tích

- Tên lớp bằng tiếng Anh, kết thúc bằng số `1`; các ô lớp chia tên lớp và ngăn thuộc tính.
- Mỗi thuộc tính có dấu `-` (private) bằng cơ chế visibility của UML, không thêm ký tự này vào tên thuộc tính trong model. Đây là quy ước trên sơ đồ; không sửa các record Java.
- Thuộc tính tính toán có thêm `/`, ví dụ `- /lineTotal` và `- /revenue`.
- Bỏ kiểu dữ liệu, phương thức, ID kỹ thuật và các cột khóa ngoại khỏi ngăn thuộc tính của sơ đồ phân tích; khóa ngoại được biểu diễn bằng quan hệ.
- Một số cột phục vụ ràng buộc kỹ thuật như required_*_role, settlement_revision và line_sequence được lược khỏi sơ đồ phân tích. Vì vậy đây không phải bản sao vật lý toàn bộ các cột database.
- Composition biểu diễn sự phụ thuộc nghiệp vụ của dòng chi tiết vào chứng từ; không có nghĩa mọi khóa ngoại đều dùng ON DELETE CASCADE.

## Giới hạn khi đọc bội số

Phiếu nhập/đơn đang nháp có thể có 0 dòng; khi xác nhận hoặc xuất hàng thì phải có chi tiết. Đơn COMPLETED phải có một giao dịch ONLINE. Liên kết trực tiếp giữa Customer1 và SaleTransaction1 chỉ dành cho khách thành viên mua tại quầy; khách mua online đi qua OnlineOrder1. Các liên kết nguồn của InventoryMovement1 phụ thuộc kind và loại trừ nhau, không phải mọi biến động đều đồng thời có phiếu nhập, đơn và giao dịch bán.

Nguồn đối chiếu là schema và code trên đĩa. Chưa kiểm tra catalog của PostgreSQL đang chạy. Việc chỉnh sơ đồ không thay đổi code hoặc schema của ứng dụng.
