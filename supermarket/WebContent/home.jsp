<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<% request.setAttribute("pageTitle", "Trang chủ"); %>
<%@ include file="WEB-INF/views/common/header.jspf" %>
<% if (menuIsManager) { %>
    <jsp:include page="/WEB-INF/views/manager/gdManagerHome1.jsp" />
<% } else { %>
    <jsp:include page="/WEB-INF/views/customer/gdCustomerHome1.jsp" />
<% } %>
<%@ include file="WEB-INF/views/common/footer.jspf" %>
