<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ page import="jakarta.servlet.http.HttpSession" %>
<%
    response.setHeader("Cache-Control", "no-store");
    if (!"POST".equals(request.getMethod())) {
        response.setHeader("Allow", "POST");
        response.sendError(405);
        return;
    }
    HttpSession logoutSession = request.getSession(false);
    Object token = logoutSession == null ? null : logoutSession.getAttribute("managerLogoutToken");
    if (token == null || !token.equals(request.getParameter("token"))) {
        response.sendError(403);
        return;
    }
    logoutSession.invalidate();
    response.sendRedirect(request.getContextPath() + "/quan-ly/dang-nhap");
%>
