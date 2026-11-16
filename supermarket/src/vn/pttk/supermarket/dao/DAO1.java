package vn.pttk.supermarket.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DAO1 {
    // Each DAO keeps a private reference to the shared, class-locked connection.
    private Connection con;
    private static Connection sharedConnection;

    public DAO1() throws SQLException {
        ensureConnection();
    }

    final void ensureConnection() throws SQLException {
        synchronized (DAO1.class) {
            if (sharedConnection != null && !sharedConnection.isClosed() && sharedConnection.isValid(2)) {
                con = sharedConnection;
                return;
            }
            if (sharedConnection != null && !sharedConnection.isClosed()) {
                sharedConnection.close();
            }
            con = openConnection();
            sharedConnection = con;
        }
    }

    final Connection getConnection() {
        return con;
    }

    private static Connection openConnection() throws SQLException {
        String dbUrl = System.getenv().getOrDefault(
                "SUPERMARKET_DB_URL", "jdbc:postgresql://127.0.0.1:5432/supermarket_pttk");
        String username = System.getenv().getOrDefault("SUPERMARKET_DB_USER", "supermarket_dev");
        String password = System.getenv().getOrDefault("SUPERMARKET_DB_PASSWORD", "");
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException exception) {
            throw new SQLException("PostgreSQL JDBC driver is missing.", exception);
        }
        Connection connection = DriverManager.getConnection(dbUrl, username, password);
        try {
            // PostgreSQL cursors must be read inside a transaction.
            connection.setAutoCommit(false);
            return connection;
        } catch (SQLException exception) {
            connection.close();
            throw exception;
        }
    }

    final void rollback(SQLException exception) {
        try {
            con.rollback();
        } catch (SQLException rollbackException) {
            exception.addSuppressed(rollbackException);
        }
    }
}
