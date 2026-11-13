# Trích và vẽ lớp hai module lần lượt theo mục 3.2.3

## Cách trình bày theo bài giảng

Bản này lấy code/database làm căn cứ dữ liệu và lấy giáo trình làm căn cứ phân tích. Quan hệ và phương thức đề xuất chưa đồng nghĩa đã tồn tại trong Java; xem bảng đối chiếu và danh sách điều chỉnh ở tài liệu 02/03.

Bản này dùng tiền tố **GD** cho lớp giao diện, giống GDChinhSV, GDDangki, GDChonTK trong hình mẫu. Phần tên phía sau bằng tiếng Anh và cuối tên có số 1, theo yêu cầu dự án. Ví dụ: **GDMemberRegistration1**, **GDItemStatistics1**. GD là quy ước đặt tên lớp biên; không tạo thêm bảng database.

Thực hiện đúng thứ tự: (1) mỗi giao diện đề xuất một lớp biên; (2) xác định các thành phần input/output/submit làm thuộc tính; (3) với chức năng bên dưới giao diện, xác định input, output, đề xuất phương thức và gán cho thực thể phù hợp, sau đó vẽ sơ đồ hoàn chỉnh cho từng module. Theo mẫu giáo trình, phương thức xử lý được phân công cho thực thể, không tự chèn thêm lớp Controller chỉ để đổi hình vẽ.

Mỗi bước được thể hiện bằng một trang VPP. Bước 1 chỉ hiện tên lớp GD; Bước 2 bổ sung thuộc tính giao diện; Bước 3 bổ sung thực thể, phương thức và quan hệ. Các trang dùng chung model lớp/quan hệ, không tạo bản sao lớp cho từng bước.

## A. Module khách hàng đăng ký thành viên

### Bước 1: Từ giao diện đề xuất lớp biên

- Ban đầu, giao diện chính của khách hàng → đề xuất **GDCustomerHome1**. Nguồn: `index.jsp` khi chưa đăng nhập quản lý.
- Sau khi chọn đăng ký thành viên, giao diện nhập thông tin đăng ký → đề xuất **GDMemberRegistration1**. Nguồn: `gdMemberRegistration.jsp`.
- Thành công và lỗi được hiển thị ngay trên trang đăng ký, vì vậy vẫn là **GDMemberRegistration1**, không tạo giao diện kết quả riêng.

Trang VPP tương ứng: **1.1 Registration - Step 1**.

### Bước 2: Xác định thành phần của từng giao diện

**GDCustomerHome1** cần các thành phần:

- Liên kết mở đăng ký thành viên: submit → `subRegisterMember`.
- Liên kết đăng nhập quản lý: submit → `subManagerLogin`; thuộc luồng hỗ trợ, không phải điều kiện bắt buộc cho khách đăng ký.

**GDMemberRegistration1** cần các thành phần:

- Ô nhập họ tên: input → `inFullName`.
- Ô nhập số điện thoại: input → `inPhone`.
- Ô nhập email: input → `inEmail`.
- Ô nhập mật khẩu: input → `inPassword`.
- Ô nhập địa chỉ: input → `inAddress`.
- Nút Thêm: submit → `subAdd`.
- Thông báo thành công hoặc lỗi chung: output → `outMessage`.
- Thông báo lỗi theo từng trường: output → `outFieldErrors`.

Nguồn trực tiếp là các input `fullName`, `phone`, `email`, `password`, textarea `address`, nút submit Thêm và vùng thông báo trong `gdMemberRegistration.jsp`. Không đề xuất nút xác nhận mật khẩu hoặc nút lưu khác vì giao diện hiện không có.

Trang VPP tương ứng: **1.2 Registration - Step 2**.

### Bước 3: Đề xuất phương thức xử lý bên dưới giao diện

**Để kiểm tra thông tin sau khi khách nhấn Thêm, cần xử lý:**

- Chức năng: kiểm tra dữ liệu bắt buộc, độ dài, định dạng điện thoại/email; chuẩn hóa dữ liệu nhập.
- Input: họ tên, điện thoại, email, địa chỉ và mật khẩu.
- Output: danh sách lỗi theo trường hoặc kết quả hợp lệ.
- Đề xuất phương thức `validateRegistration()`, gán cho **Customer1**.
- Cơ sở: đầu ra là kết quả kiểm tra, không xác định thực thể khác; đầu vào đều là thông tin khách hàng.
- Đối chiếu code: các điều kiện kiểm tra, chuẩn hóa số điện thoại/email trong `doMemberRegistration.jsp`.

**Sau khi thông tin hợp lệ, cần xử lý lưu thành viên:**

- Chức năng: tạo hồ sơ thành viên và phát hiện trùng thông tin liên hệ.
- Input: thông tin khách hàng hợp lệ; mật khẩu được chuyển sang `passwordHash` trước khi ghi database.
- Output: kết quả tạo mới, trùng điện thoại/email hoặc lỗi lưu.
- Đề xuất phương thức `register()`, gán cho **Customer1**.
- Cơ sở: đầu vào liên quan một thực thể khách hàng; đầu ra là kết quả thao tác lưu.
- Đối chiếu code: `doMemberRegistration.jsp` tạo `Customer1`, gọi `CustomerDAO1.register(customer)`; PostgreSQL đặt `is_member = true`.

**Vẽ sơ đồ module:** hàng trên là `GDCustomerHome1` liên kết `GDMemberRegistration1`; phía dưới giao diện đăng ký là `Customer1`, có các trách nhiệm kiểm tra và đăng ký. Các thuộc tính của Customer1 giữ như sơ đồ thực thể 3.2.2. Thông báo kết quả trả về cùng giao diện đăng ký; đường nối là liên kết lớp, không phải mũi tên tuần tự.

Trang VPP tương ứng: **1.3 Registration - Final analysis**.


## B. Module quản lý xem thống kê hàng hóa theo doanh thu

Điều kiện bắt đầu: nhân viên quản lý đã đăng nhập và có quyền xem báo cáo. Màn hình đăng nhập được mô tả ở phần hỗ trợ, không chèn thành một bước bắt buộc lặp lại trong mỗi lần xem thống kê.

### Bước 1: Từ giao diện đề xuất lớp biên

- Ban đầu, giao diện chính của quản lý → đề xuất **GDManagerHome1**. Nguồn: `index.jsp` ở trạng thái quản lý đã đăng nhập.
- Khi chọn mở báo cáo, giao diện chọn báo cáo thống kê → đề xuất **GDStatisticsMenu1**. Nguồn: `gdStatisticsMenu.jsp`.
- Khi chọn thống kê hàng hóa, giao diện nhập khoảng ngày và hiển thị kết quả → đề xuất **GDItemStatistics1**. Nguồn: `gdItemStatistics.jsp`; nhập ngày và bảng kết quả nằm trên cùng trang.
- Khi chọn một hàng hóa, giao diện thông tin hàng và danh sách giao dịch liên quan → đề xuất **GDItemDetails1**. Nguồn: `gdItemDetails.jsp`; hai phần này cũng nằm trên cùng trang.

Trang VPP tương ứng: **2.1 Item statistics - Step 1**.

### Bước 2: Xác định thành phần của từng giao diện

**GDManagerHome1** cần có:

- Liên kết Mở báo cáo: submit → `subViewReports`.

**GDStatisticsMenu1** cần có:

- Liên kết Chọn báo cáo thống kê hàng hóa: submit → `subSelectItemStatistics`.

Code hiện dùng một liên kết đến loại báo cáo đã có, không có hộp chọn động loại thống kê nên không đề xuất thuộc tính `inout` cho một danh sách loại báo cáo không tồn tại trên giao diện.

**GDItemStatistics1** cần có:

- Ô chọn ngày bắt đầu: input → `inStartDate`.
- Ô chọn ngày kết thúc: input → `inEndDate`.
- Nút Xem thống kê: submit → `subViewStatistics`.
- Bảng kết quả hàng hóa, trong đó tên hàng là liên kết chọn xem chi tiết: output và submit → `outsubItemStatistics`.
- Khoảng thời gian đang xem: output → `outPeriod`.
- Các tổng tiền hàng, giảm giá, hoàn tiền và doanh thu: output → `outTotals`.
- Thông báo ngày không hợp lệ, không có dữ liệu hoặc lỗi đọc: output → `outMessage`.
- Các liên kết xem kỳ dữ liệu mẫu có trong code: submit → `subSamplePeriod`.

**GDItemDetails1** cần có:

- Thông tin hàng hóa: output → `outItem`.
- Khoảng thời gian được giữ từ trang thống kê: output → `outPeriod`.
- Bảng giao dịch bán/hoàn liên quan: output → `outRelatedTransactions`.
- Doanh thu mặt hàng trong kỳ: output → `outItemRevenue`.
- Thông báo không có giao dịch: output → `outMessage`.
- Liên kết Quay lại kết quả thống kê: submit → `subBack`.

Bảng thống kê dùng `outsub` vì có liên kết trên tên hàng. Bảng giao dịch ở trang chi tiết chỉ hiển thị nên dùng `out`, không đề xuất thêm thao tác mở từng chứng từ. Khi mã hàng/ngày không hợp lệ, không tìm thấy hàng hoặc có lỗi đọc, code quay về giao diện thống kê để thông báo.

Trang VPP tương ứng: **2.2 Item statistics - Step 2**.

### Bước 3: Đề xuất phương thức xử lý bên dưới giao diện

**Để có bảng thống kê sau khi nhấn Xem thống kê, cần xử lý:**

- Chức năng: lấy số liệu hàng hóa theo doanh thu trong khoảng ngày đã chọn.
- Input: ngày bắt đầu, ngày kết thúc.
- Output: danh sách dữ liệu thống kê hàng hóa.
- Đề xuất phương thức `getItemStatistics()`, gán cho **ItemRevenue1**.
- Cơ sở: đầu ra liên quan lớp thống kê hàng hóa.
- Đối chiếu code: `gdItemStatistics.jsp` gọi `ItemRevenueDAO1.summarize(from, to)`, trả `ArrayList<ItemRevenue1>`. Trong mô hình phân tích đã thống nhất, khái niệm tương ứng là `ItemRevenue1` kế thừa `Item1`.

**Để có thông tin hàng hóa khi người dùng chọn tên hàng, cần xử lý:**

- Chức năng: tìm thông tin hàng hóa được chọn.
- Input: định danh hàng hóa.
- Output: `Item1` hoặc không tìm thấy.
- Đề xuất phương thức `getItemDetails()`, gán cho **Item1**.
- Cơ sở: đầu ra là thông tin hàng hóa.
- Đối chiếu code: `gdItemDetails.jsp` gọi `ItemRevenueDAO1.findItem(itemId)`; dữ liệu gốc từ `items1`.

**Để có bảng giao dịch liên quan của hàng hóa, cần xử lý:**

- Chức năng: lấy các dòng bán/hoàn liên quan đến hàng hóa trong cùng kỳ.
- Input: hàng hóa đã chọn, ngày bắt đầu, ngày kết thúc.
- Output: danh sách `RelatedTransaction1`.
- Đề xuất phương thức `getRelatedTransactions()`, gán cho **RelatedTransaction1**.
- Cơ sở: đầu ra là các dòng kết quả giao dịch liên quan.
- Đối chiếu code: `gdItemDetails.jsp` gọi `ItemRevenueDAO1.findTransactions(itemId, from, to)`. `RelatedTransaction1` là lớp kết quả truy vấn bán/hoàn, không có bảng riêng và không phải lớp con của `SaleTransaction1`.

**Vẽ sơ đồ module:** hàng trên gồm bốn lớp GD theo thứ tự mở giao diện. Dưới `GDItemStatistics1` là `ItemRevenue1`; dưới giao diện chi tiết là các lớp cung cấp dữ liệu `Item1`, `RelatedTransaction1`. Giữ quan hệ kế thừa `ItemRevenue1`–`Item1` và các quan hệ thực thể liên quan đến nhà cung cấp, phiếu nhập, hàng hóa, giao dịch bán, chi tiết bán và hoàn tiền như sơ đồ 3.2.2. Không đổi association thành composition chỉ vì có khóa ngoại. Các dependency của RelatedTransaction1 biểu diễn nguồn dữ liệu kết quả, không tạo khóa ngoại mới.

Trang VPP tương ứng: **2.3 Item statistics - Final analysis**.

## C. Phần hỗ trợ: Đăng nhập và kiểm tra quyền quản lý

- Giao diện đăng nhập → đề xuất **GDManagerLogin1**: `inIdentifier`, `inPassword`, `subLogin`, `outMessage`.
- Xác thực: input tên đăng nhập/mã nhân viên và mật khẩu; output quản lý được xác thực hoặc thất bại → đề xuất `Employee1.authenticate()`.
- Kiểm tra quyền: input nhân viên trong phiên; output có/không quyền xem báo cáo → đề xuất `Employee1.hasReportAccess()`.
- Đối chiếu `ManagerDAO1.authenticate()` và `hasReportAccess()`. Code trả `Long` hoặc `null` khi xác thực, lưu phiên rồi chuyển trực tiếp đến `/bao-cao`, tức **GDStatisticsMenu1**; không chuyển đến một trang thành công giả định.
- `report-get.jspf` kiểm tra lại quyền ở mọi trang báo cáo. Đăng ký khách hàng không cần đăng nhập quản lý.

Trang VPP: **3. Manager authentication - Supporting**.

## Quy ước và đồng bộ với code/database

- `GD` là tiền tố nhận biết giao diện. Thuộc tính có `-`, phương thức có `+`; `in/out/sub/outsub` theo thành phần thực tế. Không có kiểu dữ liệu hoặc ID kỹ thuật trong ngăn thuộc tính phân tích.
- Mục 3.2.3 cho phép đề xuất tên phương thức. Những tên ở trên là phân công trách nhiệm phân tích; JSP/DAO hiện thực các chức năng tương ứng, không khẳng định các lớp Java đã có các phương thức này.
- Trang 0.1 chứa 18 lớp dữ liệu/nghiệp vụ của mô hình tham chiếu: 16 thực thể theo schema và 2 lớp kết quả. Hai module lấy các lớp liên quan từ cùng model; dùng thêm 7 lớp GD.
- Có 25 model lớp: 16 thực thể theo schema, 2 lớp kết quả và 7 lớp GD; 7 phương thức được phân công cho các module. Các trang từng bước dùng lại model, không làm tăng số bảng database.
- Database vẫn 16 bảng. ItemRevenue1 là lớp thống kê trong mô hình phân tích; Java mang kết quả bằng class cùng tên độc lập. Quan hệ kế thừa thuộc pha phân tích. JSP gọi DAO, DAO dùng CallableStatement gọi PostgreSQL.
- Nguồn: bài giảng mục 3.2.3/Hình 3.6 và 3.8, code Java/JSP và schema của dự án. Đối chiếu schema trên đĩa, không khẳng định đã kiểm tra một PostgreSQL đang chạy.

## Đối chiếu tên và trách nhiệm với code hiện tại

| Trách nhiệm trong phân tích | Nơi thực hiện hiện tại | Trạng thái |
| --- | --- | --- |
| Customer1.validateRegistration() | Khối kiểm tra trong doMemberRegistration.jsp | Phương thức đề xuất, chưa có trong Customer1.java |
| Customer1.register() | CustomerDAO1.register(customer) | Phương thức đề xuất; DAO hiện đã thực hiện lưu |
| ItemRevenue1.getItemStatistics() | ItemRevenueDAO1.summarize(from, to) | Phương thức đề xuất; dữ liệu trả về đã dùng tên ItemRevenue1 |
| Item1.getItemDetails() | ItemRevenueDAO1.findItem(itemId) | Phương thức đề xuất; hiện nằm ở DAO |
| RelatedTransaction1.getRelatedTransactions() | ItemRevenueDAO1.findTransactions(itemId, from, to) | Phương thức đề xuất; giữ đúng lớp kết quả hiện có |
| Employee1.authenticate()/hasReportAccess() | ManagerDAO1 và report-get.jspf | Phân công ở phần hỗ trợ; chưa có Employee1.java |

Đây là phân công trách nhiệm theo mục 3.2.3, không phải sơ đồ đảo ngược từ Java. Nếu cần các phương thức xuất hiện đúng trong lớp Java, thực hiện các thay đổi cụ thể ở tài liệu 03; không chuyển nguyên SQL ra khỏi DAO. Các lớp GD là biểu diễn phân tích của giao diện JSP, không yêu cầu tạo thêm bảy lớp Java hoặc bảng database.
