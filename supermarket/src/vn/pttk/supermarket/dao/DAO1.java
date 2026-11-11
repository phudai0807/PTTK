package vn.pttk.supermarket.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DAO1 {
    // DAO methods lock DAO1.class so concurrent requests cannot share a transaction.
    protected static Connection con;

    public DAO1() throws SQLException {
        ensureConnection();
    }

    protected static synchronized void ensureConnection() throws SQLException {
        if (con != null && !con.isClosed() && con.isValid(2)) {
            return;
        }
        if (con != null && !con.isClosed()) {
            con.close();
        }
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
            con = connection;
        } catch (SQLException exception) {
            connection.close();
            throw exception;
        }
    }

    protected static void rollback(SQLException exception) {
        try {
            con.rollback();
        } catch (SQLException rollbackException) {
            exception.addSuppressed(rollbackException);
        }
    }
}
