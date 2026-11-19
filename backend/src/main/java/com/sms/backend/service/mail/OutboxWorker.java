package com.sms.backend.service.mail;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.*;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.*;

@Component
public class OutboxWorker {
    private final Db db;
    private final JavaMailSender mail;
    private final TransactionTemplate transaction;
    private final boolean enabled;
    private final String from;

    public OutboxWorker(
            Db db,
            JavaMailSender mail,
            PlatformTransactionManager manager,
            @Value("${sms.outbox.enabled}") boolean enabled,
            @Value("${sms.mail.from}") String from) {
        this.db = db;
        this.mail = mail;
        this.transaction = new TransactionTemplate(manager);
        this.enabled = enabled;
        this.from = from;
    }

    @Scheduled(fixedDelayString = "${sms.outbox.delay-ms}")
    public void tick() {
        if (!enabled || from.isBlank()) return;
        var row =
                transaction.execute(
                        status -> {
                            var rows =
                                    db.rows(
                                            "SELECT * FROM outbound_emails WHERE"
                                                + " (delivery_status='QUEUED' OR"
                                                + " (delivery_status='FAILED' AND attempt_count<3))"
                                                + " AND attempt_count<10 ORDER BY queued_at,id"
                                                + " LIMIT 1 FOR UPDATE");
                            if (rows.isEmpty()) return null;
                            var item = rows.getFirst();
                            db.run(
                                    "UPDATE outbound_emails SET"
                                        + " delivery_status='SENDING',attempt_count=attempt_count+1"
                                        + " WHERE id=?",
                                    item.get("id"));
                            return item;
                        });
        if (row != null) send(row);
    }

    private void send(Map<String, Object> row) {
        long id = Db.id(row.get("id"));
        int attempt = ((Number) row.get("attempt_count")).intValue() + 1;
        String result = "SENT", error = null;
        var message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(row.get("recipient_email").toString());
        message.setSubject(row.get("subject").toString());
        message.setText(body(row));
        try {
            mail.send(message);
        } catch (MailException e) {
            result = "FAILED";
            error = e.getClass().getSimpleName();
        }
        String finalResult = result, finalError = error;
        transaction.executeWithoutResult(
                status -> {
                    db.insert(
                            "email_delivery_attempts",
                            map(
                                    "outbound_email_id",
                                    id,
                                    "attempt_no",
                                    attempt,
                                    "result",
                                    finalResult,
                                    "error_code",
                                    finalError,
                                    "error_message",
                                    finalError));
                    db.run(
                            "UPDATE outbound_emails SET delivery_status=?,last_error=?,sent_at=?"
                                    + " WHERE id=?",
                            finalResult,
                            finalError,
                            "SENT".equals(finalResult) ? java.time.LocalDateTime.now() : null,
                            id);
                });
    }

    String body(Map<String, Object> row) {
        String saved = Objects.toString(row.get("body_text"), "").trim();
        if (!saved.isEmpty()) return saved;
        String subject = Objects.toString(row.get("subject"), "Thông báo EduPortal");
        String template = Objects.toString(row.get("template_code"), "");
        String message =
                switch (template) {
                    case "ADMISSION_RECEIVED" ->
                            "Nhà trường đã tiếp nhận hồ sơ trực tuyến của bạn. "
                                    + "Vui lòng đăng nhập EduPortal để theo dõi tiến độ xử lý hồ sơ.";
                    case "ADMISSION_STATUS" ->
                            "Hồ sơ của bạn đã được cập nhật trạng thái. "
                                    + "Vui lòng đăng nhập EduPortal để xem nội dung và việc cần thực hiện tiếp theo.";
                    default ->
                            "Vui lòng đăng nhập EduPortal để xem nội dung và trạng thái xử lý thông báo.";
                };
        return "Chào bạn,\n\n"
                + subject
                + "\n\n"
                + message
                + "\n\nKhông gửi mật khẩu hoặc giấy tờ cá nhân qua email phản hồi.";
    }
}
