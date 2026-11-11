package vn.pttk.supermarket.dao;

import vn.pttk.supermarket.model.Customer1;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

public class CustomerDAO1 extends DAO1 {
    public static final int CREATED = 1;
    public static final int DUPLICATE_PHONE = 2;
    public static final int DUPLICATE_EMAIL = 3;

    public CustomerDAO1() throws SQLException {
        super();
    }

    public int register(Customer1 customer) throws SQLException {
        String sql = "{? = call register_member1(?, ?, ?, ?, ?)}";
        synchronized (DAO1.class) {
            ensureConnection();
            try (CallableStatement statement = con.prepareCall(sql)) {
                statement.registerOutParameter(1, Types.INTEGER);
                statement.setString(2, customer.getFullName());
                statement.setString(3, customer.getPhone());
                statement.setString(4, customer.getEmail());
                statement.setString(5, customer.getAddress());
                statement.setString(6, customer.getPasswordHash());
                statement.execute();
                int result = statement.getInt(1);
                con.commit();
                return result;
            } catch (SQLException exception) {
                rollback(exception);
                throw exception;
            }
        }
    }
}
