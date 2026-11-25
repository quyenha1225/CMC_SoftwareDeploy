package com.sms.backend.bootstrap;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Properties;

/** Explicit Docker CLI utility. Never exposed over HTTP or run on normal app startup. */
public final class DemoProvisioner {
    // These are the disabled placeholder hashes from the immutable Flyway demo seed (V2).
    // Keep them per username so a disabled account with a real password is never reactivated.
    private static final Map<String, String> SEED_HASHES = Map.ofEntries(
            Map.entry("principal_demo", "$2a$12$PPLg2JpIqF/i8uD3f./c/OGMiyvCe41EPTMEO.dv1YiHl4vDmyCrq"),
            Map.entry("training_demo", "$2a$12$H4Q9k5WMeYU8CH41jA5Wiu8zcLrZdX8sQDNOEhtburyaXDmGk4odS"),
            Map.entry("lecturer_demo_01", "$2a$12$hKhjq7XPqPuYouPULY.1MukAtJ7A4YfqcwlBxVRuO44pKXzBv6fFi"),
            Map.entry("lecturer_demo_02", "$2a$12$jjif502I6evD0LSRnqS3b.RM0YzuxEipNz/6rAsl3JWkZpw.Sm.4q"),
            Map.entry("lecturer_demo_03", "$2a$12$Z0DqJ.PQ0WCmzZyCXjJwAeWkSl2C.HsAs2K06NZsecWPhTx1Kzff."),
            Map.entry("student_demo_001", "$2a$12$WB/jAHTw2ENa0vnNC.xVmOT2flWz2/Iv5N3Zn5KnVTUop/cimjQ.K"),
            Map.entry("student_demo_002", "$2a$12$Tg9Jo96w2K7kdz9LzVDHf.AnimqanhFurXSr/U0DWq8VZ5Xaitya."),
            Map.entry("student_demo_003", "$2a$12$ENdpuKHgvJkgeU1aGXBPx.mkKsjlvPfOuuWSQOpwxU2je5KZgkjse"),
            Map.entry("student_demo_004", "$2a$12$OZQwkC2ynwhTnlxGuI0Fbu/lP3RyfwmC0iKomBwEIUCAijZOR7eri"),
            Map.entry("student_demo_005", "$2a$12$3Cm74ibG.6AmcbKr1la6SueEBvbq4H2ZDGwBgsKVWM7k55mhYp.6O"),
            Map.entry("student_demo_006", "$2a$12$if.fXzUgpA.sXbMOXXt.EO.nMpzutTfTuwegBbcMw67VXTQkb04QO"),
            Map.entry("ctsv_demo", "!ACCOUNT_DISABLED"),
            Map.entry("applicant_demo_03", "!ACCOUNT_DISABLED"),
            Map.entry("applicant_demo_04", "!ACCOUNT_DISABLED"));

    private DemoProvisioner() {}

    public static void main(String[] args) throws Exception {
        if (!"local".equals(System.getenv("SMS_ENVIRONMENT"))
                || !"true".equals(System.getenv("SMS_SEED_DEMO"))) {
            throw new IllegalStateException(
                    "Demo provisioning is allowed only on local demo databases.");
        }
        boolean initialize = args.length == 1 && args[0].equals("--initialize");
        if (args.length != 0 && !initialize) {
            throw new IllegalArgumentException("Demo provision accepts only --initialize for a fresh seed.");
        }
        var passwords = new Properties();
        try (Reader reader = Files.newBufferedReader(Path.of("/run/secrets/demo_accounts"))) {
            passwords.load(reader);
        }
        var names = new LinkedHashSet<String>();
        names.add("principal");
        names.addAll(SEED_HASHES.keySet().stream().sorted().toList());
        if (!passwords.stringPropertyNames().equals(names)) {
            throw new IllegalStateException("Expected exactly the 15 named demo accounts.");
        }
        String password = Files.readString(Path.of("/run/secrets/DB_PASSWORD")).strip();
        var encoder = new BCryptPasswordEncoder(12);
        try (Connection connection =
                DriverManager.getConnection(System.getenv("DB_URL"), "sms_app", password)) {
            connection.setAutoCommit(false);
            try {
                boolean freshSeed = false;
                for (String name : names) {
                    String plain = passwords.getProperty(name);
                    validatePassword(name, plain);
                    try (var select =
                            connection.prepareStatement(
                                    "SELECT id,password_hash,enabled FROM users WHERE username=?"
                                            + " FOR UPDATE")) {
                        select.setString(1, name);
                        try (var rows = select.executeQuery()) {
                            if (!rows.next()) {
                                if (!initialize || !name.equals("principal")) {
                                    throw new IllegalStateException("Required demo account missing: " + name);
                                }
                                freshSeed = true;
                                createPrincipal(connection, encoder.encode(plain));
                            } else if (shouldUpdatePassword(
                                    name,
                                    rows.getBoolean("enabled"),
                                    plain,
                                    rows.getString("password_hash"),
                                    freshSeed,
                                    encoder)) {
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

    static void validatePassword(String username, String password) {
        int minimumLength = username.equals("ctsv_demo") ? 8 : 12;
        if (password == null
                || password.length() < minimumLength
                || password.length() > 72
                || !password.matches("[A-Za-z0-9_!@.-]+")) {
            throw new IllegalStateException("Invalid local demo password format.");
        }
    }

    static boolean shouldUpdatePassword(
            String username,
            boolean enabled,
            String plain,
            String passwordHash,
            boolean initialize,
            BCryptPasswordEncoder encoder) {
        if (!enabled) {
            if (initialize && passwordHash.equals(SEED_HASHES.get(username))) return true;
            throw new IllegalStateException("Demo account is disabled; activation refused: " + username);
        }
        if (!encoder.matches(plain, passwordHash)) {
            throw new IllegalStateException(
                    "Enabled demo account password differs; no password was reset: " + username);
        }
        return false;
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
