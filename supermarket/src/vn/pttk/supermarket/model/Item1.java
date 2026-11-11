package vn.pttk.supermarket.model;

import java.util.Objects;

public class Item1 {
    private long id;
    private String code;
    private String name;
    private String unit;
    private String description;

    public Item1() {
    }

    public Item1(
            long id,
            String code,
            String name,
            String unit,
            String description) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.unit = unit;
        this.description = description;
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || getClass() != other.getClass()) {
            return false;
        }
        Item1 that = (Item1) other;
        return id == that.id
                && Objects.equals(code, that.code)
                && Objects.equals(name, that.name)
                && Objects.equals(unit, that.unit)
                && Objects.equals(description, that.description);
    }

    @Override
    public int hashCode() {
        return Objects.hash(
                id,
                code,
                name,
                unit,
                description);
    }

    @Override
    public String toString() {
        return "Item1[id=" + id
                + ", code=" + code
                + ", name=" + name
                + ", unit=" + unit
                + ", description=" + description + "]";
    }
}
