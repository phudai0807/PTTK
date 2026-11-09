package vn.pttk.supermarket.web;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

public final class Html1 {
    private static final Locale VIETNAMESE = Locale.forLanguageTag("vi-VN");

    private Html1() { }

    public static String escape(Object value) {
        return value == null ? "" : value.toString()
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    public static String number(Number value) {
        return NumberFormat.getNumberInstance(VIETNAMESE).format(value);
    }

    public static String money(BigDecimal value) {
        return number(value) + " ₫";
    }
}
