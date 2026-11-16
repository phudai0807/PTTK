package vn.pttk.supermarket.model;

import java.math.BigDecimal;
import java.util.List;

/** Revenue query result used by the existing DAO and JSP contract. */
public class ItemRevenue1 extends ItemStatistics1 {
    public ItemRevenue1() {
    }

    public ItemRevenue1(long itemId, String code, String name, String unit,
            List<String> supplierLabels, long quantity, long returnedQuantity,
            long transactionCount, BigDecimal grossAmount,
            BigDecimal discountAmount, BigDecimal refundAmount) {
        super(itemId, code, name, unit, supplierLabels, quantity, returnedQuantity,
                transactionCount, grossAmount, discountAmount, refundAmount);
    }
}
