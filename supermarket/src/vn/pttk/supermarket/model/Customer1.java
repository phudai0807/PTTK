package vn.pttk.supermarket.model;

import java.util.Objects;

public class Customer1 {
    private String fullName;
    private String phone;
    private String email;
    private String address;
    private String passwordHash;

    public Customer1() {
    }

    public Customer1(
            String fullName,
            String phone,
            String email,
            String address,
            String passwordHash) {
        this.fullName = fullName;
        this.phone = phone;
        this.email = email;
        this.address = address;
        this.passwordHash = passwordHash;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || getClass() != other.getClass()) {
            return false;
        }
        Customer1 that = (Customer1) other;
        return Objects.equals(fullName, that.fullName)
                && Objects.equals(phone, that.phone)
                && Objects.equals(email, that.email)
                && Objects.equals(address, that.address)
                && Objects.equals(passwordHash, that.passwordHash);
    }

    @Override
    public int hashCode() {
        return Objects.hash(
                fullName,
                phone,
                email,
                address,
                passwordHash);
    }

    @Override
    public String toString() {
        return "Customer1[fullName=" + fullName
                + ", phone=" + phone
                + ", email=" + email
                + ", address=" + address
                + ", passwordHash=" + passwordHash + "]";
    }
}
