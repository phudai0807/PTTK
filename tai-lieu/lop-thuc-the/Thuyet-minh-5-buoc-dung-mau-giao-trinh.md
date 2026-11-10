# Trích lớp thực thể của hệ thống quản lý siêu thị trực tuyến

Thực hiện theo phương pháp trích danh từ tại mục 3.2.2 của bài giảng. Nội dung dưới đây tương ứng với sơ đồ `Sieu-thi-Lop-thuc-the-Theo-Mau-Bai-Giang.vpp`. Tên lớp dùng tiếng Anh và kết thúc bằng số `1`.

## Bước 1: Mô tả hệ thống trong một đoạn văn

Hệ thống quản lý siêu thị trực tuyến cho phép khách hàng đăng ký thành viên, tìm kiếm hàng hóa, đặt hàng trực tuyến và mua hàng trực tiếp tại quầy. Thông tin khách hàng gồm họ tên, điện thoại, email, địa chỉ, mật khẩu được lưu dưới dạng băm, trạng thái thành viên và thời điểm tạo. Nhân viên có mã nhân viên, họ tên, điện thoại, email, tên đăng nhập, mật khẩu và vai trò quản lý, kho, bán hàng hoặc giao hàng. Nhân viên kho quản lý thông tin hàng hóa và nhà cung cấp, nhập hàng từ nhà cung cấp, duyệt đơn trực tuyến và chuyển hàng cho nhân viên giao hàng. Nhà cung cấp có mã, tên, điện thoại, email và địa chỉ; hàng hóa có mã, tên, đơn vị tính, giá hiện tại, số lượng tồn, mô tả, trạng thái sử dụng và trạng thái theo dõi lô. Mỗi lần nhập được lập thành phiếu nhập, gồm mã phiếu, thời điểm nhập, thời điểm xác nhận và các chi tiết ghi hàng hóa, số lượng, giá nhập, thành tiền. Đơn trực tuyến có mã đơn, ngày đặt, địa chỉ giao, điện thoại giao, trạng thái và các chi tiết ghi hàng hóa, số lượng, đơn giá, giảm giá, thành tiền. Nhân viên bán hàng ghi nhận giao dịch tại quầy; đơn trực tuyến hoàn tất cũng có giao dịch bán. Giao dịch có mã, thời điểm bán, kênh bán và các chi tiết hàng hóa. Hệ thống ghi nhận các khoản thanh toán, khoản hoàn tiền và phân bổ tiền hoàn về khoản thanh toán gốc. Nhập, xuất, bán tại quầy và trả hàng do hủy đơn được ghi nhận bằng biến động tồn kho. Hàng hóa cần theo dõi lô có mã lô, hạn sử dụng, số lượng nhận và các phân bổ biến động theo lô. Nhân viên quản lý xem thống kê hàng hóa, nhà cung cấp và doanh thu; với thống kê hàng hóa theo doanh thu, nhân viên chọn ngày bắt đầu, ngày kết thúc, xem kết quả và danh sách giao dịch liên quan đến từng hàng hóa. Kết quả thống kê thể hiện nhà cung cấp, số lượng bán, số lượng hoàn, số giao dịch, tiền hàng, giảm giá, tiền hoàn và doanh thu.

## Bước 2: Trích các danh từ xuất hiện trong đoạn văn

- Các danh từ liên quan đến người và tổ chức: khách hàng, thành viên, nhân viên, nhân viên quản lý, nhân viên kho, nhân viên bán hàng, nhân viên giao hàng, nhà cung cấp.
- Các danh từ liên quan đến hàng hóa và chứng từ: hàng hóa, phiếu nhập, chi tiết phiếu nhập, đơn trực tuyến, chi tiết đơn, giao dịch bán, chi tiết giao dịch bán, khoản thanh toán, khoản hoàn tiền, phân bổ tiền hoàn, biến động tồn kho, lô hàng, phân bổ biến động theo lô.
- Các danh từ liên quan đến thông tin: họ tên, điện thoại, email, địa chỉ, mật khẩu, trạng thái thành viên, thời điểm tạo, mã nhân viên, tên đăng nhập, vai trò, mã hàng, tên hàng, đơn vị tính, giá hiện tại, số lượng tồn, mô tả, trạng thái sử dụng, trạng thái theo dõi lô, mã phiếu, thời điểm nhập, thời điểm xác nhận, số lượng, giá nhập, thành tiền, mã đơn, ngày đặt, địa chỉ giao, điện thoại giao, trạng thái đơn, đơn giá, giảm giá, mã giao dịch, thời điểm bán, kênh bán, mã lô, hạn sử dụng, số lượng nhận, ngày bắt đầu, ngày kết thúc, số lượng bán, số lượng hoàn, số giao dịch, tiền hàng, tiền hoàn, doanh thu.
- Các danh từ chỉ chức năng, tập hợp hoặc khái niệm chung: hệ thống, siêu thị, kho, thông tin, kết quả thống kê, thống kê hàng hóa, thống kê nhà cung cấp, thống kê doanh thu, danh sách giao dịch.

## Bước 3: Đánh giá và lựa chọn các danh từ làm lớp thực thể hoặc thuộc tính

Các danh từ trừu tượng như hệ thống, siêu thị, thông tin, kết quả và danh sách không đề xuất thành lớp thực thể độc lập. Kho được xem là ngữ cảnh quản lý tồn; hệ thống hiện chưa quản lý các đơn vị kho riêng.

Các danh từ liên quan đến người và tổ chức:

- Khách hàng → lớp `Customer1`: `fullName`, `phone`, `email`, `address`, `passwordHash`, `isMember`, `createdAt`.
- Thành viên → trạng thái `isMember` của `Customer1`; không đề xuất thêm lớp thành viên riêng.
- Nhân viên → lớp `Employee1`: `employeeCode`, `fullName`, `phone`, `email`, `role`, `username`, `passwordHash`.
- Nhân viên quản lý, kho, bán hàng, giao hàng → các giá trị của thuộc tính `role` trong `Employee1`; phân biệt vai trò xử lý trên các liên kết nghiệp vụ.
- Nhà cung cấp → lớp `Supplier1`: `supplierCode`, `name`, `phone`, `email`, `address`.

Các danh từ liên quan đến hàng hóa, chứng từ và thông tin nghiệp vụ:

- Hàng hóa → lớp `Item1`: `code`, `name`, `unit`, `currentPrice`, `stockQuantity`, `description`, `active`, `trackLots`.
- Phiếu nhập → lớp `GoodsReceipt1`: `receiptCode`, `receivedAt`, `postedAt`.
- Chi tiết phiếu nhập → lớp `GoodsReceiptDetail1`: `quantity`, `unitCost`, `/lineTotal`.
- Đơn trực tuyến → lớp `OnlineOrder1`: `orderCode`, `orderedAt`, `deliveryAddress`, `deliveryPhone`, `status`.
- Chi tiết đơn → lớp `OnlineOrderDetail1`: `quantity`, `unitPrice`, `discountAmount`, `/lineTotal`.
- Giao dịch bán → lớp `SaleTransaction1`: `transactionCode`, `soldAt`, `channel`.
- Chi tiết giao dịch bán → lớp `SaleTransactionDetail1`: `quantity`, `unitPrice`, `discountAmount`, `/lineTotal`.
- Khoản thanh toán → lớp `SalePayment1`: `paymentCode`, `method`, `amount`, `requestedAt`, `status`, `resolvedAt`, `externalReference`.
- Khoản hoàn tiền → lớp `SaleRefund1`: `refundCode`, `refundedAt`, `quantity`, `refundAmount`, `status`, `resolvedAt`, `trackPayment`.
- Phân bổ tiền hoàn → lớp `SaleRefundPayment1`: `amount`.
- Biến động tồn kho → lớp `InventoryMovement1`: `kind`, `quantityDelta`, `occurredAt`.
- Lô hàng → lớp `InventoryLot1`: `lotCode`, `expiresOn`, `receivedQuantity`.
- Phân bổ biến động theo lô → lớp `InventoryLotMovement1`: `quantityDelta`.
- Thống kê hàng hóa → lớp `ItemStatistics1`: kế thừa `Item1`, bổ sung `supplierLabels`, `quantity`, `returnedQuantity`, `transactionCount`, `grossAmount`, `discountAmount`, `refundAmount`, `/revenue`.

Các danh từ thông tin còn lại được xử lý như sau:

- Họ tên, địa chỉ, điện thoại, email → thuộc tính của khách hàng, nhân viên hoặc nhà cung cấp; giữ theo cấu trúc dữ liệu hiện tại, không tách lớp riêng.
- Số lượng tồn → thuộc tính `stockQuantity` của `Item1`.
- Thành tiền → thuộc tính dẫn xuất `/lineTotal` của các lớp chi tiết; không đề xuất lớp thành tiền.
- Doanh thu → thuộc tính dẫn xuất `/revenue` của `ItemStatistics1`, được tính từ tiền hàng trừ giảm giá và tiền hoàn.
- Ngày bắt đầu, ngày kết thúc → điều kiện tra cứu thống kê; không đề xuất thành lớp thực thể.
- Danh sách giao dịch liên quan → tập kết quả truy vấn từ giao dịch bán và hoàn tiền; không tạo thêm thực thể lưu trữ.
- Thống kê nhà cung cấp và thống kê doanh thu → các chức năng khai thác dữ liệu; sơ đồ hiện tại chưa đề xuất lớp thống kê chuyên biệt cho hai chức năng này.

Kết quả đề xuất 17 lớp phân tích: 16 thực thể lưu trữ và 1 lớp thống kê. Theo quy ước trình bày của pha phân tích, chưa ghi kiểu dữ liệu, ID kỹ thuật và phương thức; trên sơ đồ, mỗi thuộc tính có dấu `-`, thuộc tính dẫn xuất có thêm dấu `/`.

## Bước 4: Xác định quan hệ số lượng giữa các thực thể

Các quan hệ nhiều–nhiều được tách qua lớp trung gian:

- Một phiếu nhập có nhiều hàng hóa, một hàng hóa có thể được nhập trong nhiều phiếu → `GoodsReceipt1` – `Item1` là n–n → đề xuất `GoodsReceiptDetail1`. Mỗi chi tiết thuộc đúng một phiếu và một hàng hóa; mỗi phiếu hoặc hàng hóa có `0..*` chi tiết nhập.
- Một đơn có nhiều hàng hóa, một hàng hóa có thể xuất hiện trong nhiều đơn → `OnlineOrder1` – `Item1` là n–n → đề xuất `OnlineOrderDetail1`. Mỗi chi tiết thuộc đúng một đơn và một hàng hóa; mỗi đơn hoặc hàng hóa có `0..*` chi tiết đơn.
- Một giao dịch bán có nhiều hàng hóa, một hàng hóa có thể được bán trong nhiều giao dịch → `SaleTransaction1` – `Item1` là n–n → đề xuất `SaleTransactionDetail1`. Mỗi giao dịch có `1..*` chi tiết; mỗi hàng hóa có `0..*` chi tiết bán; mỗi chi tiết thuộc đúng một giao dịch và một hàng hóa.
- Một khoản hoàn có thể phân bổ về nhiều khoản thanh toán, một khoản thanh toán có thể được sử dụng cho nhiều khoản hoàn → `SaleRefund1` – `SalePayment1` là n–n → đề xuất `SaleRefundPayment1`. Mỗi khoản hoàn hoặc khoản thanh toán có `0..*` dòng phân bổ; mỗi dòng gắn đúng một khoản hoàn và một khoản thanh toán.
- Một biến động có thể phân bổ vào nhiều lô, một lô có thể tham gia nhiều biến động → `InventoryMovement1` – `InventoryLot1` là n–n → đề xuất `InventoryLotMovement1`. Mỗi biến động hoặc lô có `0..*` dòng phân bổ; mỗi dòng gắn đúng một biến động và một lô.

Các quan hệ số lượng khác:

- Một khách hàng có thể đặt nhiều đơn; mỗi đơn thuộc đúng một khách hàng → `Customer1 (1)` – `OnlineOrder1 (0..*)`.
- Một nhà cung cấp có thể có nhiều phiếu nhập; mỗi phiếu thuộc đúng một nhà cung cấp → `Supplier1 (1)` – `GoodsReceipt1 (0..*)`.
- Một nhân viên kho có thể lập nhiều phiếu nhập; mỗi phiếu do một nhân viên kho phụ trách → `Employee1 (1)` – `GoodsReceipt1 (0..*)`.
- Một chi tiết nhập có thể có nhiều lô; mỗi lô thuộc đúng một chi tiết nhập → `GoodsReceiptDetail1 (1)` – `InventoryLot1 (0..*)`.
- Một nhân viên kho có thể xử lý nhiều đơn; mỗi đơn có tối đa một nhân viên kho phụ trách → `Employee1 (0..1)` – `OnlineOrder1 (0..*)`, vai trò `warehouseStaff`.
- Một nhân viên giao hàng có thể nhận nhiều đơn; mỗi đơn có tối đa một nhân viên giao hàng → `Employee1 (0..1)` – `OnlineOrder1 (0..*)`, vai trò `deliveryStaff`.
- Một đơn có tối đa một giao dịch bán; một giao dịch có thể không gắn đơn trực tuyến → `OnlineOrder1 (0..1)` – `SaleTransaction1 (0..1)`.
- Một nhân viên bán hàng có thể thực hiện nhiều giao dịch; mỗi giao dịch có tối đa một nhân viên bán hàng → `Employee1 (0..1)` – `SaleTransaction1 (0..*)`, vai trò `saler`.
- Một khách hàng thành viên có thể có nhiều giao dịch tại quầy; mỗi giao dịch tại quầy có thể không gắn khách thành viên → `Customer1 (0..1)` – `SaleTransaction1 (0..*)`.
- Một giao dịch có thể có nhiều khoản thanh toán; mỗi khoản thanh toán thuộc đúng một giao dịch → `SaleTransaction1 (1)` – `SalePayment1 (0..*)`.
- Một chi tiết bán có thể phát sinh nhiều khoản hoàn; mỗi khoản hoàn gắn đúng một chi tiết bán gốc → `SaleTransactionDetail1 (1)` – `SaleRefund1 (0..*)`.
- Một hàng hóa có các biến động tồn; mỗi biến động thuộc đúng một hàng hóa → `Item1 (1)` – `InventoryMovement1 (1..*)`. Mô hình hiện tại ghi cả biến động khởi tạo tồn.
- Một phiếu nhập có thể phát sinh nhiều biến động; một biến động có thể không có nguồn phiếu nhập → `GoodsReceipt1 (0..1)` – `InventoryMovement1 (0..*)`.
- Một đơn có thể phát sinh nhiều biến động; một biến động có thể không có nguồn đơn → `OnlineOrder1 (0..1)` – `InventoryMovement1 (0..*)`.
- Một giao dịch tại quầy có thể phát sinh nhiều biến động; một biến động có thể không có nguồn giao dịch tại quầy → `SaleTransaction1 (0..1)` – `InventoryMovement1 (0..*)`.

Các bội số trên bao quát cả trạng thái chưa hoàn tất: phiếu nhập và đơn nháp có thể chưa có chi tiết; khi xác nhận phiếu nhập hoặc xuất đơn phải có ít nhất một chi tiết. Đơn hoàn tất phải có một giao dịch bán trực tuyến. Giao dịch tại quầy phải có nhân viên bán hàng; khách mua trực tuyến được xác định qua đơn hàng, không qua liên kết khách hàng trực tiếp trên giao dịch. Các nguồn phiếu nhập, đơn hàng và giao dịch tại quầy của biến động tồn được chọn theo loại biến động, không đồng thời gắn cả ba.

## Bước 5: Xác định quan hệ đối tượng giữa các thực thể

- `GoodsReceiptDetail1` là bộ phận gắn chặt với `GoodsReceipt1` → quan hệ composition; hình thoi đen ở đầu `GoodsReceipt1`.
- `OnlineOrderDetail1` là bộ phận gắn chặt với `OnlineOrder1` → quan hệ composition; hình thoi đen ở đầu `OnlineOrder1`.
- `SaleTransactionDetail1` là bộ phận gắn chặt với `SaleTransaction1` → quan hệ composition; hình thoi đen ở đầu `SaleTransaction1`.
- `ItemStatistics1` kế thừa `Item1`, bổ sung thông tin thống kê → quan hệ generalization; tam giác rỗng hướng về `Item1`. Không ghi lặp các thuộc tính đã kế thừa và không ghi bội số trên quan hệ này.
- Khách hàng liên kết với đơn trực tuyến và giao dịch thành viên tại quầy; nhân viên liên kết với phiếu nhập, đơn và giao dịch bán theo vai trò; nhà cung cấp liên kết với phiếu nhập → quan hệ association.
- Hàng hóa liên kết với chi tiết nhập, chi tiết đơn, chi tiết bán và biến động tồn → quan hệ association.
- Lô hàng liên kết với chi tiết nhập; đơn trực tuyến liên kết với giao dịch bán → quan hệ association.
- Khoản thanh toán liên kết với giao dịch bán; khoản hoàn tiền liên kết với chi tiết bán gốc → quan hệ association.
- `SaleRefundPayment1` liên kết một khoản hoàn với một khoản thanh toán, đồng thời lưu số tiền phân bổ → hai quan hệ association.
- Biến động tồn liên kết với chứng từ nguồn phù hợp; `InventoryLotMovement1` liên kết một biến động với một lô, đồng thời lưu số lượng tăng hoặc giảm → quan hệ association.

Kết quả thu được sơ đồ lớp thực thể pha phân tích gồm 17 lớp, 25 quan hệ association/composition và 1 quan hệ generalization. Trong 25 liên kết nghiệp vụ có 3 composition và 22 association.

`ItemStatistics1` là lớp thống kê khái niệm được mô hình hóa theo cách trình bày của bài giảng, không phải bảng database mới hoặc một lớp Java đã cài đặt. Java hiện sử dụng `ItemRevenue1` và `RelatedTransaction1` làm record kết quả truy vấn; hai record được đặt trong phụ lục đối chiếu, không tính vào 17 lớp phân tích chính. Database vẫn có 16 bảng.

Nguồn đối chiếu: bài giảng mục 3.2.2, trang 72–76; yêu cầu hệ thống siêu thị; `supermarket/database/schema.sql`; các record và DAO hiện tại. Phân tích dựa trên schema trong dự án, chưa đối chiếu catalog PostgreSQL đang chạy.
