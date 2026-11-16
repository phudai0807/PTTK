package vn.pttk.supermarket.model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class ItemStatistics1 extends Item1 {
    private List<String> supplierLabels = new ArrayList<String>();
    private long quantity;
    private long returnedQuantity;
    private long transactionCount;
    private BigDecimal grossAmount = BigDecimal.ZERO;
    private BigDecimal discountAmount = BigDecimal.ZERO;
    private BigDecimal refundAmount = BigDecimal.ZERO;

    public ItemStatistics1() {
    }

    public ItemStatistics1(long itemId, String code, String name, String unit,
            List<String> supplierLabels, long quantity, long returnedQuantity,
            long transactionCount, BigDecimal grossAmount,
            BigDecimal discountAmount, BigDecimal refundAmount) {
        super(itemId, code, name, unit, null);
        this.supplierLabels = supplierLabels;
        this.quantity = quantity;
        this.returnedQuantity = returnedQuantity;
        this.transactionCount = transactionCount;
        this.grossAmount = grossAmount;
        this.discountAmount = discountAmount;
        this.refundAmount = refundAmount;
    }

    public long getItemId() {
        return getId();
    }

    public void setItemId(long itemId) {
        setId(itemId);
    }

    public List<String> getSupplierLabels() {
        return supplierLabels;
    }

    public void setSupplierLabels(List<String> supplierLabels) {
        this.supplierLabels = supplierLabels;
    }

    public long getQuantity() {
        return quantity;
    }

    public void setQuantity(long quantity) {
        this.quantity = quantity;
    }

    public long getReturnedQuantity() {
        return returnedQuantity;
    }

    public void setReturnedQuantity(long returnedQuantity) {
        this.returnedQuantity = returnedQuantity;
    }

    public long getTransactionCount() {
        return transactionCount;
    }

    public void setTransactionCount(long transactionCount) {
        this.transactionCount = transactionCount;
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

    public BigDecimal getRevenue() {
        return grossAmount.subtract(discountAmount).subtract(refundAmount);
    }

    @Override
    public boolean equals(Object other) {
        if (!super.equals(other)) {
            return false;
        }
        ItemStatistics1 that = (ItemStatistics1) other;
        return quantity == that.quantity
                && returnedQuantity == that.returnedQuantity
                && transactionCount == that.transactionCount
                && Objects.equals(supplierLabels, that.supplierLabels)
                && Objects.equals(grossAmount, that.grossAmount)
                && Objects.equals(discountAmount, that.discountAmount)
                && Objects.equals(refundAmount, that.refundAmount);
    }

    @Override
    public int hashCode() {
        return Objects.hash(super.hashCode(), supplierLabels, quantity,
                returnedQuantity, transactionCount, grossAmount, discountAmount, refundAmount);
    }

    @Override
    public String toString() {
        return getClass().getSimpleName() + "[itemId=" + getItemId()
                + ", code=" + getCode() + ", name=" + getName() + ", unit=" + getUnit()
                + ", supplierLabels=" + supplierLabels + ", quantity=" + quantity
                + ", returnedQuantity=" + returnedQuantity + ", transactionCount=" + transactionCount
                + ", grossAmount=" + grossAmount + ", discountAmount=" + discountAmount
                + ", refundAmount=" + refundAmount + "]";
    }
}
