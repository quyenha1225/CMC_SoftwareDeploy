package com.sms.backend;

import static com.sms.backend.repository.Db.map;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.sms.backend.repository.Db;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/** Optional browser audit against an isolated, disposable H2 database. */
@EnabledIfEnvironmentVariable(named = "SMS_RUN_BROWSER_TESTS", matches = "true")
@ActiveProfiles("test")
@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT,
        properties = {
            "server.port=8082",
            "server.address=127.0.0.1",
            "spring.datasource.url=jdbc:h2:mem:ui_audit;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"
        })
class UiBrowserTests {
    @Autowired Db db;
    @Autowired PasswordEncoder encoder;

    @Test
    void auditAllSixRolesWithoutChangingMysql() throws Exception {
        db.insert("rooms", map("code", "A101", "name", "Phòng A101", "active", true));
        db.insert("exam_types", map("code", "FINAL", "name", "Cuối kỳ", "active", true));
        String password = UUID.randomUUID() + "Ui!";
        String hash = encoder.encode(password);
        for (String role :
                List.of(
                        "PRINCIPAL",
                        "CTSV",
                        "TRAINING_OFFICE",
                        "LECTURER",
                        "STUDENT",
                        "APPLICANT")) {
            long roleId = db.insert("roles", map("code", role, "description", role));
            long user =
                    db.insert(
                            "users",
                            map(
                                    "username",
                                    role.toLowerCase(),
                                    "email",
                                    role.toLowerCase() + "@ui.example.test",
                                    "full_name",
                                    "Kiểm tra " + role,
                                    "password_hash",
                                    hash,
                                    "enabled",
                                    true));
            db.run("INSERT INTO user_roles(user_id,role_id) VALUES(?,?)", user, roleId);
        }
        long faculty = db.insert("faculties", map("code", "IT", "name", "Công nghệ thông tin"));
        long major =
                db.insert(
                        "majors",
                        map("faculty_id", faculty, "code", "SE", "name", "Kỹ thuật phần mềm"));
        long cohort =
                db.insert("cohorts", map("code", "K2026", "start_year", 2026, "end_year", 2030));
        long classroom =
                db.insert(
                        "academic_classes",
                        map(
                                "major_id",
                                major,
                                "cohort_id",
                                cohort,
                                "code",
                                "SE26-A",
                                "name",
                                "Kỹ thuật phần mềm 26A"));
        long student =
                db.insert(
                        "students",
                        map(
                                "user_id",
                                user("student"),
                                "class_id",
                                classroom,
                                "student_code",
                                "UI26001",
                                "phone",
                                "0900000000",
                                "address",
                                "Hà Nội",
                                "status",
                                "STUDYING"));
        long lecturer =
                db.insert(
                        "lecturers",
                        map(
                                "user_id",
                                user("lecturer"),
                                "faculty_id",
                                faculty,
                                "lecturer_code",
                                "UI-GV01"));
        LocalDate today = LocalDate.now();
        long year =
                db.insert(
                        "academic_years",
                        map(
                                "name",
                                "2026–2027",
                                "starts_on",
                                today.minusMonths(2),
                                "ends_on",
                                today.plusMonths(10)));
        long term =
                db.insert(
                        "semesters",
                        map(
                                "academic_year_id",
                                year,
                                "code",
                                "HK1",
                                "starts_on",
                                today.minusMonths(1),
                                "ends_on",
                                today.plusMonths(3),
                                "registration_from",
                                today.minusDays(2).atStartOfDay(),
                                "registration_to",
                                today.plusDays(10).atStartOfDay(),
                                "status",
                                "OPEN"));
        long course =
                db.insert(
                        "courses",
                        map(
                                "course_code",
                                "SE101",
                                "title",
                                "Nhập môn kỹ thuật phần mềm",
                                "credits",
                                3,
                                "active",
                                true));
        long curriculum =
                db.insert(
                        "curricula",
                        map(
                                "major_id",
                                major,
                                "cohort_id",
                                cohort,
                                "title",
                                "Chương trình KTPM 2026"));
        db.run(
                "INSERT INTO"
                    + " curriculum_courses(curriculum_id,course_id,suggested_semester,required_course)"
                    + " VALUES(?,?,1,TRUE)",
                curriculum,
                course);
        long section =
                db.insert(
                        "course_sections",
                        map(
                                "semester_id",
                                term,
                                "course_id",
                                course,
                                "lecturer_id",
                                lecturer,
                                "section_code",
                                "SE101-01",
                                "capacity",
                                40,
                                "attendance_weight",
                                10,
                                "midterm_weight",
                                30,
                                "final_weight",
                                60,
                                "is_open",
                                true));
        db.insert(
                "section_schedules",
                map(
                        "section_id",
                        section,
                        "day_of_week",
                        1,
                        "starts_at",
                        "07:00:00",
                        "ends_at",
                        "09:00:00",
                        "room",
                        "A101",
                        "room_id",
                        db.number("SELECT id FROM rooms WHERE code='A101'")));
        db.insert("grade_sheets", map("section_id", section, "status", "DRAFT"));
        long enrollment =
                db.insert(
                        "enrollments",
                        map("student_id", student, "section_id", section, "status", "REGISTERED"));
        db.insert(
                "grades",
                map(
                        "enrollment_id",
                        enrollment,
                        "attendance_score",
                        8,
                        "midterm_score",
                        7,
                        "final_score",
                        9));
        db.insert("tuition_rates", map("semester_id", term, "price_per_credit", 850000));
        long invoice = db.insert("invoices", map("student_id", student, "semester_id", term));
        db.insert(
                "invoice_items",
                map(
                        "invoice_id",
                        invoice,
                        "enrollment_id",
                        enrollment,
                        "credits_at_issue",
                        3,
                        "unit_price_at_issue",
                        850000));
        long fund =
                db.insert(
                        "ctsv_funds",
                        map(
                                "code",
                                "CASH",
                                "name",
                                "Quỹ tiền mặt CTSV",
                                "channel",
                                "CASH",
                                "active",
                                true));
        db.insert(
                "payments",
                map(
                        "invoice_id",
                        invoice,
                        "fund_id",
                        fund,
                        "recorded_by",
                        user("ctsv"),
                        "amount",
                        500000,
                        "reference_no",
                        "UI-001",
                        "paid_at",
                        java.time.LocalDateTime.now()));
        db.insert(
                "student_school_mailboxes",
                map(
                        "student_id",
                        student,
                        "school_email",
                        "ui26001@student.example.test",
                        "provisioning_status",
                        "RESERVED"));
        db.insert(
                "student_requests",
                map(
                        "request_code",
                        "UI-REQ-001",
                        "student_id",
                        student,
                        "request_type",
                        "DOCUMENT_REQUEST",
                        "content",
                        "Đề nghị xác nhận sinh viên",
                        "status",
                        "PROCESSING",
                        "handled_by",
                        user("training_office")));
        long period =
                db.insert(
                        "admission_periods",
                        map(
                                "code",
                                "UI2026",
                                "title",
                                "Nhập học 2026",
                                "cohort_id",
                                cohort,
                                "opens_at",
                                today.minusDays(10).atStartOfDay(),
                                "closes_at",
                                today.plusMonths(2).atStartOfDay(),
                                "status",
                                "OPEN"));
        db.insert(
                "admission_applications",
                map(
                        "application_code",
                        "UI-HS-001",
                        "applicant_user_id",
                        user("applicant"),
                        "period_id",
                        period,
                        "major_id",
                        major,
                        "legal_full_name",
                        "Ứng viên kiểm tra",
                        "personal_email",
                        "applicant@ui.example.test",
                        "phone",
                        "0900000001",
                        "status",
                        "DRAFT"));
        long notification =
                db.insert(
                        "notifications",
                        map(
                                "notification_code",
                                "UI-NOTICE",
                                "created_by",
                                user("ctsv"),
                                "title",
                                "Thông báo kiểm tra giao diện",
                                "body",
                                "Lịch học và hướng dẫn học vụ."));
        for (var row : db.rows("SELECT id FROM users"))
            db.run(
                    "INSERT INTO notification_recipients(notification_id,user_id) VALUES(?,?)",
                    notification,
                    row.get("id"));

        Path frontend = Path.of("..").toAbsolutePath().normalize().resolve("frontend");
        ProcessBuilder builder =
                new ProcessBuilder("node", "tests/browser-full-ui.mjs")
                        .directory(frontend.toFile())
                        .inheritIO();
        builder.environment().put("SMS_UI_FIXTURE", "true");
        builder.environment().put("SMS_UI_PASSWORD", password);
        Process browser = builder.start();
        if (!browser.waitFor(6, TimeUnit.MINUTES)) {
            browser.destroyForcibly();
            throw new AssertionError("Browser audit timed out");
        }
        assertEquals(
                0, browser.exitValue(), "See screenshots/recheck-2026-11-12/six-roles/report.json");
    }

    private long user(String username) {
        return db.number("SELECT id FROM users WHERE username=?", username);
    }
}
