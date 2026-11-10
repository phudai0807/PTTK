# Bản hoàn thiện sơ đồ lớp thực thể

Mở bản mới nhất `Sieu-thi-Lop-thuc-the-Theo-Mau-Bai-Giang.vpp` bằng Visual Paradigm 18.1.

Bản này dùng ô lớp trắng như Hình 3.5 trong bài giảng, bố cục theo cụm nghiệp vụ và luồng từ trên xuống dưới, đường nối vuông góc và ký hiệu UML `-` trước từng thuộc tính. Tên lớp tiếng Anh, có hậu tố `1`. Dấu `/` sau dấu `-` đánh dấu thuộc tính dẫn xuất.

- Trang 0: tóm tắt đủ 5 bước mục 3.2.2.
- Trang 1: 17 lớp phân tích, gồm 16 thực thể lưu trữ và ItemStatistics1; 25 liên kết nghiệp vụ và 1 quan hệ kế thừa.
- Trang 2-5: các góc nhìn theo nghiệp vụ, dùng chung lớp và quan hệ.
- Trang 6: ItemStatistics1 kế thừa Item1 theo cách biểu diễn lớp thống kê ở mẫu bài giảng; tam giác rỗng hướng về Item1.
- Trang 7: phụ lục hai record kết quả truy vấn thực tế trong Java, không phải hai bảng mới.

Bản thuyết minh đầy đủ: `Phan-tich-5-buoc-theo-mau-bai-giang.md`.
Bản viết theo bố cục giáo trình, dùng để đưa vào báo cáo: `Thuyet-minh-5-buoc-dung-mau-giao-trinh.md`.
Ảnh bản mới nằm trong thư mục `theo-mau-bai-giang-preview`, được xuất từ chính file VPP bằng bộ xuất chính thức của Visual Paradigm. Ảnh tổng thể có tên `Class-diagram-Theo-Mau-Bai-Giang.png`.

Đối chiếu code/database: `Doi-chieu-ban-theo-mau-bai-giang.md`. Database vẫn có 16 bảng. ItemStatistics1 là lớp thống kê khái niệm trong pha phân tích; Java hiện dùng record ItemRevenue1 phẳng để mang kết quả, không có quan hệ extends này trong code. Không sửa code hoặc schema trong lần hoàn thiện sơ đồ.

Các file Giao-Trinh, Hoan-Thien, checked, Ready, Final hoặc Theo-5-Buoc là các bản trước; bản bàn giao hiện tại là file Theo-Mau-Bai-Giang ghi trên đầu trang này.
