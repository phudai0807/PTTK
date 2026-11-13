<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.UUID" %>
<%
    response.setHeader("Cache-Control", "no-store");
    if (!"GET".equals(request.getMethod()) && !"HEAD".equals(request.getMethod())
            && request.getAttribute("loginError") == null) {
        response.setHeader("Allow", "GET, HEAD");
        response.sendError(405);
        return;
    }
    synchronized (session) {
        if (session.getAttribute("managerLoginToken") == null) {
            session.setAttribute("managerLoginToken", UUID.randomUUID().toString());
        }
    }
    request.setAttribute("pageTitle", "Đăng nhập quản lý");
%>
<%@ include file="../common/header.jspf" %>
<section class="page-title">
    <p class="eyebrow">Nhân viên quản lý</p>
    <h1>Đăng nhập để xem báo cáo</h1>
    <p>Nhập tên đăng nhập hoặc mã nhân viên, cùng mật khẩu của tài khoản quản lý.</p>
</section>
<section class="panel form-panel" aria-label="Đăng nhập quản lý">
    <% if (request.getAttribute("loginError") != null) { %>
    <p class="notice error" role="alert"><%= Html1.escape(request.getAttribute("loginError")) %></p>
    <% } %>
    <form action="<%= request.getContextPath() %>/quan-ly/dang-nhap/xu-ly" method="post">
        <input type="hidden" name="token" value="<%= Html1.escape(session.getAttribute("managerLoginToken")) %>">
        <div class="fields">
            <label>Tên đăng nhập hoặc mã nhân viên
                <input name="identifier" autocomplete="username" required maxlength="30"
                       value="<%= Html1.escape(request.getAttribute("identifier")) %>">
            </label>
            <label>Mật khẩu
                <input type="password" name="password" autocomplete="current-password" required maxlength="128">
            </label>
        </div>
        <div class="actions"><button type="submit">Đăng nhập</button></div>
    </form>
</section>
<%@ include file="../common/footer.jspf" %>
