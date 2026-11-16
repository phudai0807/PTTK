<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Map,java.util.UUID" %>
<%!
    private static boolean hasError(Map<?, ?> errors, String field) {
        return errors != null && errors.containsKey(field);
    }
%>
<%
    response.setHeader("Cache-Control", "no-store");
    Map<?, ?> errors = (Map<?, ?>) request.getAttribute("errors");
    if ("POST".equals(request.getMethod()) && errors == null) {
        request.getRequestDispatcher("/customer/doMemberRegistration1.jsp").forward(request, response);
        return;
    }
    if (errors == null) {
        synchronized (session) {
            if (session.getAttribute("registrationToken") == null) {
                session.setAttribute("registrationToken", UUID.randomUUID().toString());
            }
            request.setAttribute("token", session.getAttribute("registrationToken"));
            request.setAttribute("success", session.getAttribute("registrationSuccess"));
            session.removeAttribute("registrationSuccess");
        }
    }
    request.setAttribute("pageTitle", "Đăng ký thành viên");
%>
<%@ include file="../common/header.jspf" %>
<section class="page-title">
    <p class="eyebrow">Khách hàng</p>
    <h1>Đăng ký thành viên</h1>
    <p>Điền đầy đủ thông tin, sau đó nhấn “Thêm”.</p>
</section>
<section class="panel form-panel" aria-label="Thông tin đăng ký">
    <% if (Boolean.TRUE.equals(request.getAttribute("success"))) { %>
    <p class="notice success" role="status">Đăng ký thành viên thành công.</p>
    <% } %>
    <% if (errors != null && !errors.isEmpty()) { %>
    <div class="notice error" role="alert">
        <strong>Vui lòng kiểm tra thông tin đăng ký.</strong>
        <% if (errors.containsKey("database")) { %>
        <p><%= Html1.escape(errors.get("database")) %></p>
        <% } %>
    </div>
    <% } %>
    <form action="<%= request.getContextPath() %>/dang-ky/luu" method="post">
        <input type="hidden" name="token" value="<%= Html1.escape(request.getAttribute("token")) %>">
        <div class="fields">
            <label>Họ và tên
                <input name="fullName" autocomplete="name" required maxlength="120"
                       aria-invalid="<%= hasError(errors, "fullName") %>" aria-describedby="fullName-error"
                       value="<%= Html1.escape(request.getAttribute("fullName")) %>">
                <span id="fullName-error" class="field-error"><%= Html1.escape(errors == null ? null : errors.get("fullName")) %></span>
            </label>
            <label>Số điện thoại
                <input name="phone" type="tel" autocomplete="tel" required maxlength="32"
                       aria-invalid="<%= hasError(errors, "phone") %>" aria-describedby="phone-help phone-error"
                       value="<%= Html1.escape(request.getAttribute("phone")) %>">
                <span id="phone-help" class="hint">Số di động Việt Nam dùng để tra cứu thành viên.</span>
                <span id="phone-error" class="field-error"><%= Html1.escape(errors == null ? null : errors.get("phone")) %></span>
            </label>
            <label>Email
                <input name="email" type="email" autocomplete="email" required maxlength="254"
                       aria-invalid="<%= hasError(errors, "email") %>" aria-describedby="email-error"
                       value="<%= Html1.escape(request.getAttribute("email")) %>">
                <span id="email-error" class="field-error"><%= Html1.escape(errors == null ? null : errors.get("email")) %></span>
            </label>
            <label>Mật khẩu
                <input name="password" type="password" autocomplete="new-password" required
                       minlength="8" maxlength="128" aria-invalid="<%= hasError(errors, "password") %>"
                       aria-describedby="password-help password-error">
                <span id="password-help" class="hint">Từ 8 đến 128 ký tự.</span>
                <span id="password-error" class="field-error"><%= Html1.escape(errors == null ? null : errors.get("password")) %></span>
            </label>
            <label class="full">Địa chỉ
                <textarea name="address" autocomplete="street-address" required maxlength="300" rows="2"
                          aria-invalid="<%= hasError(errors, "address") %>" aria-describedby="address-error"><%= Html1.escape(request.getAttribute("address")) %></textarea>
                <span id="address-error" class="field-error"><%= Html1.escape(errors == null ? null : errors.get("address")) %></span>
            </label>
        </div>
        <div class="actions"><button type="submit">Thêm</button></div>
    </form>
</section>
<%@ include file="../common/footer.jspf" %>
