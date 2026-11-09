package vn.pttk.supermarket.dao;

import vn.pttk.supermarket.model.Item1;
import vn.pttk.supermarket.model.ItemRevenue1;
import vn.pttk.supermarket.model.RelatedTransaction1;
import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public final class ItemRevenueDAO1 {
    public List<ItemRevenue1> summarize(LocalDate from, LocalDate to) throws SQLException {
        String sql = """
                WITH item_totals AS (
                    SELECT item_id, COALESCE(SUM(quantity) FILTER (WHERE NOT is_refund), 0) AS quantity,
                           COALESCE(SUM(quantity) FILTER (WHERE is_refund), 0) AS returned_quantity,
                           COUNT(DISTINCT transaction_id) FILTER (WHERE NOT is_refund) AS transaction_count,
                           SUM(gross_amount) AS gross_amount, SUM(discount_amount) AS discount_amount,
                           SUM(refund_amount) AS refund_amount
                    FROM item_revenue_events1
                    WHERE occurred_at >= ? AND occurred_at < ?
                    GROUP BY item_id
                )
                SELECT i.id, i.item_code, i.name, i.unit, totals.quantity, totals.returned_quantity,
                       totals.transaction_count, totals.gross_amount, totals.discount_amount, totals.refund_amount,
                       ARRAY(
                           SELECT s.supplier_code || ' · ' || s.name
                           FROM suppliers1 s
                           WHERE EXISTS (
                               SELECT 1
                               FROM goods_receipts1 r
                               JOIN goods_receipt_details1 d ON d.receipt_id = r.id
                               WHERE r.supplier_id = s.id AND d.item_id = i.id AND r.posted_at < ?
                           )
                           ORDER BY s.supplier_code
                       ) AS suppliers
                FROM item_totals totals
                JOIN items1 i ON i.id = totals.item_id
                ORDER BY totals.gross_amount - totals.discount_amount - totals.refund_amount DESC, i.item_code
                """;
        var rows = new ArrayList<ItemRevenue1>();
        try (var connection = Database1.open(); var statement = connection.prepareStatement(sql)) {
            bindDates(statement, from, to);
            statement.setObject(3, to.plusDays(1).atStartOfDay());
            try (var results = statement.executeQuery()) {
                while (results.next()) {
                    var suppliers = results.getArray("suppliers");
                    try {
                        rows.add(new ItemRevenue1(
                                results.getLong("id"), results.getString("item_code"), results.getString("name"),
                                results.getString("unit"), List.of((String[]) suppliers.getArray()),
                                results.getLong("quantity"), results.getLong("returned_quantity"),
                                results.getLong("transaction_count"), results.getBigDecimal("gross_amount"),
                                results.getBigDecimal("discount_amount"), results.getBigDecimal("refund_amount")));
                    } finally {
                        suppliers.free();
                    }
                }
            }
        }
        return rows;
    }

    public Optional<Item1> findItem(long itemId) throws SQLException {
        String sql = "SELECT id, item_code, name, unit, description FROM items1 WHERE id = ?";
        try (var connection = Database1.open(); var statement = connection.prepareStatement(sql)) {
            statement.setLong(1, itemId);
            try (var results = statement.executeQuery()) {
                if (results.next()) {
                    return Optional.of(new Item1(
                            results.getLong("id"), results.getString("item_code"), results.getString("name"),
                            results.getString("unit"), results.getString("description")));
                }
                return Optional.empty();
            }
        }
    }

    public List<RelatedTransaction1> findTransactions(long itemId, LocalDate from, LocalDate to)
            throws SQLException {
        String sql = """
                WITH selected_events AS (
                    SELECT transaction_id, transaction_code, event_code, occurred_at, channel, is_refund,
                           SUM(quantity) AS item_quantity,
                           ARRAY_AGG(DISTINCT unit_price ORDER BY unit_price) AS unit_prices,
                           SUM(gross_amount) AS gross_amount, SUM(discount_amount) AS discount_amount,
                           SUM(refund_amount) AS refund_amount
                    FROM item_revenue_events1
                    WHERE occurred_at >= ? AND occurred_at < ? AND item_id = ?
                    GROUP BY transaction_id, transaction_code, event_code, occurred_at, channel, is_refund
                )
                SELECT s.*, CASE WHEN s.is_refund THEN -s.refund_amount ELSE (
                    SELECT SUM(d.line_total - d.discount_amount)
                    FROM sale_transaction_details1 d WHERE d.transaction_id = s.transaction_id
                ) END AS transaction_total
                FROM selected_events s
                ORDER BY s.occurred_at DESC, s.event_code, s.is_refund
                """;
        var rows = new ArrayList<RelatedTransaction1>();
        try (var connection = Database1.open(); var statement = connection.prepareStatement(sql)) {
            bindDates(statement, from, to);
            statement.setLong(3, itemId);
            try (var results = statement.executeQuery()) {
                while (results.next()) {
                    var prices = results.getArray("unit_prices");
                    try {
                        rows.add(new RelatedTransaction1(
                                results.getString("event_code"), results.getString("transaction_code"),
                                results.getObject("occurred_at", LocalDateTime.class), results.getString("channel"),
                                results.getBoolean("is_refund"), results.getLong("item_quantity"),
                                List.of((BigDecimal[]) prices.getArray()), results.getBigDecimal("gross_amount"),
                                results.getBigDecimal("discount_amount"), results.getBigDecimal("refund_amount"),
                                results.getBigDecimal("transaction_total")));
                    } finally {
                        prices.free();
                    }
                }
            }
        }
        return rows;
    }

    private static void bindDates(PreparedStatement statement, LocalDate from, LocalDate to) throws SQLException {
        statement.setObject(1, from.atStartOfDay());
        statement.setObject(2, to.plusDays(1).atStartOfDay());
    }
}
