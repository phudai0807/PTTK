package vn.pttk.supermarket.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

final class Database1 {
    private static final String URL = System.getenv().getOrDefault(
            "SUPERMARKET_DB_URL", "jdbc:postgresql://127.0.0.1:5432/supermarket_pttk");
    private static final String USER = System.getenv().getOrDefault("SUPERMARKET_DB_USER", "supermarket_dev");
    private static final String PASSWORD = System.getenv().getOrDefault("SUPERMARKET_DB_PASSWORD", "");

    private Database1() { }

    static Connection open() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException exception) {
            throw new SQLException("PostgreSQL JDBC driver is missing.", exception);
        }
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
