<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="report-get.jspf" %>
<% request.setAttribute("pageTitle", "Báo cáo thống kê"); %>
<%@ include file="../common/header.jspf" %>
<section class="page-title">
    <p class="eyebrow">Nhân viên quản lý</p>
    <h1>Báo cáo thống kê</h1>
</section>
<section class="panel form-panel">
    <h2>Thống kê hàng hóa theo doanh thu</h2>
    <p>Xem số lượng bán, doanh thu của từng mặt hàng và danh sách giao dịch liên quan.</p>
    <a class="button" href="<%= request.getContextPath() %>/thong-ke/hang-hoa">Chọn báo cáo</a>
</section>
<%@ include file="../common/footer.jspf" %>
