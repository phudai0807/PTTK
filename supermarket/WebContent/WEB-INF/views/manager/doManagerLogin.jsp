<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ page import="java.sql.SQLException,java.util.UUID,vn.pttk.supermarket.dao.ManagerDAO1" %>
<%@ page import="jakarta.servlet.http.HttpSession" %>
<%
    response.setHeader("Cache-Control", "no-store");
    if (!"POST".equals(request.getMethod())) {
        response.setHeader("Allow", "POST");
        response.sendError(405);
        return;
    }
    request.setCharacterEncoding("UTF-8");
    HttpSession loginSession = request.getSession(false);
    Object token = loginSession == null ? null : loginSession.getAttribute("managerLoginToken");
    if (token == null || !token.equals(request.getParameter("token"))) {
        response.sendError(403, "Hãy mở lại trang đăng nhập rồi thử lại.");
        return;
    }

    String identifier = request.getParameter("identifier");
    if (identifier == null) {
        identifier = request.getParameter("employeeCode");
    }
    identifier = identifier == null ? "" : identifier.strip();
    String password = request.getParameter("password");
    int status = 401;
    String error = "Thông tin đăng nhập không hợp lệ hoặc tài khoản không có quyền quản lý.";
    if (!identifier.isEmpty() && identifier.length() <= 30 && password != null
            && !password.isEmpty() && password.length() <= 128) {
        try {
            Long managerId = new ManagerDAO1().authenticate(identifier, password);
            if (managerId != null) {
                request.changeSessionId();
                loginSession.setAttribute("managerId", managerId);
                loginSession.setAttribute("managerLogoutToken", UUID.randomUUID().toString());
                loginSession.removeAttribute("managerLoginToken");
                response.sendRedirect(request.getContextPath() + "/bao-cao");
                return;
            }
        } catch (SQLException exception) {
            application.log("Cannot authenticate manager.", exception);
            status = 503;
            error = "Chưa thể kiểm tra tài khoản. Vui lòng thử lại sau.";
        }
    }
    request.setAttribute("identifier", identifier);
    request.setAttribute("loginError", error);
    response.setStatus(status);
    request.getRequestDispatcher("/WEB-INF/views/manager/gdManagerLogin.jsp").forward(request, response);
%>
