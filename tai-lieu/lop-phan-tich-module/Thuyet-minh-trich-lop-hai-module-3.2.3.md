# Trích và vẽ biểu đồ lớp cho hai module theo mục 3.2.3

Nguồn: bài giảng mục 3.2.3, trang 76–83, đặc biệt Hình 3.6 và Hình 3.8; giao diện JSP và Java hiện tại; sơ đồ thực thể đã thống nhất ở mục 3.2.2.

Mẫu của giáo trình gán phương thức xử lý cho lớp thực thể theo đầu ra, hoặc theo đầu vào khi đầu ra không xác định một lớp thực thể. Vì vậy, hai sơ đồ chính không thêm các lớp Controller/DAO giả định vào giữa giao diện và thực thể. Đây là mô hình phân tích, không phải sơ đồ lớp cài đặt Java. Code thực tế xử lý bằng JSP và DAO, được ánh xạ ở Bước 3.

Tên lớp bằng tiếng Anh, kết thúc bằng số 1. Thuộc tính private có dấu `-`; phương thức public có dấu `+`. Thuộc tính chưa ghi kiểu dữ liệu; chữ ký trên hình chỉ ghi tên phương thức và `()` như mẫu, còn đầu vào/đầu ra trình bày trong bảng. Các lớp giao diện đặt ở hàng trên, lớp nghiệp vụ ở dưới; các đường nối vuông góc.

## Bước 1: Mỗi giao diện đề xuất thành một lớp biên

| Module | Giao diện thực tế | Lớp biên đề xuất |
| --- | --- | --- |
| Đăng ký thành viên | index.jsp ở trạng thái khách | CustomerHomeView1 |
| Đăng ký thành viên | gdMemberRegistration.jsp | MemberRegistrationView1 |
| Thống kê hàng hóa | index.jsp ở trạng thái quản lý | ManagerHomeView1 |
| Thống kê hàng hóa | gdStatisticsMenu.jsp | StatisticsMenuView1 |
| Thống kê hàng hóa | gdItemStatistics.jsp: nhập ngày và xem kết quả cùng trang | ItemStatisticsView1 |
| Thống kê hàng hóa | gdItemDetails.jsp: thông tin hàng và danh sách giao dịch cùng trang | ItemDetailsView1 |
| Hỗ trợ điều kiện đăng nhập | gdManagerLogin.jsp | ManagerLoginView1 |

Không tạo riêng giao diện báo thành công: code hiển thị kết quả đăng ký ngay trên trang đăng ký. Không tách giao diện nhập ngày khỏi giao diện kết quả, cũng không tách danh sách giao dịch thành trang mới vì code gộp các phần này trên cùng trang.

## Bước 2: Đề xuất thuộc tính cho các thành phần giao diện

Quy ước: `in` nhận dữ liệu; `out` hiển thị dữ liệu; `sub` gửi yêu cầu hoặc điều hướng; `outsub` vừa hiển thị vừa cho chọn/gửi yêu cầu, giống mẫu bảng có liên kết trong giáo trình.

### CustomerHomeView1

index.jsp ở trạng thái khách chưa đăng nhập; liên kết Đăng ký và Đăng nhập quản lý.

- `subRegisterMember`.
- `subManagerLogin`.

### MemberRegistrationView1

gdMemberRegistration.jsp; lỗi và thành công được hiển thị trên cùng giao diện, không tạo trang kết quả giả định.

- `inFullName`.
- `inPhone`.
- `inEmail`.
- `inPassword`.
- `inAddress`.
- `subAdd`.
- `outMessage`.
- `outFieldErrors`.

### ManagerHomeView1

index.jsp khi quản lý đã đăng nhập; liên kết Mở báo cáo.

- `subViewReports`.

### StatisticsMenuView1

gdStatisticsMenu.jsp hiện có một liên kết Chọn báo cáo, không có hộp chọn loại thống kê.

- `subSelectItemStatistics`.

### ItemStatisticsView1

gdItemStatistics.jsp; cùng một trang nhập ngày và hiển thị kết quả. Tên hàng trong bảng là liên kết mở chi tiết.

- `inStartDate`.
- `inEndDate`.
- `subViewStatistics`.
- `outsubItemStatistics`.
- `outPeriod`.
- `outTotals`.
- `outMessage`.
- `subSamplePeriod`.

### ItemDetailsView1

gdItemDetails.jsp; bảng giao dịch chỉ hiển thị, không có thao tác mở tiếp từng giao dịch.

- `outItem`.
- `outPeriod`.
- `outRelatedTransactions`.
- `outItemRevenue`.
- `outMessage`.
- `subBack`.

### ManagerLoginView1

gdManagerLogin.jsp; chức năng hỗ trợ điều kiện quản lý đã đăng nhập.

- `inIdentifier`.
- `inPassword`.
- `subLogin`.
- `outMessage`.

Bảng thống kê có liên kết trên tên hàng nên dùng `outsubItemStatistics`. Bảng giao dịch trên trang chi tiết chỉ hiển thị nên dùng `outRelatedTransactions`, không gán thao tác mở chứng từ mà code chưa có. Các tổng tiền, lỗi và trạng thái rỗng đều được thể hiện qua các thuộc tính output. Token ẩn, session, mã trạng thái HTTP, băm mật khẩu và kết nối database là chi tiết thực thi, không đề xuất thành lớp biên hoặc lớp thực thể mới.

## Bước 3: Đề xuất phương thức và gán cho lớp thực thể

| Chức năng | Input | Output | Phương thức và lớp được gán | Ánh xạ code hiện tại |
| --- | --- | --- | --- | --- |
| validateRegistration | Thông tin họ tên, điện thoại, email, địa chỉ và mật khẩu nhập | Danh sách lỗi theo trường hoặc hợp lệ | Customer1.validateRegistration() | doMemberRegistration.jsp kiểm tra và chuẩn hóa dữ liệu trước khi tạo record Customer1. |
| register | Thông tin khách hàng hợp lệ | Kết quả tạo thành viên hoặc trùng điện thoại/email; lỗi lưu được xử lý riêng | Customer1.register() | doMemberRegistration.jsp → CustomerDAO1.register(Customer1); is_member = true, created_at do database cấp. |
| getItemStatistics | Ngày bắt đầu, ngày kết thúc | Danh sách ItemStatistics1 | ItemStatistics1.getItemStatistics() | gdItemStatistics.jsp → ItemRevenueDAO1.summarize(from, to), thực tế trả List<ItemRevenue1>; ItemStatistics1 là khái niệm phân tích. |
| getItemDetails | Hàng hóa được chọn (định danh hàng hóa) | Thông tin Item1 hoặc không tìm thấy | Item1.getItemDetails() | gdItemDetails.jsp → ItemRevenueDAO1.findItem(itemId). |
| getRelatedTransactions | Hàng hóa được chọn, ngày bắt đầu, ngày kết thúc | Danh sách RelatedTransaction1 | RelatedTransaction1.getRelatedTransactions() | gdItemDetails.jsp → ItemRevenueDAO1.findTransactions(itemId, from, to). Đây là dữ liệu kết quả bán/hoàn, không phải bảng mới. |
| authenticate | Tên đăng nhập hoặc mã nhân viên, mật khẩu | Nhân viên quản lý được xác thực hoặc không hợp lệ | Employee1.authenticate() | doManagerLogin.jsp → ManagerDAO1.authenticate(identifier, password); code trả Optional<Long> mã định danh quản lý. |
| hasReportAccess | Nhân viên trong phiên đăng nhập | Có hoặc không có quyền xem báo cáo | Employee1.hasReportAccess() | report-get.jspf → ManagerDAO1.hasReportAccess(employeeId); áp dụng cho mọi trang báo cáo. |

### Cơ sở gán phương thức

- `validateRegistration()` và `register()`: đầu ra là lỗi/kết quả xử lý, không phải một thực thể khác; đầu vào chỉ liên quan thông tin khách hàng → gán Customer1.
- `getItemStatistics()`: đầu ra là danh sách thống kê hàng hóa → gán ItemStatistics1.
- `getItemDetails()`: đầu ra là thông tin hàng hóa → gán Item1.
- `getRelatedTransactions()`: đầu ra là các dòng kết quả giao dịch bán/hoàn → gán RelatedTransaction1. Lớp này không có bảng riêng.
- `authenticate()` và `hasReportAccess()`: chức năng hỗ trợ xác thực và quyền của nhân viên → gán Employee1.

Các phép kiểm tra kỳ báo cáo, định dạng dữ liệu và xử lý lỗi được mô tả trong Documentation của các lớp/giao diện; không đề xuất thêm thực thể chỉ để chứa chúng. Đăng ký lưu passwordHash và đánh dấu isMember; không ghi mật khẩu thô vào lớp thực thể.

## Vẽ biểu đồ lớp pha phân tích cho từng module

### Module 1: Khách hàng đăng ký thành viên

- CustomerHomeView1 liên kết MemberRegistrationView1 để mở trang đăng ký.
- MemberRegistrationView1 liên kết Customer1 để kiểm tra và lưu thông tin thành viên.
- Customer1 giữ các thuộc tính đã xác định ở mục 3.2.2, bổ sung hai phương thức phân tích validateRegistration() và register().
- Đầu vào không hợp lệ, trùng điện thoại/email, lỗi lưu hoặc thành công được trả về cùng giao diện đăng ký.

### Module 2: Nhân viên quản lý xem thống kê hàng hóa theo doanh thu

Điều kiện bắt đầu: nhân viên quản lý đã đăng nhập và có quyền xem báo cáo.

- ManagerHomeView1 → StatisticsMenuView1 → ItemStatisticsView1 → ItemDetailsView1 biểu diễn chuỗi các giao diện có liên kết điều hướng.
- ItemStatisticsView1 liên kết ItemStatistics1 để lấy kết quả theo ngày bắt đầu và ngày kết thúc.
- ItemDetailsView1 liên kết Item1 để lấy thông tin hàng; liên kết RelatedTransaction1 để lấy các giao dịch bán/hoàn trong cùng khoảng ngày.
- Giữ ItemStatistics1 kế thừa Item1 như sơ đồ thực thể phân tích đã thống nhất. Tam giác rỗng hướng về Item1, không gán thêm kế thừa cho RelatedTransaction1.
- Giữ nguyên các quan hệ Supplier1–GoodsReceipt1, GoodsReceipt1–GoodsReceiptDetail1, Item1–GoodsReceiptDetail1, SaleTransaction1–SaleTransactionDetail1, Item1–SaleTransactionDetail1 và SaleTransactionDetail1–SaleRefund1. Bội số và ba dạng quan hệ sử dụng trong module được lấy từ mô hình trước: association, composition và generalization.
- RelatedTransaction1 phụ thuộc dữ liệu Item1, SaleTransaction1, SaleTransactionDetail1, SaleRefund1; đây là phụ thuộc của kết quả truy vấn, không phải bốn khóa ngoại mới.
- Ngày không hợp lệ, không có dữ liệu, hàng hóa không tồn tại và lỗi đọc dữ liệu được thể hiện qua output thông báo. Trường hợp lỗi tra cứu chi tiết, code quay về giao diện thống kê để thông báo.

### Sơ đồ hỗ trợ: Xác thực quản lý

CustomerHomeView1 → ManagerLoginView1 → StatisticsMenuView1. Đăng nhập thành công chuyển trực tiếp đến /bao-cao đúng code. ManagerLoginView1 liên kết Employee1; authenticate() xác thực tài khoản MANAGEMENT, hasReportAccess() được kiểm tra lại tại các trang báo cáo. Đây là sơ đồ hỗ trợ điều kiện đầu vào, không thay thế module thống kê.

## Đồng bộ với code và sơ đồ thực thể

- 18 lớp trong file: 7 lớp biên và 11 lớp nghiệp vụ/dữ liệu kết quả được dùng bởi các module và phần xác thực. Không thêm bảng database.
- 7 phương thức là phương thức được phân công trong pha phân tích. Không khẳng định các record Java hiện có sẵn những phương thức này.
- ItemStatistics1 vẫn là lớp phân tích kế thừa Item1; code dùng record ItemRevenue1 để mang kết quả từ ItemRevenueDAO1.summarize().
- RelatedTransaction1 là dữ liệu kết quả bán/hoàn hiện có trong Java, không phải lớp con của SaleTransaction1 và không phải bảng độc lập.
- JSP/DAO chỉ được dùng để đối chiếu thực thi trong thuyết minh. Không đưa chúng vào hai sơ đồ phân tích chính như các lớp nghiệp vụ mới.
- Giữ các thuộc tính và quan hệ của thực thể từ sơ đồ 3.2.2; chỉ bổ sung phương thức và lớp biên. Không sửa code Java, JSP hoặc schema ứng dụng.
