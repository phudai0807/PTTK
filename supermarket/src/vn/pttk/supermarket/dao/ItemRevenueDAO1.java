package vn.pttk.supermarket.dao;

import vn.pttk.supermarket.model.Item1;
import vn.pttk.supermarket.model.ItemRevenue1;
import vn.pttk.supermarket.model.RelatedTransaction1;
import java.math.BigDecimal;
import java.sql.Array;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;

public class ItemRevenueDAO1 extends DAO1 {
    public ItemRevenueDAO1() throws SQLException {
        super();
    }

    public ArrayList<ItemRevenue1> summarize(LocalDate from, LocalDate to) throws SQLException {
        String sql = "{? = call get_item_revenue1(?, ?)}";
        synchronized (DAO1.class) {
            ensureConnection();
            ArrayList<ItemRevenue1> rows = new ArrayList<ItemRevenue1>();
            try (CallableStatement statement = con.prepareCall(sql)) {
                statement.registerOutParameter(1, Types.OTHER);
                statement.setObject(2, from.atStartOfDay());
                statement.setObject(3, to.plusDays(1).atStartOfDay());
                statement.execute();
                try (ResultSet results = (ResultSet) statement.getObject(1)) {
                    while (results.next()) {
                        ItemRevenue1 item = new ItemRevenue1();
                        item.setItemId(results.getLong("id"));
                        item.setCode(results.getString("item_code"));
                        item.setName(results.getString("name"));
                        item.setUnit(results.getString("unit"));
                        Array suppliers = results.getArray("suppliers");
                        try {
                            ArrayList<String> supplierLabels = new ArrayList<String>();
                            for (String supplier : (String[]) suppliers.getArray()) {
                                supplierLabels.add(supplier);
                            }
                            item.setSupplierLabels(supplierLabels);
                        } finally {
                            suppliers.free();
                        }
                        item.setQuantity(results.getLong("quantity"));
                        item.setReturnedQuantity(results.getLong("returned_quantity"));
                        item.setTransactionCount(results.getLong("transaction_count"));
                        item.setGrossAmount(results.getBigDecimal("gross_amount"));
                        item.setDiscountAmount(results.getBigDecimal("discount_amount"));
                        item.setRefundAmount(results.getBigDecimal("refund_amount"));
                        rows.add(item);
                    }
                }
                con.commit();
                return rows;
            } catch (SQLException exception) {
                rollback(exception);
                throw exception;
            }
        }
    }

    public Item1 findItem(long itemId) throws SQLException {
        String sql = "{? = call find_item1(?)}";
        synchronized (DAO1.class) {
            ensureConnection();
            try (CallableStatement statement = con.prepareCall(sql)) {
                statement.registerOutParameter(1, Types.OTHER);
                statement.setLong(2, itemId);
                statement.execute();
                Item1 item = null;
                try (ResultSet results = (ResultSet) statement.getObject(1)) {
                    if (results.next()) {
                        item = new Item1();
                        item.setId(results.getLong("id"));
                        item.setCode(results.getString("item_code"));
                        item.setName(results.getString("name"));
                        item.setUnit(results.getString("unit"));
                        item.setDescription(results.getString("description"));
                    }
                }
                con.commit();
                return item;
            } catch (SQLException exception) {
                rollback(exception);
                throw exception;
            }
        }
    }

    public ArrayList<RelatedTransaction1> findTransactions(long itemId, LocalDate from, LocalDate to)
            throws SQLException {
        String sql = "{? = call get_related_transactions1(?, ?, ?)}";
        synchronized (DAO1.class) {
            ensureConnection();
            ArrayList<RelatedTransaction1> rows = new ArrayList<RelatedTransaction1>();
            try (CallableStatement statement = con.prepareCall(sql)) {
                statement.registerOutParameter(1, Types.OTHER);
                statement.setLong(2, itemId);
                statement.setObject(3, from.atStartOfDay());
                statement.setObject(4, to.plusDays(1).atStartOfDay());
                statement.execute();
                try (ResultSet results = (ResultSet) statement.getObject(1)) {
                    while (results.next()) {
                        RelatedTransaction1 transaction = new RelatedTransaction1();
                        transaction.setCode(results.getString("event_code"));
                        transaction.setOriginalSaleCode(results.getString("transaction_code"));
                        transaction.setOccurredAt(results.getObject("occurred_at", LocalDateTime.class));
                        transaction.setChannel(results.getString("channel"));
                        transaction.setRefund(results.getBoolean("is_refund"));
                        transaction.setQuantity(results.getLong("item_quantity"));
                        Array prices = results.getArray("unit_prices");
                        try {
                            ArrayList<BigDecimal> unitPrices = new ArrayList<BigDecimal>();
                            for (BigDecimal price : (BigDecimal[]) prices.getArray()) {
                                unitPrices.add(price);
                            }
                            transaction.setUnitPrices(unitPrices);
                        } finally {
                            prices.free();
                        }
                        transaction.setGrossAmount(results.getBigDecimal("gross_amount"));
                        transaction.setDiscountAmount(results.getBigDecimal("discount_amount"));
                        transaction.setRefundAmount(results.getBigDecimal("refund_amount"));
                        transaction.setTransactionTotal(results.getBigDecimal("transaction_total"));
                        rows.add(transaction);
                    }
                }
                con.commit();
                return rows;
            } catch (SQLException exception) {
                rollback(exception);
                throw exception;
            }
        }
    }
}
