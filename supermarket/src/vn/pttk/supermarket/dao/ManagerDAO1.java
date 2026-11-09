package vn.pttk.supermarket.dao;

import vn.pttk.supermarket.web.PasswordHash1;
import java.sql.SQLException;
import java.util.Locale;
import java.util.Optional;

public final class ManagerDAO1 {
    public Optional<Long> authenticate(String identifier, String password) throws SQLException {
        String sql = """
                SELECT id, role, password_hash
                FROM employees1
                WHERE employee_code = ? OR username = ?
                LIMIT 2
                """;
        try (var connection = Database1.open(); var statement = connection.prepareStatement(sql)) {
            statement.setString(1, identifier.toUpperCase(Locale.ROOT));
            statement.setString(2, identifier.toLowerCase(Locale.ROOT));
            try (var rows = statement.executeQuery()) {
                if (!rows.next()) {
                    return Optional.empty();
                }
                long id = rows.getLong("id");
                String role = rows.getString("role");
                String hash = rows.getString("password_hash");
                // Refuse an identifier that refers to more than one employee.
                if (rows.next() || !"MANAGEMENT".equals(role) || !PasswordHash1.matches(password, hash)) {
                    return Optional.empty();
                }
                return Optional.of(id);
            }
        }
    }

    public boolean hasReportAccess(long employeeId) throws SQLException {
        String sql = """
                SELECT 1 FROM employees1
                WHERE id = ? AND role = 'MANAGEMENT' AND password_hash IS NOT NULL
                """;
        try (var connection = Database1.open(); var statement = connection.prepareStatement(sql)) {
            statement.setLong(1, employeeId);
            try (var rows = statement.executeQuery()) {
                return rows.next();
            }
        }
    }
}
