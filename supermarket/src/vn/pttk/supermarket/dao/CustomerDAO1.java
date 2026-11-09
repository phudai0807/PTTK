package vn.pttk.supermarket.dao;

import vn.pttk.supermarket.model.Customer1;
import org.postgresql.util.PSQLException;
import java.sql.SQLException;

public final class CustomerDAO1 {
    public enum RegistrationResult1 { CREATED, DUPLICATE_PHONE, DUPLICATE_EMAIL }

    public RegistrationResult1 register(Customer1 customer) throws SQLException {
        String sql = """
                INSERT INTO customers1 (full_name, phone, email, address, password_hash, is_member)
                VALUES (?, normalize_customer_phone(?), ?, ?, ?, true)
                ON CONFLICT (email) DO NOTHING
                """;
        try (var connection = Database1.open();
             var statement = connection.prepareStatement(sql)) {
            statement.setString(1, customer.fullName());
            statement.setString(2, customer.phone());
            statement.setString(3, customer.email());
            statement.setString(4, customer.address());
            statement.setString(5, customer.passwordHash());
            return statement.executeUpdate() == 1 ? RegistrationResult1.CREATED : RegistrationResult1.DUPLICATE_EMAIL;
        } catch (PSQLException exception) {
            var error = exception.getServerErrorMessage();
            if ("23505".equals(exception.getSQLState()) && error != null
                    && "uq_member_phone1".equals(error.getConstraint())) {
                return RegistrationResult1.DUPLICATE_PHONE;
            }
            throw exception;
        }
    }
}
