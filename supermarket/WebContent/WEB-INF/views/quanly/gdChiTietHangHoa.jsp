<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.math.BigDecimal,java.sql.SQLException,java.util.ArrayList,java.time.format.DateTimeFormatter" %>
<%@ page import="vn.pttk.supermarket.dao.ItemRevenueDAO1,vn.pttk.supermarket.model.Item1,vn.pttk.supermarket.model.RelatedTransaction1" %>
<%@ include file="report-get.jspf" %>
<%@ include file="report-period.jspf" %>
<%!
    private static long reportItemId(String value) {
        try {
            long itemId = Long.parseLong(value);
            if (itemId > 0) {
                return itemId;
            }
        } catch (NumberFormatException ignored) {
            // Invalid or missing item ID.
        }
        throw new IllegalArgumentException("Mã hàng hóa không hợp lệ.");
    }
%>
<%
    String fromInput = request.getParameter("from");
    String toInput = request.getParameter("to");
    Item1 item = null;
    ArrayList<RelatedTransaction1> transactions = null;
    String error = null;
    int status = 200;
    try {
        LocalDate[] period = reportPeriod(fromInput, toInput);
        long itemId = reportItemId(request.getParameter("item"));
        ItemRevenueDAO1 dao = new ItemRevenueDAO1();
        item = dao.findItem(itemId);
        if (item == null) {
            status = 404;
            error = "Không tìm thấy hàng hóa.";
        } else {
            transactions = dao.findTransactions(itemId, period[0], period[1]);
        }
    } catch (IllegalArgumentException exception) {
        status = 400;
        error = exception.getMessage();
    } catch (SQLException exception) {
        application.log("Cannot read related transactions.", exception);
        status = 503;
        error = "Chưa thể đọc dữ liệu thống kê. Vui lòng thử lại sau.";
    }
    if (error != null) {
        response.setStatus(status);
        request.setAttribute("error", error);
        request.getRequestDispatcher("/WEB-INF/views/quanly/gdThongKeHangHoa.jsp").forward(request, response);
        return;
    }
    request.setAttribute("from", fromInput);
    request.setAttribute("to", toInput);
    request.setAttribute("pageTitle", "Chi tiết hàng hóa");
    DateTimeFormatter dateTime = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
%>
<%@ include file="../common/header.jspf" %>
<section class="page-title">
    <a href="<%= request.getContextPath() %>/thong-ke/hang-hoa?from=<%= Html1.escape(request.getAttribute("from")) %>&amp;to=<%= Html1.escape(request.getAttribute("to")) %>">← Quay lại kết quả thống kê</a>
    <h1><%= Html1.escape(item.getName()) %></h1>
    <p><strong><%= Html1.escape(item.getCode()) %></strong> · <%= Html1.escape(item.getUnit()) %></p>
    <p><%= Html1.escape(item.getDescription()) %></p>
</section>
<section class="panel report-detail">
    <h2>Danh sách giao dịch liên quan</h2>
    <p>Từ <strong><%= Html1.escape(request.getAttribute("from")) %></strong> đến hết ngày
        <strong><%= Html1.escape(request.getAttribute("to")) %></strong>.</p>
    <% if (transactions.isEmpty()) { %>
    <p class="notice">Hàng hóa này chưa có giao dịch trong khoảng thời gian đã chọn.</p>
    <% } else { %>
    <%
        BigDecimal itemRevenue = BigDecimal.ZERO;
        for (RelatedTransaction1 transaction : transactions) {
            itemRevenue = itemRevenue.add(transaction.getItemAmount());
        }
    %>
    <p>Doanh thu mặt hàng trong kỳ <strong><%= Html1.money(itemRevenue) %></strong></p>
    <div class="table-wrap">
        <table>
            <thead><tr>
                <th scope="col">Mã chứng từ</th><th scope="col">Thời gian</th><th scope="col">Loại</th>
                <th scope="col" class="numeric">Số lượng</th>
                <th scope="col" class="numeric">Đơn giá bán</th>
                <th scope="col" class="numeric">Tiền hàng</th><th scope="col" class="numeric">Giảm giá</th>
                <th scope="col" class="numeric">Hoàn tiền</th>
                <th scope="col" class="numeric">Doanh thu mặt hàng</th>
                <th scope="col" class="numeric">Tổng chứng từ</th>
            </tr></thead>
            <tbody>
            <% for (RelatedTransaction1 row : transactions) { %>
            <tr>
                <td><%= Html1.escape(row.getCode()) %>
                    <% if (row.isRefund()) { %>
                    <br><span class="hint">Giao dịch gốc <%= Html1.escape(row.getOriginalSaleCode()) %></span>
                    <% } %>
                </td>
                <td><%= row.getOccurredAt().format(dateTime) %></td>
                <td><%= row.isRefund() ? "Hoàn tiền" : ("ONLINE".equals(row.getChannel()) ? "Bán trực tuyến" : "Bán tại quầy") %></td>
                <td class="numeric"><%= Html1.number(row.getQuantity()) %> <%= Html1.escape(item.getUnit()) %></td>
                <td class="numeric">
                    <% if (row.isRefund()) { %>
                    —
                    <% } else { %>
                    <% for (int priceIndex = 0; priceIndex < row.getUnitPrices().size(); priceIndex++) { %>
                    <% if (priceIndex > 0) { %><br><% } %>
                    <%= Html1.money(row.getUnitPrices().get(priceIndex)) %>
                    <% } %>
                    <% } %>
                </td>
                <td class="numeric"><%= Html1.money(row.getGrossAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.getDiscountAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.getRefundAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.getItemAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.getTransactionTotal()) %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</section>
<%@ include file="../common/footer.jspf" %>
