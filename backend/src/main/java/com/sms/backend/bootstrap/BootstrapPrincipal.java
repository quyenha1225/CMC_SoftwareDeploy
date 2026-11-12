package com.sms.backend.bootstrap;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.*;

@Component
public class BootstrapPrincipal implements CommandLineRunner {
    private final Db db;
    private final PasswordEncoder encoder;
    private final TransactionTemplate transaction;
    private final boolean enabled;
    private final String username, email, password;

    public BootstrapPrincipal(
            Db db,
            PasswordEncoder encoder,
            org.springframework.transaction.PlatformTransactionManager manager,
            @Value("${sms.bootstrap.enabled}") boolean enabled,
            @Value("${sms.bootstrap.username}") String username,
            @Value("${sms.bootstrap.email}") String email,
            @Value("${sms.bootstrap.password}") String password) {
        this.db = db;
        this.encoder = encoder;
        this.transaction = new TransactionTemplate(manager);
        this.enabled = enabled;
        this.username = username;
        this.email = email;
        this.password = password;
    }

    @Override
    public void run(String... args) {
        if (!enabled) return;
        if (!username.matches("[a-zA-Z0-9._-]{3,80}")
                || !email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")
                || password.length() < 12)
            throw new IllegalStateException(
                    "Bootstrap yêu cầu username/email hợp lệ và mật khẩu tối thiểu 12 ký tự qua"
                            + " biến môi trường.");
        transaction.executeWithoutResult(
                status -> {
                    db.one("SELECT id FROM roles WHERE code='PRINCIPAL' FOR UPDATE");
                    if (db.number(
                                    "SELECT COUNT(*) FROM users u JOIN user_roles ur ON"
                                        + " ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE"
                                        + " r.code='PRINCIPAL' AND u.enabled=TRUE")
                            > 0)
                        throw new IllegalStateException(
                                "Đã có tài khoản BGH hoạt động. Tắt SMS_BOOTSTRAP_ENABLED.");
                    if (db.number(
                                    "SELECT COUNT(*) FROM users WHERE username=? OR email=?",
                                    username,
                                    email)
                            > 0)
                        throw new IllegalStateException(
                                "Tên bootstrap đã tồn tại; không ghi đè tài khoản cũ.");
                    long id =
                            db.insert(
                                    "users",
                                    map(
                                            "username",
                                            username,
                                            "email",
                                            email,
                                            "full_name",
                                            "Quản trị nhà trường",
                                            "password_hash",
                                            encoder.encode(password),
                                            "enabled",
                                            true));
                    db.run(
                            "INSERT INTO user_roles(user_id,role_id) SELECT ?,id FROM roles WHERE"
                                    + " code='PRINCIPAL'",
                            id);
                });
    }
}
