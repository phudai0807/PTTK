package vn.pttk.supermarket.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record RelatedTransaction1(
        String code, String originalSaleCode, LocalDateTime occurredAt, String channel, boolean refund,
        long quantity, List<BigDecimal> unitPrices, BigDecimal grossAmount, BigDecimal discountAmount,
        BigDecimal refundAmount, BigDecimal transactionTotal
) {
    public BigDecimal itemAmount() {
        return grossAmount.subtract(discountAmount).subtract(refundAmount);
    }
}
