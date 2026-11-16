<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<% request.setAttribute("pageTitle", "Trang chủ"); %>
<%@ include file="common/header.jspf" %>
<% if (menuIsManager) { %>
    <jsp:include page="/manager/gdManagerHome1.jsp" />
<% } else { %>
    <jsp:include page="/customer/gdCustomerHome1.jsp" />
<% } %>
<%@ include file="common/footer.jspf" %>
