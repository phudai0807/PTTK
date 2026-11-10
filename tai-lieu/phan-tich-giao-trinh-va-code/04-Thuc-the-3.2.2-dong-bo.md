# Mô hình thực thể tham chiếu 3.2.2 dùng chung cho hai module

## Bước 1: Mô tả hệ thống

Hệ thống siêu thị quản lý khách hàng, nhân viên, nhà cung cấp, hàng hóa, nhập hàng, đơn trực tuyến, giao dịch bán, thanh toán, hoàn tiền và tồn kho theo lô. Khách hàng đăng ký thành viên, tìm hàng, đặt online hoặc mua tại quầy. Nhân viên kho quản lý hàng/nhà cung cấp, nhập hàng và xử lý đơn; nhân viên bán hàng ghi giao dịch tại quầy; quản lý xem thống kê và giao dịch liên quan. Các chứng từ có chi tiết hàng hóa, số lượng, đơn giá và tiền; thống kê tổng hợp dữ liệu bán và hoàn theo kỳ.

## Bước 2: Trích danh từ

Khách hàng, thành viên, nhân viên, vai trò, nhà cung cấp, hàng hóa, phiếu nhập, chi tiết nhập, đơn hàng, chi tiết đơn, giao dịch bán, chi tiết bán, thanh toán, hoàn tiền, phân bổ hoàn, biến động tồn, lô, phân bổ theo lô, thống kê hàng hóa, dòng giao dịch liên quan, họ tên, địa chỉ, điện thoại, email, mật khẩu, mã, ngày, trạng thái, số lượng, đơn giá, thành tiền và doanh thu.

## Bước 3: Đánh giá và đề xuất lớp/thuộc tính

| Lớp | Nguồn dữ liệu | Thuộc tính phân tích |
| --- | --- | --- |
| Customer1 | customers1 | fullName, phone, email, address, passwordHash, isMember, createdAt |
| Employee1 | employees1 | employeeCode, fullName, phone, email, role, username, passwordHash |
| Supplier1 | suppliers1 | supplierCode, name, phone, email, address |
| Item1 | items1 | code, name, unit, currentPrice, stockQuantity, description, active, trackLots |
| GoodsReceipt1 | goods_receipts1 | receiptCode, receivedAt, postedAt |
| GoodsReceiptDetail1 | goods_receipt_details1 | quantity, unitCost, /lineTotal |
| OnlineOrder1 | online_orders1 | orderCode, orderedAt, deliveryAddress, deliveryPhone, status |
| OnlineOrderDetail1 | online_order_details1 | quantity, unitPrice, discountAmount, /lineTotal |
| SaleTransaction1 | sale_transactions1 | transactionCode, soldAt, channel |
| SaleTransactionDetail1 | sale_transaction_details1 | quantity, unitPrice, discountAmount, /lineTotal |
| SalePayment1 | sale_payments1 | paymentCode, method, amount, requestedAt, status, resolvedAt, externalReference |
| SaleRefund1 | sale_refunds1 | refundCode, refundedAt, quantity, refundAmount, status, resolvedAt, trackPayment |
| SaleRefundPayment1 | sale_refund_payments1 | amount |
| InventoryMovement1 | inventory_movements1 | kind, quantityDelta, occurredAt |
| InventoryLot1 | inventory_lots1 | lotCode, expiresOn, receivedQuantity |
| InventoryLotMovement1 | inventory_lot_movements1 | quantityDelta |
| ItemRevenue1 | Kết quả tổng hợp/truy vấn, không có bảng riêng | supplierLabels, quantity, returnedQuantity, transactionCount, grossAmount, discountAmount, refundAmount, /revenue |
| RelatedTransaction1 | Kết quả tổng hợp/truy vấn, không có bảng riêng | code, originalSaleCode, occurredAt, channel, refund, quantity, unitPrices, grossAmount, discountAmount, refundAmount, transactionTotal, /itemAmount |

Thành viên được thể hiện bằng isMember, vai trò nhân viên bằng role. Các thông tin họ tên/địa chỉ giữ làm thuộc tính; các từ chung như hệ thống, thông tin, danh sách không tạo lớp riêng. ID kỹ thuật và kiểu dữ liệu được lược trên hình phân tích. Các lớp GD được trích ở mục 3.2.3, không phải bảng dữ liệu.

## Bước 4: Xác định quan hệ số lượng

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

Tách n-n bằng GoodsReceiptDetail1, OnlineOrderDetail1, SaleTransactionDetail1, SaleRefundPayment1 và InventoryLotMovement1. Phiếu/đơn nháp có thể rỗng; trạng thái xác nhận/xuất phải có chi tiết. Một giao dịch bán có ít nhất một dòng. Các nguồn phiếu nhập/đơn/giao dịch của biến động tồn phụ thuộc kind và không đồng thời có đủ cả ba.

## Bước 5: Xác định quan hệ đối tượng

- Composition: phiếu nhập–chi tiết nhập, đơn–chi tiết đơn, giao dịch bán–chi tiết bán; hình thoi đen ở đầu chứng từ.
- Association: các liên kết nghiệp vụ còn lại giữa 16 thực thể.
- Generalization: lớp thống kê ItemRevenue1 kế thừa Item1 theo cách đề xuất trong mẫu bài giảng. Đây là thiết kế phân tích, chưa phải quan hệ Java hiện có; xem tài liệu 03 để refactor khi triển khai.
- Dependency: RelatedTransaction1 dùng dữ liệu Item1, SaleTransaction1, SaleTransactionDetail1, SaleRefund1 để tạo các dòng kết quả; không thêm khóa ngoại hoặc ép kế thừa.

Trang 0.1 của VPP là mô hình tham chiếu này và ẩn phương thức như pha 3.2.2. Các trang 1.3/2.3 dùng lại các lớp, bổ sung phương thức phân tích theo 3.2.3. Tổng 18 lớp dữ liệu/nghiệp vụ gồm 16 thực thể lưu trữ và 2 lớp kết quả; database vẫn 16 bảng.
