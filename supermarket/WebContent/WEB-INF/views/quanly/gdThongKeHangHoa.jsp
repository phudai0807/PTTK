<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.math.BigDecimal,java.sql.SQLException,java.time.ZoneId,java.time.format.DateTimeFormatter,java.util.List" %>
<%@ page import="vn.pttk.supermarket.dao.ItemRevenueDAO1,vn.pttk.supermarket.model.ItemRevenue1" %>
<%@ include file="report-get.jspf" %>
<%@ include file="report-period.jspf" %>
<%
    request.setAttribute("pageTitle", "Thống kê hàng hóa theo doanh thu");
    List<ItemRevenue1> results = null;
    LocalDate[] period = null;
    String reportPath = request.getContextPath() + "/thong-ke/hang-hoa";
    String fromInput = request.getParameter("from");
    String toInput = request.getParameter("to");
    if (request.getAttribute("error") == null && fromInput == null && toInput == null) {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        request.setAttribute("from", today.minusDays(6));
        request.setAttribute("to", today);
    } else {
        request.setAttribute("from", fromInput);
        request.setAttribute("to", toInput);
        if (request.getAttribute("error") == null) {
            try {
                period = reportPeriod(fromInput, toInput);
                results = new ItemRevenueDAO1().summarize(period[0], period[1]);
            } catch (IllegalArgumentException exception) {
                response.setStatus(400);
                request.setAttribute("error", exception.getMessage());
            } catch (SQLException exception) {
                application.log("Cannot read item revenue.", exception);
                response.setStatus(503);
                request.setAttribute("error", "Chưa thể đọc dữ liệu thống kê. Vui lòng thử lại sau.");
            }
        }
    }
%>
<%@ include file="../common/header.jspf" %>
<section class="page-title">
    <p class="eyebrow">Báo cáo thống kê</p>
    <h1>Thống kê hàng hóa theo doanh thu</h1>
    <p>Chọn khoảng thời gian để xem tiền bán, giảm giá và hoàn tiền theo mặt hàng.</p>
</section>
<section class="panel">
    <form class="date-filter" action="<%= reportPath %>" method="get">
        <label>Ngày bắt đầu
            <input type="date" name="from" required value="<%= Html1.escape(request.getAttribute("from")) %>">
        </label>
        <label>Ngày kết thúc
            <input type="date" name="to" required value="<%= Html1.escape(request.getAttribute("to")) %>">
        </label>
        <button type="submit">Xem thống kê</button>
    </form>
    <p class="hint">
        <a href="<%= reportPath %>?from=2026-11-01&amp;to=2026-11-03">Xem mẫu bán hàng 01–03/11/2026</a>
        · <a href="<%= reportPath %>?from=2026-11-05&amp;to=2026-11-07">Xem mẫu giảm giá và hoàn tiền 05–07/11/2026</a>
    </p>
    <% if (request.getAttribute("error") != null) { %>
    <p class="notice error" role="alert"><%= Html1.escape(request.getAttribute("error")) %></p>
    <% } %>
</section>
<% if (results != null) { %>
<section class="panel results">
    <h2>Kết quả thống kê</h2>
    <%
        DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalDiscount = BigDecimal.ZERO;
        BigDecimal totalRefund = BigDecimal.ZERO;
        for (ItemRevenue1 row : results) {
            totalGross = totalGross.add(row.grossAmount());
            totalDiscount = totalDiscount.add(row.discountAmount());
            totalRefund = totalRefund.add(row.refundAmount());
        }
        BigDecimal totalRevenue = totalGross.subtract(totalDiscount).subtract(totalRefund);
    %>
    <div class="report-summary">
        <p class="hint">Từ <strong><%= period[0].format(dateFormat) %></strong> đến hết ngày
            <strong><%= period[1].format(dateFormat) %></strong> · <%= Html1.number(results.size()) %> mặt hàng</p>
        <p class="report-total"><span>Tổng doanh thu sau giảm giá và hoàn tiền</span>
            <strong><%= Html1.money(totalRevenue) %></strong></p>
    </div>
    <% if (results.isEmpty()) { %>
    <p class="notice">Không có giao dịch trong khoảng thời gian đã chọn.</p>
    <% } else { %>
    <p>Tiền hàng <strong><%= Html1.money(totalGross) %></strong> · Giảm giá
        <strong><%= Html1.money(totalDiscount) %></strong> · Hoàn tiền <strong><%= Html1.money(totalRefund) %></strong></p>
    <p class="hint">Tiền bán và giảm giá tính theo ngày bán. Khoản hoàn tính theo ngày hoàn, kể cả khi giao dịch gốc nằm ngoài kỳ.
        Nhà cung cấp được lấy từ phiếu nhập đã xác nhận đến hết ngày kết thúc.</p>
    <div class="table-wrap">
        <table>
            <thead><tr>
                <th scope="col">Mã hàng</th><th scope="col">Tên hàng hóa</th>
                <th scope="col">Nhà cung cấp</th>
                <th scope="col">Đơn vị tính</th>
                <th scope="col" class="numeric">SL bán</th><th scope="col" class="numeric">SL trả</th>
                <th scope="col" class="numeric">Lượt bán</th><th scope="col" class="numeric">Tiền hàng</th>
                <th scope="col" class="numeric">Giảm giá</th><th scope="col" class="numeric">Hoàn tiền</th>
                <th scope="col" class="numeric">Doanh thu còn lại</th>
            </tr></thead>
            <tbody>
            <% for (ItemRevenue1 row : results) { %>
            <tr>
                <td><%= Html1.escape(row.code()) %></td>
                <td><a href="<%= reportPath %>/chi-tiet?item=<%= row.itemId() %>&amp;from=<%= Html1.escape(request.getAttribute("from")) %>&amp;to=<%= Html1.escape(request.getAttribute("to")) %>"><%= Html1.escape(row.name()) %></a></td>
                <td>
                    <% if (row.supplierLabels().isEmpty()) { %>
                    <span class="hint">Chưa có phiếu nhập</span>
                    <% } else { %>
                    <ul class="supplier-list">
                        <% for (String supplier : row.supplierLabels()) { %>
                        <li><%= Html1.escape(supplier) %></li>
                        <% } %>
                    </ul>
                    <% } %>
                </td>
                <td><%= Html1.escape(row.unit()) %></td>
                <td class="numeric"><%= Html1.number(row.quantity()) %></td>
                <td class="numeric"><%= Html1.number(row.returnedQuantity()) %></td>
                <td class="numeric"><%= Html1.number(row.transactionCount()) %></td>
                <td class="numeric"><%= Html1.money(row.grossAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.discountAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.refundAmount()) %></td>
                <td class="numeric"><%= Html1.money(row.revenue()) %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</section>
<% } %>
<%@ include file="../common/footer.jspf" %>
