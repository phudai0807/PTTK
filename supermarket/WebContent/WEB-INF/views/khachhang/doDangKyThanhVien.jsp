<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ page import="java.sql.SQLException,java.util.LinkedHashMap,java.util.Locale,java.util.regex.Pattern" %>
<%@ page import="vn.pttk.supermarket.dao.CustomerDAO1,vn.pttk.supermarket.model.Customer1,vn.pttk.supermarket.web.PasswordHash1" %>
<%@ page import="vn.pttk.supermarket.dao.CustomerDAO1.RegistrationResult1" %>
<%!
    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private static final Pattern PHONE = Pattern.compile("(?:0|\\+?84)[35789][0-9]{8}");

    private static String field(String value) {
        return value == null ? "" : value.strip();
    }
%>
<%
    if (!"POST".equals(request.getMethod())) {
        response.setHeader("Allow", "POST");
        response.sendError(405);
        return;
    }
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-store");
    var registrationSession = request.getSession(false);
    String token = registrationSession == null ? null
            : (String) registrationSession.getAttribute("registrationToken");
    if (token == null || !token.equals(request.getParameter("token"))) {
        response.sendError(403, "Hãy mở lại trang đăng ký rồi thử lại.");
        return;
    }

    String fullName = field(request.getParameter("fullName"));
    String phone = field(request.getParameter("phone"));
    String compactPhone = phone.replaceAll("[\\s().-]", "");
    String email = field(request.getParameter("email")).toLowerCase(Locale.ROOT);
    String address = field(request.getParameter("address"));
    String password = request.getParameter("password");
    var errors = new LinkedHashMap<String, String>();
    if (fullName.isBlank() || fullName.length() > 120) {
        errors.put("fullName", "Nhập họ tên từ 1 đến 120 ký tự.");
    }
    if (phone.length() > 32 || !PHONE.matcher(compactPhone).matches()) {
        errors.put("phone", "Nhập số di động Việt Nam bắt đầu bằng 0 hoặc +84.");
    }
    if (email.length() > 254 || !EMAIL.matcher(email).matches()) {
        errors.put("email", "Nhập địa chỉ email hợp lệ.");
    }
    if (address.isBlank() || address.length() > 300) {
        errors.put("address", "Nhập địa chỉ từ 1 đến 300 ký tự.");
    }
    if (password == null || password.isBlank() || password.length() < 8 || password.length() > 128) {
        errors.put("password", "Mật khẩu cần từ 8 đến 128 ký tự.");
    }

    int status = 400;
    if (errors.isEmpty()) {
        try {
            Customer1 customer = new Customer1(fullName, compactPhone, email, address, PasswordHash1.create(password));
            RegistrationResult1 result = new CustomerDAO1().register(customer);
            if (result == RegistrationResult1.CREATED) {
                registrationSession.setAttribute("registrationSuccess", true);
                response.sendRedirect(request.getContextPath() + "/dang-ky");
                return;
            }
            if (result == RegistrationResult1.DUPLICATE_PHONE) {
                errors.put("phone", "Số điện thoại này đã được đăng ký thành viên.");
            } else {
                errors.put("email", "Email này đã tồn tại trong hệ thống.");
            }
            status = 409;
        } catch (SQLException exception) {
            application.log("Cannot save member registration.", exception);
            errors.put("database", "Chưa thể lưu đăng ký. Vui lòng thử lại sau.");
            status = 503;
        }
    }

    request.setAttribute("fullName", fullName);
    request.setAttribute("phone", phone);
    request.setAttribute("email", email);
    request.setAttribute("address", address);
    request.setAttribute("token", token);
    request.setAttribute("errors", errors);
    response.setStatus(status);
    request.getRequestDispatcher("/WEB-INF/views/khachhang/gdDangKyThanhVien.jsp").forward(request, response);
%>
