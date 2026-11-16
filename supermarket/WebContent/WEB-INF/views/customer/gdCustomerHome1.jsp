<%@ page pageEncoding="UTF-8" %>
<section class="hero">
    <p class="eyebrow">Hệ thống quản lý</p>
    <h1>Siêu thị trực tuyến</h1>
    <p>Đăng ký thành viên hoặc đăng nhập với tài khoản quản lý.</p>
</section>
<div class="cards">
    <section class="panel">
        <p class="eyebrow">Khách hàng</p>
        <h2>Đăng ký thành viên</h2>
        <p>Điền thông tin liên hệ để đăng ký thành viên của siêu thị.</p>
        <a class="button" href="<%= request.getContextPath() %>/dang-ky">Mở trang đăng ký</a>
    </section>
    <section class="panel">
        <p class="eyebrow">Nhân viên quản lý</p>
        <h2>Đăng nhập quản lý</h2>
        <p>Đăng nhập bằng tài khoản nhân viên quản lý để xem báo cáo.</p>
        <a class="button secondary" href="<%= request.getContextPath() %>/quan-ly/dang-nhap">Đăng nhập</a>
    </section>
</div>
