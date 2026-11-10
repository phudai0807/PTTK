# Chi tiết những thay đổi code cần cân nhắc để cài đặt mô hình phân tích

## Trạng thái và phạm vi

Đây là danh sách đề xuất, **chưa áp dụng vào code**. Không cần sửa database để dùng sơ đồ pha phân tích. Cũng không cần đổi record thành class chỉ vì biểu đồ vẽ ô lớp UML: record là một cách cài đặt dữ liệu. Chỉ khi cần cài đặt quan hệ kế thừa và các phương thức đúng nơi như thiết kế phân tích thì mới cần những điều chỉnh dưới đây.

## 1. Nếu giữ kế thừa ItemRevenue1 → Item1 như hình mẫu

Đây là phần phải thay đổi nếu muốn Java cài đặt đúng quan hệ kế thừa trên sơ đồ: record không thể làm lớp cha có lớp con nghiệp vụ và record con cũng không thể extends Item1.

### Item1.java

- Chuyển `public record Item1(...)` thành lớp thường, cho phép kế thừa.
- Giữ các dữ liệu hiện có: id, code, name, unit, description. ID vẫn có trong cài đặt dù lược trên hình phân tích.
- Nếu dùng lớp này làm thực thể đầy đủ theo sơ đồ, thêm currentPrice, stockQuantity, active, trackLots từ items1; không thêm cột DB.
- Giữ các phương thức đọc dạng id(), code(), name(), unit(), description() để JSP hiện tại tiếp tục dùng. Bổ sung phương thức đọc các trường mới nếu thêm.

### ItemRevenue1.java

- Chuyển record thành lớp thường `extends Item1`.
- code/name/unit lấy từ lớp cha, không khai báo lặp. Dữ liệu riêng: supplierLabels, quantity, returnedQuantity, transactionCount, grossAmount, discountAmount, refundAmount.
- Giữ revenue() = grossAmount − discountAmount − refundAmount.
- Giữ các phương thức đọc cùng tên đang được JSP gọi. Đặc biệt, giữ itemId() như hàm trả id() của lớp cha để liên kết chi tiết vẫn hoạt động.
- Thiết kế constructor truyền dữ liệu hàng hóa vào super(...), rồi gán các số liệu thống kê.
- Nếu kiểm thử/nghiệp vụ đang dùng tính so sánh giá trị do record tự sinh, bảo toàn equals/hashCode/toString phù hợp khi đổi sang lớp thường.

### ItemRevenueDAO1.java

- findItem(): nếu lớp cha chứa đầy đủ dữ liệu bảng, bổ sung current_price, stock_quantity, active, track_lots vào SELECT và truyền vào constructor Item1; vẫn trả Optional<Item1>.
- summarize(): bổ sung các trường lớp cha cần, như description và các trường hàng hóa mới, vào SELECT; điều chỉnh lời gọi constructor ItemRevenue1 theo super(...). Vẫn trả List<ItemRevenue1>.
- Giữ cách tính kỳ [đầu ngày bắt đầu, đầu ngày sau ngày kết thúc), nguồn item_revenue_events1, điều kiện hoàn thành công và cách lấy nhà cung cấp từ phiếu nhập đã xác nhận. Không đổi các quy tắc doanh thu chỉ để sửa cấu trúc lớp.

## 2. Nếu muốn phương thức nằm đúng lớp như phân công của mục 3.2.3

Các phương thức phân tích hiện được cài đặt bằng khối JSP hoặc DAO. Có thể thêm các phương thức điều phối nghiệp vụ vào lớp đã phân công và ủy quyền xuống DAO; không sao chép SQL vào hai nơi.

| File/lớp cần bổ sung | Phương thức đề xuất | Việc thực hiện |
| --- | --- | --- |
| Customer1.java | validateRegistration(...) | Tách phần kiểm tra/chuẩn hóa dữ liệu của doDangKyThanhVien.jsp thành phương thức có đầu vào các trường đăng ký và đầu ra lỗi theo trường. Có thể dùng static để kiểm tra trước khi tạo đối tượng. |
| Customer1.java | register() | Phương thức điều phối lưu đối tượng khách hàng qua CustomerDAO1.register(this), trả kết quả đăng ký và cho phép xử lý SQLException ở nơi gọi. Không chuyển SQL ra khỏi DAO. |
| ItemRevenue1.java | getItemStatistics(from, to) | Phương thức tra cứu thống kê, có thể static, ủy quyền ItemRevenueDAO1.summarize(from, to). |
| Item1.java | getItemDetails(itemId) | Phương thức tra cứu, có thể static, ủy quyền ItemRevenueDAO1.findItem(itemId). |
| RelatedTransaction1.java | getRelatedTransactions(itemId, from, to) | Phương thức tra cứu, có thể static, ủy quyền ItemRevenueDAO1.findTransactions(...). Không cần đổi record này thành class chỉ để thêm static method. |

Tên tham số/kiểu dữ liệu cụ thể được chốt ở pha thiết kế. Trên hình pha phân tích chỉ ghi tên phương thức như giáo trình; input/output và nơi xử lý hiện tại đã được nêu trong tài liệu 01.

### Những JSP sẽ đổi lời gọi nếu thực hiện mục 2

- doDangKyThanhVien.jsp: gọi phần kiểm tra đã tách; khi hợp lệ tạo Customer1 và gọi customer.register() thay vì gọi DAO trực tiếp. Giữ kiểm tra phương thức POST/token, chuẩn hóa điện thoại/email, băm mật khẩu trước khi lưu, thông báo trùng điện thoại/email, trạng thái lỗi và redirect hiện có.
- gdThongKeHangHoa.jsp: gọi ItemRevenue1.getItemStatistics(from, to) nếu đã thêm phương thức; phần hiển thị vẫn dùng các accessor hiện có.
- gdChiTietHangHoa.jsp: gọi Item1.getItemDetails(itemId), sau đó RelatedTransaction1.getRelatedTransactions(itemId, from, to); giữ xử lý không tìm thấy, lỗi ngày, lỗi database và liên kết quay lại.

## 3. Customer1 và hai trường do database xử lý

Customer1 hiện là DTO nhập với 5 trường. is_member được SQL gán true và created_at được database cấp. Điều này đang hợp lệ, không phải lỗi dữ liệu. Bảng đối chiếu ghi rõ hai trường trạng thái phân tích nằm ở DB, chưa nằm trong DTO nhập.

Nếu về sau quyết định dùng Customer1 như đối tượng thực thể đầy đủ thay cho DTO nhập, mới thêm isMember/createdAt và thiết kế cách lấy created_at sau INSERT (ví dụ RETURNING). Cần giữ constructor/accessor mà JSP/DAO đang gọi hoặc cập nhật đồng bộ; không tự cấp thời điểm ở Java khác với thời điểm do DB lưu.

## 4. Phần xác thực hỗ trợ và các thực thể chưa có file Java

Employee1.authenticate()/hasReportAccess() là phân công phân tích. Code hiện xử lý trong ManagerDAO1 và report-get.jspf. Chỉ cần thêm Employee1 và các phương thức ủy quyền nếu triển khai lớp thực thể này; có thể giữ ManagerDAO1 làm nơi truy cập dữ liệu. Đăng nhập hiện chuyển trực tiếp đến /bao-cao và kiểm tra quyền MANAGEMENT; không thay quy tắc này.

Các lớp Supplier1, GoodsReceipt1, GoodsReceiptDetail1, SaleTransaction1, SaleTransactionDetail1, SaleRefund1 và các thực thể khác được phân tích từ schema, chưa có file Java tương ứng. Không cần tạo hàng loạt lớp rỗng để hai module đang chạy hoạt động; chỉ triển khai khi chức năng/thiết kế đối tượng cần đến. Nếu mục tiêu sau này là mỗi thực thể có một Java class, phải triển khai thêm theo bảng ánh xạ, không ghi rằng code hiện đã có chúng.

## 5. Phần không cần thay đổi

- Không thêm bảng cho GD, ItemRevenue1 hoặc RelatedTransaction1.
- Không đổi các khóa ngoại, bội số nghiệp vụ và trigger để chiều theo cách vẽ.
- Không ép RelatedTransaction1 kế thừa SaleTransaction1 vì nó gom cả sự kiện bán và hoàn.
- Không bắt buộc mỗi bảng phải có một Java class trong kiến trúc JDBC hiện tại.

## 6. Kiểm tra sau khi triển khai các thay đổi được chọn

- Build Java/JSP; kiểm tra constructor/accessor sau khi đổi record.
- Đăng ký: hợp lệ, thiếu/sai dữ liệu, trùng điện thoại/email; kiểm tra không lưu mật khẩu thô và token/lỗi vẫn hoạt động.
- Thống kê: kỳ có/không dữ liệu, ngày sai, ngày kết thúc được tính trọn ngày; số liệu bán/giảm giá/hoàn trước và sau refactor phải bằng nhau.
- Chi tiết: giữ đúng itemId và kỳ từ bảng thống kê, hàng không tồn tại, sự kiện hoàn có giao dịch gốc ngoài kỳ, tổng doanh thu mặt hàng khớp báo cáo.
- Xác thực: quản lý hợp lệ, tài khoản không có quyền, phiên hết hạn; các trang báo cáo vẫn kiểm tra quyền.
