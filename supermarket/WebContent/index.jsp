<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<% request.setAttribute("pageTitle", "Trang chủ"); %>
<%@ include file="WEB-INF/views/common/header.jspf" %>
<section class="hero">
    <p class="eyebrow">Hệ thống quản lý</p>
    <h1>Siêu thị trực tuyến</h1>
    <% if (menuIsManager) { %>
    <p>Xem doanh thu hàng hóa trong khoảng thời gian bạn chọn.</p>
    <% } else { %>
    <p>Đăng ký thành viên hoặc đăng nhập với tài khoản quản lý.</p>
    <% } %>
</section>
<div class="<%= menuIsManager ? "form-panel" : "cards" %>">
    <% if (!menuIsManager) { %>
    <section class="panel">
        <p class="eyebrow">Khách hàng</p>
        <h2>Đăng ký thành viên</h2>
        <p>Điền thông tin liên hệ để đăng ký thành viên của siêu thị.</p>
        <a class="button" href="<%= request.getContextPath() %>/dang-ky">Mở trang đăng ký</a>
    </section>
    <% } %>
    <section class="panel">
        <p class="eyebrow">Nhân viên quản lý</p>
        <% if (menuIsManager) { %>
        <h2>Báo cáo thống kê</h2>
        <p>Xem doanh thu từng hàng hóa và tra cứu các giao dịch liên quan.</p>
        <a class="button secondary" href="<%= request.getContextPath() %>/bao-cao">Mở báo cáo</a>
        <% } else { %>
        <h2>Đăng nhập quản lý</h2>
        <p>Đăng nhập bằng tài khoản nhân viên quản lý để xem báo cáo.</p>
        <a class="button secondary" href="<%= request.getContextPath() %>/quan-ly/dang-nhap">Đăng nhập</a>
        <% } %>
    </section>
</div>
<%@ include file="WEB-INF/views/common/footer.jspf" %>
