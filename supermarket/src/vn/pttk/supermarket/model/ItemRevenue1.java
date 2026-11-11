package vn.pttk.supermarket.model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class ItemRevenue1 {
    private long itemId;
    private String code;
    private String name;
    private String unit;
    private List<String> supplierLabels = new ArrayList<String>();
    private long quantity;
    private long returnedQuantity;
    private long transactionCount;
    private BigDecimal grossAmount = BigDecimal.ZERO;
    private BigDecimal discountAmount = BigDecimal.ZERO;
    private BigDecimal refundAmount = BigDecimal.ZERO;

    public ItemRevenue1() {
    }

    public ItemRevenue1(
            long itemId,
            String code,
            String name,
            String unit,
            List<String> supplierLabels,
            long quantity,
            long returnedQuantity,
            long transactionCount,
            BigDecimal grossAmount,
            BigDecimal discountAmount,
            BigDecimal refundAmount) {
        this.itemId = itemId;
        this.code = code;
        this.name = name;
        this.unit = unit;
        this.supplierLabels = supplierLabels;
        this.quantity = quantity;
        this.returnedQuantity = returnedQuantity;
        this.transactionCount = transactionCount;
        this.grossAmount = grossAmount;
        this.discountAmount = discountAmount;
        this.refundAmount = refundAmount;
    }

    public long getItemId() {
        return itemId;
    }

    public void setItemId(long itemId) {
        this.itemId = itemId;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
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
        if (this == other) {
            return true;
        }
        if (other == null || getClass() != other.getClass()) {
            return false;
        }
        ItemRevenue1 that = (ItemRevenue1) other;
        return itemId == that.itemId
                && Objects.equals(code, that.code)
                && Objects.equals(name, that.name)
                && Objects.equals(unit, that.unit)
                && Objects.equals(supplierLabels, that.supplierLabels)
                && quantity == that.quantity
                && returnedQuantity == that.returnedQuantity
                && transactionCount == that.transactionCount
                && Objects.equals(grossAmount, that.grossAmount)
                && Objects.equals(discountAmount, that.discountAmount)
                && Objects.equals(refundAmount, that.refundAmount);
    }

    @Override
    public int hashCode() {
        return Objects.hash(
                itemId,
                code,
                name,
                unit,
                supplierLabels,
                quantity,
                returnedQuantity,
                transactionCount,
                grossAmount,
                discountAmount,
                refundAmount);
    }

    @Override
    public String toString() {
        return "ItemRevenue1[itemId=" + itemId
                + ", code=" + code
                + ", name=" + name
                + ", unit=" + unit
                + ", supplierLabels=" + supplierLabels
                + ", quantity=" + quantity
                + ", returnedQuantity=" + returnedQuantity
                + ", transactionCount=" + transactionCount
                + ", grossAmount=" + grossAmount
                + ", discountAmount=" + discountAmount
                + ", refundAmount=" + refundAmount + "]";
    }
}
