package com.sms.backend.service.auth;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.*;
import java.util.*;

@Service
public class PasswordRecovery {
    public record Delivery(long id, String email, String token) {}

    private final Db db;
    private final PasswordEncoder encoder;
    private final JavaMailSender mail;
    private final String publicUrl, from;
    private final boolean enabled;

    public PasswordRecovery(
            Db db,
            PasswordEncoder encoder,
            JavaMailSender mail,
            @Value("${sms.public-url}") String url,
            @Value("${sms.mail.from}") String from,
            @Value("${sms.mail.enabled}") boolean enabled) {
        this.db = db;
        this.encoder = encoder;
        this.mail = mail;
        this.publicUrl = url;
        this.from = from;
        this.enabled = enabled;
        if (!url.matches("https?://[^\\s#?]+"))
            throw new IllegalArgumentException(
                    "sms.public-url must be an absolute HTTP(S) URL without query or fragment.");
    }

    public static String digest(String value) {
        try {
            return HexFormat.of()
                    .formatHex(
                            MessageDigest.getInstance("SHA-256")
                                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    @Transactional
    public Delivery issue(String email) {
        if (!enabled || from.isBlank())
            throw error(503, "Nhà trường chưa cấu hình dịch vụ gửi email. Vui lòng liên hệ CTSV.");
        var rows =
                db.rows(
                        "SELECT u.id,m.school_email FROM users u JOIN students s ON s.user_id=u.id"
                            + " JOIN student_school_mailboxes m ON m.student_id=s.id WHERE"
                            + " LOWER(m.school_email)=LOWER(?) AND m.provisioning_status='ACTIVE'"
                            + " AND u.enabled=TRUE AND EXISTS(SELECT 1 FROM user_roles ur JOIN"
                            + " roles r ON r.id=ur.role_id WHERE ur.user_id=u.id AND"
                            + " r.code='STUDENT')",
                        email);
        if (rows.size() != 1) return null;
        var row = rows.getFirst();
        long userId = Db.id(row.get("id"));
        db.one("SELECT id FROM users WHERE id=? FOR UPDATE", userId);
        db.run(
                "UPDATE password_reset_tokens SET used_at=CURRENT_TIMESTAMP WHERE user_id=? AND"
                        + " used_at IS NULL",
                userId);
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        long id =
                db.insert(
                        "password_reset_tokens",
                        map(
                                "user_id",
                                userId,
                                "token_hash",
                                digest(token),
                                "expires_at",
                                LocalDateTime.now().plusMinutes(20)));
        return new Delivery(id, row.get("school_email").toString(), token);
    }

    public void deliver(Delivery delivery) {
        if (delivery == null) return;
        var message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(delivery.email());
        message.setSubject("EduPortal — Khôi phục mật khẩu sinh viên");
        message.setText(
                "Bạn đã yêu cầu đặt lại mật khẩu EduPortal. Liên kết chỉ dùng một lần và hết hạn"
                        + " sau 20 phút:\n\n"
                        + publicUrl
                        + "/#reset-password/"
                        + delivery.token()
                        + "\n\n"
                        + "Nếu không yêu cầu, bạn có thể bỏ qua thư này. Nhà trường không yêu cầu"
                        + " gửi mật khẩu qua email.");
        try {
            mail.send(message);
            db.run(
                    "UPDATE password_reset_tokens SET delivery_status='SENT' WHERE id=?",
                    delivery.id());
        } catch (org.springframework.mail.MailException e) {
            db.run(
                    "UPDATE password_reset_tokens SET"
                            + " delivery_status='FAILED',used_at=CURRENT_TIMESTAMP WHERE id=?",
                    delivery.id());
        }
    }

    @Transactional
    public void reset(String token, String password) {
        if (!token.matches("[A-Za-z0-9_-]{43}")
                || password.length() < 12
                || password.length() > 128)
            throw error(400, "Kiểm tra liên kết và mật khẩu mới (12–128 ký tự).");
        var rows =
                db.rows(
                        "SELECT id,user_id FROM password_reset_tokens WHERE token_hash=? AND"
                                + " used_at IS NULL AND expires_at>CURRENT_TIMESTAMP AND"
                                + " delivery_status='SENT' FOR UPDATE",
                        digest(token));
        if (rows.size() != 1) throw error(400, "Liên kết không hợp lệ, đã dùng hoặc đã hết hạn.");
        var row = rows.getFirst();
        long id = Db.id(row.get("user_id"));
        db.one("SELECT id FROM users WHERE id=? AND enabled=TRUE FOR UPDATE", id);
        db.run("UPDATE users SET password_hash=? WHERE id=?", encoder.encode(password), id);
        db.run(
                "UPDATE password_reset_tokens SET used_at=CURRENT_TIMESTAMP WHERE user_id=? AND"
                        + " used_at IS NULL",
                id);
        db.insert(
                "audit_logs",
                map(
                        "actor_user_id",
                        id,
                        "action",
                        "RESET_PASSWORD",
                        "entity_type",
                        "users",
                        "entity_id",
                        String.valueOf(id)));
    }
}
