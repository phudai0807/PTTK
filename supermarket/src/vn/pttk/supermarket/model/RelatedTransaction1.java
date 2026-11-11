package vn.pttk.supermarket.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class RelatedTransaction1 {
    private String code;
    private String originalSaleCode;
    private LocalDateTime occurredAt;
    private String channel;
    private boolean refund;
    private long quantity;
    private List<BigDecimal> unitPrices = new ArrayList<BigDecimal>();
    private BigDecimal grossAmount = BigDecimal.ZERO;
    private BigDecimal discountAmount = BigDecimal.ZERO;
    private BigDecimal refundAmount = BigDecimal.ZERO;
    private BigDecimal transactionTotal = BigDecimal.ZERO;

    public RelatedTransaction1() {
    }

    public RelatedTransaction1(
            String code,
            String originalSaleCode,
            LocalDateTime occurredAt,
            String channel,
            boolean refund,
            long quantity,
            List<BigDecimal> unitPrices,
            BigDecimal grossAmount,
            BigDecimal discountAmount,
            BigDecimal refundAmount,
            BigDecimal transactionTotal) {
        this.code = code;
        this.originalSaleCode = originalSaleCode;
        this.occurredAt = occurredAt;
        this.channel = channel;
        this.refund = refund;
        this.quantity = quantity;
        this.unitPrices = unitPrices;
        this.grossAmount = grossAmount;
        this.discountAmount = discountAmount;
        this.refundAmount = refundAmount;
        this.transactionTotal = transactionTotal;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getOriginalSaleCode() {
        return originalSaleCode;
    }

    public void setOriginalSaleCode(String originalSaleCode) {
        this.originalSaleCode = originalSaleCode;
    }

    public LocalDateTime getOccurredAt() {
        return occurredAt;
    }

    public void setOccurredAt(LocalDateTime occurredAt) {
        this.occurredAt = occurredAt;
    }

    public String getChannel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public boolean isRefund() {
        return refund;
    }

    public void setRefund(boolean refund) {
        this.refund = refund;
    }

    public long getQuantity() {
        return quantity;
    }

    public void setQuantity(long quantity) {
        this.quantity = quantity;
    }

    public List<BigDecimal> getUnitPrices() {
        return unitPrices;
    }

    public void setUnitPrices(List<BigDecimal> unitPrices) {
        this.unitPrices = unitPrices;
    }

    public BigDecimal getGrossAmount() {
        return grossAmount;
    }

    public void setGrossAmount(BigDecimal grossAmount) {
        this.grossAmount = grossAmount;
    }

    public BigDecimal getDiscountAmount() {
        return discountAmount;
    }

    public void setDiscountAmount(BigDecimal discountAmount) {
        this.discountAmount = discountAmount;
    }

    public BigDecimal getRefundAmount() {
        return refundAmount;
    }

    public void setRefundAmount(BigDecimal refundAmount) {
        this.refundAmount = refundAmount;
    }

    public BigDecimal getTransactionTotal() {
        return transactionTotal;
    }

    public void setTransactionTotal(BigDecimal transactionTotal) {
        this.transactionTotal = transactionTotal;
    }

    public BigDecimal getItemAmount() {
        return grossAmount.subtract(discountAmount).subtract(refundAmount);
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || getClass() != other.getClass()) {
            return false;
        }
        RelatedTransaction1 that = (RelatedTransaction1) other;
        return Objects.equals(code, that.code)
                && Objects.equals(originalSaleCode, that.originalSaleCode)
                && Objects.equals(occurredAt, that.occurredAt)
                && Objects.equals(channel, that.channel)
                && refund == that.refund
                && quantity == that.quantity
                && Objects.equals(unitPrices, that.unitPrices)
                && Objects.equals(grossAmount, that.grossAmount)
                && Objects.equals(discountAmount, that.discountAmount)
                && Objects.equals(refundAmount, that.refundAmount)
                && Objects.equals(transactionTotal, that.transactionTotal);
    }

    @Override
    public int hashCode() {
        return Objects.hash(
                code,
                originalSaleCode,
                occurredAt,
                channel,
                refund,
                quantity,
                unitPrices,
                grossAmount,
                discountAmount,
                refundAmount,
                transactionTotal);
    }

    @Override
    public String toString() {
        return "RelatedTransaction1[code=" + code
                + ", originalSaleCode=" + originalSaleCode
                + ", occurredAt=" + occurredAt
                + ", channel=" + channel
                + ", refund=" + refund
                + ", quantity=" + quantity
                + ", unitPrices=" + unitPrices
                + ", grossAmount=" + grossAmount
                + ", discountAmount=" + discountAmount
                + ", refundAmount=" + refundAmount
                + ", transactionTotal=" + transactionTotal + "]";
    }
}
