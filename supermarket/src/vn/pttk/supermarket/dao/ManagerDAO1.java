package vn.pttk.supermarket.dao;

import vn.pttk.supermarket.web.PasswordHash1;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Locale;

public class ManagerDAO1 extends DAO1 {
    public ManagerDAO1() throws SQLException {
        super();
    }

    public Long authenticate(String identifier, String password) throws SQLException {
        String sql = "{? = call find_management_account1(?, ?)}";
        synchronized (DAO1.class) {
            ensureConnection();
            try (CallableStatement statement = con.prepareCall(sql)) {
                statement.registerOutParameter(1, Types.OTHER);
                statement.setString(2, identifier.toUpperCase(Locale.ROOT));
                statement.setString(3, identifier.toLowerCase(Locale.ROOT));
                statement.execute();
                Long managerId = null;
                try (ResultSet rows = (ResultSet) statement.getObject(1)) {
                    if (rows.next()) {
                        long id = rows.getLong("id");
                        String role = rows.getString("role");
                        String hash = rows.getString("password_hash");
                        // The identifier must refer to exactly one management account.
                        if (!rows.next() && "MANAGEMENT".equals(role) && PasswordHash1.matches(password, hash)) {
                            managerId = Long.valueOf(id);
                        }
                    }
                }
                con.commit();
                return managerId;
            } catch (SQLException exception) {
                rollback(exception);
                throw exception;
            }
        }
    }

    public boolean hasReportAccess(long employeeId) throws SQLException {
        String sql = "{? = call has_report_access1(?)}";
        synchronized (DAO1.class) {
            ensureConnection();
            try (CallableStatement statement = con.prepareCall(sql)) {
                statement.registerOutParameter(1, Types.BOOLEAN);
                statement.setLong(2, employeeId);
                statement.execute();
                boolean allowed = statement.getBoolean(1);
                con.commit();
                return allowed;
            } catch (SQLException exception) {
                rollback(exception);
                throw exception;
            }
        }
    }
}
