package com.sms.backend.service.mail;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

import com.sms.backend.repository.Db;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.transaction.PlatformTransactionManager;

class OutboxWorkerTests {
    private final OutboxWorker worker =
            new OutboxWorker(
                    mock(Db.class),
                    mock(JavaMailSender.class),
                    mock(PlatformTransactionManager.class),
                    true,
                    "school@example.test");

    @Test
    void usesSavedBodyAndTemplatesForQueuedNotices() {
        assertEquals(
                "Saved message",
                worker.body(Map.of("body_text", "  Saved message  ", "subject", "Subject")));

        String received =
                worker.body(
                        Map.of(
                                "template_code", "ADMISSION_RECEIVED",
                                "subject", "Application received"));
        String status =
                worker.body(
                        Map.of(
                                "template_code", "ADMISSION_STATUS",
                                "subject", "Application updated"));
        String generic = worker.body(Map.of("subject", "General notice"));

        assertTrue(received.contains("Application received"));
        assertTrue(received.contains("trực tuyến"));
        assertTrue(status.contains("Application updated"));
        assertTrue(status.contains("trạng thái"));
        assertTrue(generic.contains("General notice"));
        assertNotEquals(received, status);
        assertNotEquals(status, generic);
        assertTrue(generic.contains("Không gửi mật khẩu"));
    }

    @Test
    void fallsBackWhenSubjectIsMissing() {
        assertTrue(worker.body(new HashMap<>()).contains("Thông báo EduPortal"));
    }
}
