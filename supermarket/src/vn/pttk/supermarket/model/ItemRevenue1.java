package vn.pttk.supermarket.model;

import java.math.BigDecimal;
import java.util.List;

public record ItemRevenue1(
        long itemId, String code, String name, String unit, List<String> supplierLabels,
        long quantity, long returnedQuantity, long transactionCount,
        BigDecimal grossAmount, BigDecimal discountAmount, BigDecimal refundAmount
) {
    public BigDecimal revenue() {
        return grossAmount.subtract(discountAmount).subtract(refundAmount);
    }
}
