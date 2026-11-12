package com.sms.backend.repository;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.*;

@Component
public class Db {
    public final JdbcTemplate jdbc;

    public Db(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> rows(String sql, Object... args) {
        var rows = jdbc.queryForList(sql, args);
        for (var row : rows) {
            row.replaceAll(
                    (key, value) -> {
                        if (value instanceof java.sql.Timestamp timestamp) {
                            return timestamp
                                    .toLocalDateTime()
                                    .format(java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                        }
                        if (value instanceof java.sql.Date date)
                            return date.toLocalDate().toString();
                        if (value instanceof java.sql.Time time) {
                            return time.toLocalTime()
                                    .format(java.time.format.DateTimeFormatter.ISO_LOCAL_TIME);
                        }
                        return value;
                    });
        }
        return rows;
    }

    public Map<String, Object> one(String sql, Object... args) {
        var rows = rows(sql, args);
        if (rows.isEmpty()) throw error(404, "Không tìm thấy dữ liệu.");
        return rows.getFirst();
    }

    public long number(String sql, Object... args) {
        var n = jdbc.queryForObject(sql, Long.class, args);
        return n == null ? 0 : n;
    }

    public int run(String sql, Object... args) {
        return jdbc.update(sql, args);
    }

    public long insert(String table, Map<String, Object> values) {
        var keys = new ArrayList<>(values.keySet());
        String sql =
                "INSERT INTO "
                        + table
                        + " ("
                        + String.join(",", keys)
                        + ") VALUES ("
                        + String.join(",", Collections.nCopies(keys.size(), "?"))
                        + ")";
        var holder = new GeneratedKeyHolder();
        jdbc.update(
                connection -> {
                    var ps = connection.prepareStatement(sql, new String[] {"id"});
                    for (int i = 0; i < keys.size(); i++)
                        ps.setObject(i + 1, values.get(keys.get(i)));
                    return ps;
                },
                holder);
        return Objects.requireNonNull(holder.getKey()).longValue();
    }

    public void update(String table, long id, Map<String, Object> values) {
        if (values.isEmpty()) throw error(400, "Không có trường cần cập nhật.");
        var args = new ArrayList<>(values.values());
        args.add(id);
        run(
                "UPDATE "
                        + table
                        + " SET "
                        + String.join(",", values.keySet().stream().map(key -> key + "=?").toList())
                        + " WHERE id=?",
                args.toArray());
    }

    public static Map<String, Object> map(Object... pairs) {
        var result = new LinkedHashMap<String, Object>();
        for (int i = 0; i < pairs.length; i += 2) result.put(pairs[i].toString(), pairs[i + 1]);
        return result;
    }

    public static long id(Object value) {
        try {
            long id = Long.parseLong(String.valueOf(value));
            if (id <= 0) throw new NumberFormatException();
            return id;
        } catch (Exception e) {
            throw error(400, "Mã dữ liệu không hợp lệ.");
        }
    }

    public static String text(Map<String, Object> input, String key, int max) {
        String value = Objects.toString(input.get(key), "").trim();
        if (value.isEmpty() || value.length() > max)
            throw error(400, "Kiểm tra trường " + key + " (tối đa " + max + " ký tự).");
        return value;
    }

    public static BigDecimal amount(Object value) {
        try {
            var n = new BigDecimal(String.valueOf(value));
            if (n.signum() <= 0 || n.scale() > 2 || n.precision() > 14)
                throw new NumberFormatException();
            return n;
        } catch (Exception e) {
            throw error(400, "Số tiền phải dương, tối đa hai chữ số thập phân.");
        }
    }

    public static ResponseStatusException error(int code, String message) {
        return new ResponseStatusException(HttpStatus.valueOf(code), message);
    }
}
