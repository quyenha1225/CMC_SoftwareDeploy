package com.sms.backend.bootstrap;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

/** Explicit Docker CLI utility. Never exposed over HTTP or run on normal app startup. */
public final class DemoProvisioner {
    private DemoProvisioner() {}

    public static void main(String[] args) throws Exception {
        if (!"local".equals(System.getenv("SMS_ENVIRONMENT"))
                || !"true".equals(System.getenv("SMS_SEED_DEMO"))) {
            throw new IllegalStateException(
                    "Demo provisioning is allowed only on local demo databases.");
        }
        var passwords = new Properties();
        try (Reader reader = Files.newBufferedReader(Path.of("/run/secrets/demo_accounts"))) {
            passwords.load(reader);
        }
        List<String> names =
                new ArrayList<>(
                        List.of(
                                "principal",
                                "principal_demo",
                                "training_demo",
                                "ctsv_demo",
                                "lecturer_demo_01",
                                "lecturer_demo_02",
                                "lecturer_demo_03",
                                "applicant_demo_03",
                                "applicant_demo_04"));
        for (int i = 1; i <= 6; i++) names.add("student_demo_%03d".formatted(i));
        if (!passwords.stringPropertyNames().equals(new java.util.HashSet<>(names))) {
            throw new IllegalStateException("Expected exactly the 15 named demo accounts.");
        }
        String password = Files.readString(Path.of("/run/secrets/DB_PASSWORD")).strip();
        var encoder = new BCryptPasswordEncoder(12);
        try (Connection connection =
                DriverManager.getConnection(System.getenv("DB_URL"), "sms_app", password)) {
            connection.setAutoCommit(false);
            try {
                for (String name : names) {
                    String plain = passwords.getProperty(name);
                    if (plain == null || !plain.matches("[A-Za-z0-9_!@.-]{12,72}")) {
                        throw new IllegalStateException("Invalid local demo password format.");
                    }
                    try (var select =
                            connection.prepareStatement(
                                    "SELECT id,password_hash,enabled FROM users WHERE username=?"
                                            + " FOR UPDATE")) {
                        select.setString(1, name);
                        try (var rows = select.executeQuery()) {
                            if (!rows.next()) {
                                if (!name.equals("principal"))
                                    throw new IllegalStateException("Demo seed incomplete.");
                                createPrincipal(connection, encoder.encode(plain));
                            } else if (rows.getBoolean("enabled")) {
                                if (!encoder.matches(plain, rows.getString("password_hash"))) {
                                    throw new IllegalStateException(
                                            "Enabled account password differs; no password was"
                                                    + " reset.");
                                }
                            } else {
                                try (var update =
                                        connection.prepareStatement(
                                                "UPDATE users SET enabled=TRUE,password_hash=?"
                                                        + " WHERE id=?")) {
                                    update.setString(1, encoder.encode(plain));
                                    update.setLong(2, rows.getLong("id"));
                                    update.executeUpdate();
                                }
                            }
                        }
                    }
                }
                connection.commit();
                System.out.println(
                        "Local demo accounts verified/provisioned: 15. Passwords were not logged.");
            } catch (Exception failure) {
                connection.rollback();
                throw failure;
            }
        }
    }

    private static void createPrincipal(Connection connection, String hash) throws Exception {
        try (var insert =
                connection.prepareStatement(
                        "INSERT INTO users(username,email,password_hash,full_name,enabled)"
                                + " VALUES('principal','principal@example.test',?,'Quản trị thực"
                                + " hành',TRUE)",
                        java.sql.Statement.RETURN_GENERATED_KEYS)) {
            insert.setString(1, hash);
            insert.executeUpdate();
            try (var keys = insert.getGeneratedKeys()) {
                if (!keys.next()) throw new IllegalStateException("Missing account ID.");
                try (var role =
                        connection.prepareStatement(
                                "INSERT INTO user_roles(user_id,role_id) SELECT ?,id FROM roles"
                                        + " WHERE code='PRINCIPAL'")) {
                    role.setLong(1, keys.getLong(1));
                    if (role.executeUpdate() != 1)
                        throw new IllegalStateException("Principal role missing.");
                }
            }
        }
    }
}
