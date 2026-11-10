# Trích lớp thực thể toàn hệ thống theo mục 3.2.2

Nguồn đối chiếu: `supermarket/database/schema.sql`, bốn record trong `supermarket/src/vn/pttk/supermarket/model` và các DAO. Phân tích dựa trên schema trong dự án; chưa đối chiếu catalog của một PostgreSQL đang chạy. Java hiện triển khai hai module giao diện; schema mô tả toàn hệ thống.

Kết quả: **16 lớp thực thể lưu trữ**, **25 quan hệ**, thêm **2 lớp dữ liệu dẫn xuất** trong một sơ đồ phụ. Tất cả tên lớp bằng tiếng Anh và kết thúc bằng `1`. Sơ đồ pha phân tích không ghi kiểu dữ liệu, phương thức, ID kỹ thuật hoặc khóa ngoại dưới dạng thuộc tính; quan hệ biểu diễn các tham chiếu này.

## Bước 1 Mô tả hệ thống trong một đoạn văn

Hệ thống quản lý siêu thị trực tuyến lưu thông tin khách hàng gồm họ tên, số điện thoại, email, địa chỉ, mật khẩu và trạng thái thành viên. Nhân viên có mã nhân viên, tên đăng nhập và vai trò quản lý, kho, bán hàng hoặc giao hàng. Khách hàng đăng ký thành viên và đặt đơn hàng trực tuyến; mỗi đơn có mã đơn, ngày đặt, địa chỉ giao, số điện thoại giao, trạng thái và các chi tiết đơn hàng ghi hàng hóa, số lượng, đơn giá, giảm giá, thành tiền. Nhân viên kho quản lý hàng hóa và nhà cung cấp, lập phiếu nhập hàng cùng các chi tiết phiếu nhập, xác nhận nhập kho, xử lý đơn và phân công giao hàng. Hàng hóa có mã hàng, tên, đơn vị tính, giá hiện tại, số lượng tồn, mô tả và trạng thái sử dụng. Nhân viên bán hàng ghi giao dịch bán tại quầy; đơn trực tuyến hoàn tất cũng phát sinh giao dịch bán và các chi tiết giao dịch. Mỗi giao dịch có thể có nhiều khoản thanh toán; mỗi khoản hoàn tiền gắn với một chi tiết bán và có thể được phân bổ về các khoản thanh toán bằng các dòng phân bổ tiền hoàn. Nhập, xuất, bán tại quầy và trả hàng do hủy đơn được ghi bằng biến động tồn kho. Mặt hàng cần theo dõi lô có lô hàng thuộc chi tiết phiếu nhập, với mã lô, hạn sử dụng và số lượng nhận; phân bổ biến động theo lô ghi số lượng tăng hoặc giảm của từng lô. Nhân viên quản lý xem kết quả thống kê hàng hóa theo khoảng thời gian gồm ngày bắt đầu và ngày kết thúc, doanh thu và danh sách giao dịch liên quan. Doanh thu được tính từ tiền hàng, giảm giá và các khoản hoàn thành công. Khoản hoàn tài chính không tự động đồng nghĩa với nhập lại hàng vào tồn bán được.

## Bước 2 Trích các danh từ

| Nhóm | Danh từ |
| --- | --- |
| Con người | Khách hàng; thành viên; nhân viên; nhân viên quản lý; nhân viên kho; nhân viên bán hàng; nhân viên giao hàng; nhà cung cấp. |
| Chứng từ và đối tượng nghiệp vụ | Hàng hóa; phiếu nhập hàng; chi tiết phiếu nhập; đơn hàng trực tuyến; chi tiết đơn hàng; giao dịch bán; chi tiết giao dịch; khoản thanh toán; khoản hoàn tiền; phân bổ tiền hoàn; biến động tồn kho; lô hàng; phân bổ biến động theo lô. |
| Thông tin và giá trị | Họ tên; số điện thoại; email; địa chỉ; mật khẩu; trạng thái thành viên; mã nhân viên; tên đăng nhập; vai trò; mã đơn; ngày đặt; địa chỉ giao; số điện thoại giao; trạng thái; số lượng; đơn giá; giảm giá; thành tiền; mã hàng; tên hàng; đơn vị tính; giá hiện tại; số lượng tồn; mô tả; mã lô; hạn sử dụng; số lượng nhận; khoảng thời gian; ngày bắt đầu; ngày kết thúc; doanh thu. |
| Tập hợp và khái niệm chung | Hệ thống; siêu thị; kho; thông tin; kết quả thống kê; danh sách giao dịch. |

## Bước 3 Đánh giá danh từ và đề xuất lớp thực thể

| Danh từ | Tên lớp | Bảng nguồn | Thuộc tính phân tích |
| --- | --- | --- | --- |
| Khách hàng | Customer1 | customers1 | fullName, phone, email, address, passwordHash, isMember, createdAt |
| Nhân viên | Employee1 | employees1 | employeeCode, fullName, phone, email, role, username, passwordHash |
| Nhà cung cấp | Supplier1 | suppliers1 | supplierCode, name, phone, email, address |
| Hàng hóa | Item1 | items1 | code, name, unit, currentPrice, stockQuantity, description, active, trackLots |
| Phiếu nhập hàng | GoodsReceipt1 | goods_receipts1 | receiptCode, receivedAt, postedAt |
| Chi tiết phiếu nhập | GoodsReceiptDetail1 | goods_receipt_details1 | quantity, unitCost, /lineTotal |
| Đơn hàng trực tuyến | OnlineOrder1 | online_orders1 | orderCode, orderedAt, deliveryAddress, deliveryPhone, status |
| Chi tiết đơn hàng | OnlineOrderDetail1 | online_order_details1 | quantity, unitPrice, discountAmount, /lineTotal |
| Giao dịch bán hàng | SaleTransaction1 | sale_transactions1 | transactionCode, soldAt, channel |
| Chi tiết giao dịch bán | SaleTransactionDetail1 | sale_transaction_details1 | quantity, unitPrice, discountAmount, /lineTotal |
| Khoản thanh toán | SalePayment1 | sale_payments1 | paymentCode, method, amount, requestedAt, status, resolvedAt, externalReference |
| Khoản hoàn tiền | SaleRefund1 | sale_refunds1 | refundCode, refundedAt, quantity, refundAmount, status, resolvedAt, trackPayment |
| Phân bổ tiền hoàn | SaleRefundPayment1 | sale_refund_payments1 | amount |
| Biến động tồn kho | InventoryMovement1 | inventory_movements1 | kind, quantityDelta, occurredAt |
| Lô hàng | InventoryLot1 | inventory_lots1 | lotCode, expiresOn, receivedQuantity |
| Phân bổ biến động theo lô | InventoryLotMovement1 | inventory_lot_movements1 | quantityDelta |

### Gộp thành thuộc tính hoặc loại khỏi lớp độc lập

| Danh từ hoặc nhóm | Quyết định | Cơ sở |
| --- | --- | --- |
| Thành viên | Thuộc tính isMember của Customer1 | customers1 lưu cả khách và trạng thái thành viên; không có bảng hoặc lớp con Member1. |
| Các loại nhân viên | Thuộc tính role của Employee1 | Dùng chung employees1; không tạo bốn lớp con nếu code/database chưa có cấu trúc kế thừa. |
| Họ tên, địa chỉ, email, điện thoại | Thuộc tính | Hiện lưu trực tiếp trên các bảng; không tách Name1 hoặc Address1. |
| Số lượng tồn | Thuộc tính stockQuantity của Item1 | Không có lớp Inventory1 riêng; biến động tồn và lô có các lớp riêng. |
| Thành tiền | Thuộc tính dẫn xuất /lineTotal | Được tính bởi generated column; không tạo lớp LineTotal1. |
| Doanh thu, khoảng ngày | Giá trị dẫn xuất và tham số truy vấn | Không có bảng Revenue1 hoặc ReportingPeriod1; ngày bắt đầu/kết thúc là tham số DAO. |
| Kết quả thống kê hàng hóa | ItemRevenue1, lớp dữ liệu dẫn xuất | Record Java hiện có; đưa vào sơ đồ phụ, không tính là bảng thực thể thứ 17. |
| Dòng giao dịch liên quan | RelatedTransaction1, lớp dữ liệu dẫn xuất | Record Java gom sự kiện bán/hoàn; không thay thế SaleTransaction1 và không tạo bảng mới. |
| Thống kê nhà cung cấp, thống kê doanh thu tổng quát | Chức năng trong đề bài | Không thêm lớp kết quả giả định khi code hiện tại chưa có record tương ứng. |
| Hệ thống, siêu thị, kho, thông tin, danh sách | Loại khỏi danh sách lớp độc lập | Là ngữ cảnh, khái niệm quá chung hoặc tập hợp; không có đối tượng lưu trữ độc lập tương ứng. |
| DAO, JSP, Database1, Html1, PasswordHash1 | Không thuộc sơ đồ lớp thực thể | Là truy cập dữ liệu, giao diện hoặc tiện ích kỹ thuật; thuộc mô hình lớp/module khác. |

### Đối chiếu với Java hiện có

Chỉ Customer1 và Item1 trong 16 lớp thực thể đã có record Java cùng tên; thuộc tính phân tích được bổ sung từ bảng. 14 tên lớp còn lại là đề xuất phân tích từ database, không phải khẳng định đã có 14 file Java. ItemRevenue1 và RelatedTransaction1 là hai record kết quả truy vấn hiện có, không có bảng riêng. Item1.code ánh xạ items1.item_code.

| Record dẫn xuất | Thuộc tính |
| --- | --- |
| ItemRevenue1 | code, name, unit, supplierLabels, quantity, returnedQuantity, transactionCount, grossAmount, discountAmount, refundAmount, /revenue |
| RelatedTransaction1 | code, originalSaleCode, occurredAt, channel, refund, quantity, unitPrices, grossAmount, discountAmount, refundAmount, transactionTotal, /itemAmount |

Các cột id, các *_id, required_*_role, settlement_revision và line_sequence không đưa vào ô thuộc tính phân tích. Các khóa ngoại được chuyển thành liên kết; required_*_role là cơ chế cưỡng chế vai trò; settlement_revision và line_sequence phục vụ xử lý kỹ thuật. Các thuộc tính bắt đầu bằng / là dẫn xuất.

## Bước 4 Xác định quan hệ số lượng

Bội số ghi cạnh một lớp là số đối tượng của lớp đó ứng với một đối tượng ở đầu còn lại. 0..* có thể chưa có; 1..* có ít nhất một; 0..1 là tùy chọn tối đa một.

| Mã | Lớp A | Bội số tại A | Lớp B | Bội số tại B | Ý nghĩa |
| --- | --- | --- | --- | --- | --- |
| R01 | Customer1 | 1 | OnlineOrder1 | 0..* | Mỗi đơn có đúng một khách hàng; khách hàng có thể chưa đặt đơn. |
| R02 | Supplier1 | 1 | GoodsReceipt1 | 0..* | Mỗi phiếu nhập thuộc đúng một nhà cung cấp. |
| R03 | Employee1 | 1 | GoodsReceipt1 | 0..* | Mỗi phiếu nhập có một nhân viên kho, role = WAREHOUSE. |
| R04 | GoodsReceipt1 | 1 | GoodsReceiptDetail1 | 0..* | Phiếu nháp có thể rỗng; phiếu xác nhận phải có ít nhất một chi tiết. |
| R05 | Item1 | 1 | GoodsReceiptDetail1 | 0..* | Mỗi chi tiết nhập gắn với đúng một hàng hóa. |
| R06 | GoodsReceiptDetail1 | 1 | InventoryLot1 | 0..* | Mỗi lô thuộc một chi tiết nhập; hàng không theo lô có thể không có lô. |
| R07 | Employee1 | 0..1 | OnlineOrder1 | 0..* | Đơn PENDING có thể chưa phân công; xuất hàng phải có nhân viên kho. |
| R08 | Employee1 | 0..1 | OnlineOrder1 | 0..* | Đơn PENDING có thể chưa phân công; xuất hàng phải có nhân viên giao. |
| R09 | OnlineOrder1 | 1 | OnlineOrderDetail1 | 0..* | Đơn nháp PENDING có thể rỗng; xuất hàng yêu cầu ít nhất một dòng. |
| R10 | Item1 | 1 | OnlineOrderDetail1 | 0..* | Một hàng hóa có thể có mặt trong nhiều chi tiết đơn. |
| R11 | OnlineOrder1 | 0..1 | SaleTransaction1 | 0..1 | Đơn COMPLETED có đúng một giao dịch ONLINE. Giao dịch COUNTER không gắn đơn. |
| R12 | Employee1 | 0..1 | SaleTransaction1 | 0..* | COUNTER bắt buộc có nhân viên role SALER; ONLINE không có saler_id. |
| R13 | Customer1 | 0..1 | SaleTransaction1 | 0..* | Liên kết trực tiếp chỉ dành cho khách thành viên mua COUNTER; khách ONLINE qua OnlineOrder1. |
| R14 | SaleTransaction1 | 1 | SaleTransactionDetail1 | 1..* | Constraint trigger kiểm tra ít nhất một dòng khi kết thúc giao dịch SQL. |
| R15 | Item1 | 1 | SaleTransactionDetail1 | 0..* | Một hàng hóa có thể xuất hiện nhiều dòng theo các đơn giá khác nhau. |
| R16 | SaleTransaction1 | 1 | SalePayment1 | 0..* | Một giao dịch có thể chưa có khoản thu hoặc có nhiều lần thu. |
| R17 | SaleTransactionDetail1 | 1 | SaleRefund1 | 0..* | Mỗi khoản hoàn tham chiếu đúng một dòng bán gốc. |
| R18 | SaleRefund1 | 1 | SaleRefundPayment1 | 0..* | Khoản hoàn cũ có thể không phân bổ; khoản hoàn có theo dõi thanh toán phải phân bổ đủ tiền. |
| R19 | SalePayment1 | 1 | SaleRefundPayment1 | 0..* | Mỗi dòng phân bổ gắn đúng một khoản thanh toán của cùng giao dịch bán. |
| R20 | Item1 | 1 | InventoryMovement1 | 1..* | Trigger tạo OPENING cho hàng mới; dữ liệu nâng cấp cũng được bổ sung OPENING. |
| R21 | GoodsReceipt1 | 0..1 | InventoryMovement1 | 0..* | Chỉ kind RECEIPT có nguồn phiếu nhập. |
| R22 | OnlineOrder1 | 0..1 | InventoryMovement1 | 0..* | Chỉ kind DISPATCH hoặc RETURN có nguồn đơn hàng. |
| R23 | SaleTransaction1 | 0..1 | InventoryMovement1 | 0..* | Chỉ kind COUNTER_SALE có nguồn giao dịch bán tại quầy. |
| R24 | InventoryMovement1 | 1 | InventoryLotMovement1 | 0..* | Một biến động có thể không theo lô hoặc phân bổ vào nhiều lô. |
| R25 | InventoryLot1 | 1 | InventoryLotMovement1 | 0..* | Một lô có thể chưa phát sinh biến động hoặc có nhiều phân bổ. |

### Tách các quan hệ nhiều nhiều

| Quan hệ n-n | Lớp trung gian | Thông tin liên kết |
| --- | --- | --- |
| GoodsReceipt1 - Item1 | GoodsReceiptDetail1 | Lưu quantity, unitCost và /lineTotal. |
| OnlineOrder1 - Item1 | OnlineOrderDetail1 | Lưu quantity, unitPrice, discountAmount và /lineTotal. |
| SaleTransaction1 - Item1 | SaleTransactionDetail1 | Lưu quantity, unitPrice, discountAmount; cùng hàng hóa có thể có các dòng đơn giá khác nhau. |
| SaleRefund1 - SalePayment1 | SaleRefundPayment1 | Lưu số tiền phân bổ amount cho mỗi cặp khoản hoàn - khoản thu. |
| InventoryMovement1 - InventoryLot1 | InventoryLotMovement1 | Lưu quantityDelta cho mỗi cặp biến động - lô. |

Nhà cung cấp - hàng hóa được truy vết qua Supplier1 - GoodsReceipt1 - GoodsReceiptDetail1 - Item1. Không thêm SupplierItem1 vì schema hiện tại không có quan hệ danh mục cung ứng trực tiếp này.

## Bước 5 Xác định quan hệ đối tượng

- Ba quan hệ composition: GoodsReceipt1 - GoodsReceiptDetail1, OnlineOrder1 - OnlineOrderDetail1, SaleTransaction1 - SaleTransactionDetail1. Chi tiết là bộ phận của đúng một chứng từ. Đây là sở hữu trong mô hình miền, không có nghĩa database dùng ON DELETE CASCADE.
- Các quan hệ còn lại giữa 16 lớp lưu trữ là association. Không suy ra aggregation chỉ vì có khóa ngoại.
- Không thêm generalization giữa Customer1 và Employee1, giữa các vai trò nhân viên, hoặc giữa các record báo cáo và lớp thực thể, vì code/database hiện tại không triển khai kế thừa đó. Bài giảng có ví dụ lớp thống kê kế thừa; ở hệ thống này record Java dùng dữ liệu phẳng nên biểu diễn dependency ở sơ đồ phụ.
- SaleRefundPayment1 và InventoryLotMovement1 là các lớp liên kết có thuộc tính riêng. Các quan hệ n-n đã được tách thành các quan hệ 1-n qua lớp trung gian.
- Customer1 - SaleTransaction1 là liên kết trực tiếp tùy chọn cho thành viên mua tại quầy. Khách mua trực tuyến được xác định qua OnlineOrder1; không vẽ một liên kết trực tiếp bắt buộc cho mọi giao dịch.
- OnlineOrder1 - SaleTransaction1 là 0..1 ở cả hai đầu trong toàn bộ mô hình; đơn COMPLETED bắt buộc có đúng một giao dịch ONLINE. Giao dịch COUNTER không có đơn trực tuyến.
- Employee1 có các vai trò warehouseStaff, deliveryStaff và saler trên các liên kết khác nhau. Khi xuất đơn phải có đủ nhân viên kho và giao hàng; giao dịch COUNTER phải có nhân viên bán hàng.
- InventoryMovement1 có nguồn theo kind: OPENING không có chứng từ nguồn; RECEIPT chỉ có phiếu nhập; DISPATCH/RETURN chỉ có đơn; COUNTER_SALE chỉ có giao dịch tại quầy. Ba nguồn không đồng thời tồn tại.
- Mỗi Item1 có ít nhất một InventoryMovement1 vì trigger khởi tạo OPENING. Phiếu nhập và đơn hàng nháp có thể chưa có dòng; khi xác nhận phiếu hoặc xuất đơn phải có ít nhất một dòng.
- Hoàn tiền có theo dõi thanh toán phải phân bổ đủ tổng tiền về các khoản thu thành công của cùng giao dịch; các khoản hoàn cũ có thể không có dòng phân bổ. Hoàn tiền không tự động tăng tồn kho.
- Lô hàng tham chiếu chi tiết phiếu nhập bằng cặp (receipt_id, item_id); không rút gọn sai thành quan hệ lô - phiếu nhập mà bỏ hàng hóa của dòng nhập.

## Các sơ đồ trong file Visual Paradigm

- 0. Phan tich 5 buoc - 3.2.2
- 1. Entity model - Full system
- 2. Purchasing and suppliers
- 3. Online orders and sales
- 4. Payments and refunds
- 5. Inventory and lots
- 6. Derived report data - Java records

Sơ đồ 1 chứa đầy đủ 16 lớp và 25 quan hệ. Sơ đồ 2-5 là các góc nhìn của cùng mô hình, không tạo bản sao lớp. Sơ đồ 6 biểu diễn dependency của hai record báo cáo; không tính chúng là bảng thứ 17 và 18.

## Nguồn

- Bài giảng `BG HP TTTN 2 CNPM 2020 final.pdf`, mục 3.2.2, trang in 72-76.
- `supermarket/database/schema.sql`.
- `supermarket/src/vn/pttk/supermarket/model/*.java`.
- `supermarket/src/vn/pttk/supermarket/dao/ItemRevenueDAO1.java`, `CustomerDAO1.java`, `ManagerDAO1.java`.
