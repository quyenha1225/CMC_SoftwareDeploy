package com.sms.backend;

import static com.sms.backend.repository.Db.*;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.LoginTokens;
import com.sms.backend.service.auth.PasswordRecovery;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.util.*;

@SpringBootTest(properties = {"sms.mail.enabled=true", "sms.mail.from=school@example.test"})
@ActiveProfiles("test")
@Transactional
class V6SecurityTests {
    @org.springframework.test.context.bean.override.mockito.MockitoBean
    org.springframework.mail.javamail.JavaMailSender mail;

    @Autowired PasswordRecovery recovery;
    private static String testHash;
    @Autowired WebApplicationContext context;
    @Autowired Db db;
    @Autowired PasswordEncoder encoder;
    MockMvc mvc;
    long studentUser,
            otherUser,
            principal,
            ctsv,
            pdt,
            applicant,
            student,
            otherStudent,
            application;

    @BeforeEach
    void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        for (String role :
                List.of("STUDENT", "LECTURER", "PRINCIPAL", "CTSV", "TRAINING_OFFICE", "APPLICANT"))
            if (db.number("SELECT COUNT(*) FROM roles WHERE code=?", role) == 0)
                db.insert("roles", map("code", role));
        db.insert("rooms", map("code", "A101", "name", "Room A101", "active", true));
        db.insert("exam_types", map("code", "FINAL", "name", "Final", "active", true));
        studentUser = makeUser("student", "STUDENT");
        otherUser = makeUser("other", "STUDENT");
        principal = makeUser("principal", "PRINCIPAL");
        ctsv = makeUser("ctsv", "CTSV");
        pdt = makeUser("pdt", "TRAINING_OFFICE");
        applicant = makeUser("applicant", "APPLICANT");
        long faculty = db.insert("faculties", map("code", "IT", "name", "Faculty"));
        long major =
                db.insert("majors", map("code", "SE", "name", "Software", "faculty_id", faculty));
        long cohort =
                db.insert("cohorts", map("code", "K2026", "start_year", 2026, "end_year", 2030));
        long classroom =
                db.insert(
                        "academic_classes",
                        map(
                                "code",
                                "SE26",
                                "name",
                                "SE26",
                                "major_id",
                                major,
                                "cohort_id",
                                cohort));
        student =
                db.insert(
                        "students",
                        map("user_id", studentUser, "student_code", "SV1", "class_id", classroom));
        otherStudent =
                db.insert(
                        "students",
                        map("user_id", otherUser, "student_code", "SV2", "class_id", classroom));
        long period =
                db.insert(
                        "admission_periods",
                        map(
                                "code",
                                "P1",
                                "title",
                                "Admission",
                                "cohort_id",
                                cohort,
                                "opens_at",
                                "2020-01-01 00:00:00",
                                "closes_at",
                                "2099-01-01 00:00:00",
                                "status",
                                "OPEN"));
        application =
                db.insert(
                        "admission_applications",
                        map(
                                "application_code",
                                "HS1",
                                "applicant_user_id",
                                applicant,
                                "period_id",
                                period,
                                "major_id",
                                major,
                                "status",
                                "SENT_TO_SCHOOL"));
    }

    long makeUser(String username, String role) {
        if (testHash == null) testHash = encoder.encode("LongPassword123!");
        long id =
                db.insert(
                        "users",
                        map(
                                "username",
                                username,
                                "email",
                                username + "@example.test",
                                "full_name",
                                username,
                                "password_hash",
                                testHash,
                                "enabled",
                                true));
        db.run(
                "INSERT INTO user_roles(user_id,role_id) SELECT ?,id FROM roles WHERE code=?",
                id,
                role);
        return id;
    }

    @Test
    void resourceQueriesMatchV6Schema() throws Exception {
        for (String key :
                List.of(
                        "faculties",
                        "majors",
                        "cohorts",
                        "academic_classes",
                        "academic_years",
                        "semesters",
                        "courses",
                        "curricula",
                        "admission_periods",
                        "tuition_rates",
                        "ctsv_funds",
                        "lecturers",
                        "sections",
                        "students",
                        "admissions",
                        "enrollments",
                        "grades",
                        "grade_sheets",
                        "invoices",
                        "payments",
                        "adjustments",
                        "remittances",
                        "reports",
                        "requests",
                        "users",
                        "mailboxes",
                        "emails",
                        "audit",
                        "notifications")) {
            mvc.perform(
                            get("/api/resources/" + key + "?search=sample&page=1&size=5")
                                    .with(user("principal")))
                    .andExpect(status().isOk());
        }
    }

    @Test
    void actualLoginCreatesServerSession() throws Exception {
        var login =
                mvc.perform(
                                post("/api/auth/login")
                                        .with(csrf())
                                        .contentType("application/json")
                                        .content(
                                                "{\"username\":\"student\",\"password\":\"LongPassword123!\"}"))
                        .andExpect(status().isOk())
                        .andExpect(jsonPath("$.roles[0]").value("STUDENT"))
                        .andReturn();
        mvc.perform(
                        get("/api/me")
                                .cookie(login.getResponse().getCookie(LoginTokens.COOKIE))
                                .session(
                                        (org.springframework.mock.web.MockHttpSession)
                                                login.getRequest().getSession()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(studentUser));
    }

    @Test
    void registrationCannotGrantStaffRole() throws Exception {
        mvc.perform(
                        post("/api/public/admissions")
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"username\":\"newuser\",\"email\":\"new@example.test\",\"full_name\":\"Applicant\",\"password\":\"LongPassword123!\",\"role\":\"PRINCIPAL\"}"))
                .andExpect(status().isBadRequest());
        org.junit.jupiter.api.Assertions.assertEquals(
                0, db.number("SELECT COUNT(*) FROM users WHERE username='newuser'"));
    }

    @Test
    void standaloneRegistrationIsDisabled() throws Exception {
        mvc.perform(
                        post("/api/auth/register")
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void admissionCreatesOnlyApplicantAndDraftAtomically() throws Exception {
        long
                period =
                        db.number(
                                "SELECT period_id FROM admission_applications WHERE id=?",
                                application),
                major =
                        db.number(
                                "SELECT major_id FROM admission_applications WHERE id=?",
                                application);
        mvc.perform(
                        post("/api/public/admissions")
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"username\":\"newapplicant\",\"email\":\"newapplicant@example.test\",\"full_name\":\"New"
                                            + " Applicant\",\"password\":\"LongPassword123!\",\"period_id\":"
                                                + period
                                                + ",\"major_id\":"
                                                + major
                                                + "}"))
                .andExpect(status().isOk());
        org.junit.jupiter.api.Assertions.assertEquals(
                1,
                db.number(
                        "SELECT COUNT(*) FROM admission_applications a JOIN users u ON"
                                + " u.id=a.applicant_user_id WHERE u.username='newapplicant' AND"
                                + " a.status='DRAFT'"));
        org.junit.jupiter.api.Assertions.assertEquals(
                0,
                db.number(
                        "SELECT COUNT(*) FROM students s JOIN users u ON u.id=s.user_id WHERE"
                                + " u.username='newapplicant'"));
    }

    @Test
    void failedAdmissionDoesNotLeaveAccount() throws Exception {
        mvc.perform(
                        post("/api/public/admissions")
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"username\":\"orphan\",\"email\":\"orphan@example.test\",\"full_name\":\"Applicant\",\"password\":\"LongPassword123!\",\"period_id\":999999,\"major_id\":999999}"))
                .andExpect(status().isNotFound());
        org.junit.jupiter.api.Assertions.assertEquals(
                0, db.number("SELECT COUNT(*) FROM users WHERE username='orphan'"));
    }

    @Test
    void jwtCookieIsHttpOnlyAndRejectsTampering() throws Exception {
        var login =
                mvc.perform(
                                post("/api/auth/login")
                                        .with(csrf())
                                        .contentType("application/json")
                                        .content(
                                                "{\"username\":\"student\",\"password\":\"LongPassword123!\"}"))
                        .andExpect(status().isOk())
                        .andReturn();
        var cookie = login.getResponse().getCookie(LoginTokens.COOKIE);
        org.junit.jupiter.api.Assertions.assertTrue(cookie.isHttpOnly());
        org.junit.jupiter.api.Assertions.assertEquals("/api", cookie.getPath());
        var session =
                (org.springframework.mock.web.MockHttpSession) login.getRequest().getSession();
        mvc.perform(get("/api/me").session(session)).andExpect(status().isUnauthorized());
        mvc.perform(
                        get("/api/me")
                                .session(session)
                                .cookie(
                                        new jakarta.servlet.http.Cookie(
                                                LoginTokens.COOKIE, cookie.getValue() + "x")))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me").cookie(cookie)).andExpect(status().isUnauthorized());
    }

    @Test
    void passwordResetIsSingleUseAndInvalidatesExistingJwt() throws Exception {
        db.insert(
                "student_school_mailboxes",
                map(
                        "student_id",
                        student,
                        "school_email",
                        "student@school.test",
                        "provisioning_status",
                        "ACTIVE",
                        "activated_at",
                        java.time.LocalDateTime.now()));
        var login =
                mvc.perform(
                                post("/api/auth/login")
                                        .with(csrf())
                                        .contentType("application/json")
                                        .content(
                                                "{\"username\":\"student\",\"password\":\"LongPassword123!\"}"))
                        .andReturn();
        var delivery = recovery.issue("student@school.test");
        org.junit.jupiter.api.Assertions.assertNotNull(delivery);
        recovery.deliver(delivery);
        org.mockito.Mockito.verify(mail)
                .send(
                        org.mockito.ArgumentMatchers.any(
                                org.springframework.mail.SimpleMailMessage.class));
        org.junit.jupiter.api.Assertions.assertNotEquals(
                delivery.token(),
                db.one("SELECT token_hash FROM password_reset_tokens WHERE id=?", delivery.id())
                        .get("token_hash"));
        recovery.reset(delivery.token(), "ChangedPassword123!");
        org.junit.jupiter.api.Assertions.assertTrue(
                encoder.matches(
                        "ChangedPassword123!",
                        db.one("SELECT password_hash FROM users WHERE id=?", studentUser)
                                .get("password_hash")
                                .toString()));
        org.junit.jupiter.api.Assertions.assertThrows(
                org.springframework.web.server.ResponseStatusException.class,
                () -> recovery.reset(delivery.token(), "ChangedPassword456!"));
        mvc.perform(
                        get("/api/me")
                                .session(
                                        (org.springframework.mock.web.MockHttpSession)
                                                login.getRequest().getSession())
                                .cookie(login.getResponse().getCookie(LoginTokens.COOKIE)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void recoveryRequiresActivatedSchoolMailboxAndExpiry() throws Exception {
        org.junit.jupiter.api.Assertions.assertNull(recovery.issue("student@example.test"));
        db.insert(
                "student_school_mailboxes",
                map(
                        "student_id",
                        student,
                        "school_email",
                        "student@school.test",
                        "provisioning_status",
                        "RESERVED"));
        org.junit.jupiter.api.Assertions.assertNull(recovery.issue("student@school.test"));
        db.run(
                "UPDATE student_school_mailboxes SET"
                        + " provisioning_status='ACTIVE',activated_at=CURRENT_TIMESTAMP WHERE"
                        + " student_id=?",
                student);
        var delivery = recovery.issue("student@school.test");
        recovery.deliver(delivery);
        db.run(
                "UPDATE password_reset_tokens SET expires_at=? WHERE id=?",
                java.time.LocalDateTime.now().minusMinutes(1),
                delivery.id());
        org.junit.jupiter.api.Assertions.assertThrows(
                org.springframework.web.server.ResponseStatusException.class,
                () -> recovery.reset(delivery.token(), "ChangedPassword123!"));
    }

    @Test
    void portraitUploadAndReadEnforceStudentScope() throws Exception {
        var image =
                new java.awt.image.BufferedImage(64, 64, java.awt.image.BufferedImage.TYPE_INT_RGB);
        var bytes = new java.io.ByteArrayOutputStream();
        javax.imageio.ImageIO.write(image, "png", bytes);
        var file =
                new org.springframework.mock.web.MockMultipartFile(
                        "file", "portrait.png", "image/png", bytes.toByteArray());
        mvc.perform(
                        multipart("/api/students/" + student + "/photo")
                                .file(file)
                                .with(user("student"))
                                .with(csrf()))
                .andExpect(status().isOk());
        mvc.perform(get("/api/students/" + student + "/photo").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/jpeg"));
        mvc.perform(get("/api/students/" + student + "/photo").with(user("other")))
                .andExpect(status().isNotFound());
        mvc.perform(
                        multipart("/api/students/" + otherStudent + "/photo")
                                .file(file)
                                .with(user("student"))
                                .with(csrf()))
                .andExpect(status().isNotFound());
    }

    @Test
    void anonymousCannotReadPrivateData() throws Exception {
        mvc.perform(get("/api/resources/users")).andExpect(status().isUnauthorized());
    }

    @Test
    void studentCannotReadUsersOrSelfGrantRoles() throws Exception {
        mvc.perform(get("/api/resources/users").with(user("student")))
                .andExpect(status().isForbidden());
        mvc.perform(
                        post("/api/users/" + studentUser + "/roles")
                                .with(user("student"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"roles\":[\"PRINCIPAL\"]}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void studentCannotReadAnotherStudentByChangingId() throws Exception {
        mvc.perform(get("/api/resources/students/" + otherStudent).with(user("student")))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/resources/students/" + student).with(user("student")))
                .andExpect(status().isOk());
    }

    @Test
    void writesRequireCsrf() throws Exception {
        mvc.perform(
                        post("/api/admissions/" + application + "/actions/SCHOOL_APPROVE")
                                .with(user("principal"))
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void bghApprovalDoesNotCreateStudentAndCannotEnroll() throws Exception {
        long before = db.number("SELECT COUNT(*) FROM students");
        mvc.perform(
                        post("/api/admissions/" + application + "/actions/SCHOOL_APPROVE")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isOk());
        org.junit.jupiter.api.Assertions.assertEquals(
                before, db.number("SELECT COUNT(*) FROM students"));
        mvc.perform(
                        post("/api/admissions/" + application + "/actions/ENROLL")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void ctsvCannotConfirmTheirOwnRemittanceAsWrongRole() throws Exception {
        mvc.perform(
                        post("/api/remittances/999/decision")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"approve\":true}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void applicantCannotReadAnotherDossier() throws Exception {
        mvc.perform(get("/api/admissions/" + application).with(user("student")))
                .andExpect(status().isForbidden());
    }

    @Test
    void disabledSessionIsRejected() throws Exception {
        db.run("UPDATE users SET enabled=FALSE WHERE id=?", studentUser);
        mvc.perform(get("/api/me").with(user("student"))).andExpect(status().isUnauthorized());
    }

    @Test
    void loginRejectsWrongPassword() throws Exception {
        mvc.perform(
                        post("/api/auth/login")
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"username\":\"student\",\"password\":\"incorrect\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void academicAndFinanceWorkflowRunsWithRoleBoundaries() throws Exception {
        var now = java.time.LocalDate.now();
        long year =
                db.insert(
                        "academic_years",
                        map(
                                "name",
                                "FLOW-YEAR",
                                "starts_on",
                                now.minusMonths(2),
                                "ends_on",
                                now.plusMonths(12)));
        long term =
                db.insert(
                        "semesters",
                        map(
                                "academic_year_id",
                                year,
                                "code",
                                "FLOW-TERM",
                                "starts_on",
                                now.minusMonths(1),
                                "ends_on",
                                now.plusMonths(3),
                                "registration_from",
                                now.minusDays(1).atStartOfDay(),
                                "registration_to",
                                now.plusDays(1).atStartOfDay(),
                                "status",
                                "OPEN"));
        long course =
                db.insert(
                        "courses",
                        map(
                                "course_code",
                                "FLOW101",
                                "title",
                                "Workflow Course",
                                "credits",
                                3,
                                "active",
                                true));
        long teacher = makeUser("teacherflow", "LECTURER"),
                faculty = db.number("SELECT MIN(id) FROM faculties");
        long lecturer =
                db.insert(
                        "lecturers",
                        map("user_id", teacher, "faculty_id", faculty, "lecturer_code", "GV-FLOW"));
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
                                "FLOW-01",
                                "capacity",
                                2,
                                "attendance_weight",
                                10,
                                "midterm_weight",
                                30,
                                "final_weight",
                                60,
                                "is_open",
                                true));
        db.insert("grade_sheets", map("section_id", section, "status", "DRAFT"));
        mvc.perform(
                        post("/api/sections/" + section + "/register")
                                .with(user("student"))
                                .with(csrf()))
                .andExpect(status().isOk());
        mvc.perform(
                        post("/api/sections/" + section + "/register")
                                .with(user("student"))
                                .with(csrf()))
                .andExpect(status().isConflict());
        long enrollment =
                db.number(
                        "SELECT id FROM enrollments WHERE student_id=? AND section_id=?",
                        student,
                        section);
        mvc.perform(
                        put("/api/enrollments/" + enrollment + "/grade")
                                .with(user("teacherflow"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"attendance_score\":8,\"midterm_score\":7,\"final_score\":9}"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/resources/grades").with(user("student")))
                .andExpect(jsonPath("$.total").value(0));
        for (String[] step :
                new String[][] {
                    {"SUBMIT", "teacherflow"},
                    {"VERIFY", "pdt"},
                    {"APPROVE", "principal"},
                    {"PUBLISH", "pdt"}
                })
            mvc.perform(
                            post("/api/sections/" + section + "/sheet/" + step[0])
                                    .with(user(step[1]))
                                    .with(csrf())
                                    .contentType("application/json")
                                    .content("{}"))
                    .andExpect(status().isOk());
        mvc.perform(get("/api/resources/grades").with(user("student")))
                .andExpect(jsonPath("$.items[0].total_score").value(8.3));
        db.insert("tuition_rates", map("semester_id", term, "price_per_credit", 100000));
        mvc.perform(
                        post("/api/invoices/issue")
                                .with(user("student"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"student_id\":"
                                                + student
                                                + ",\"semester_id\":"
                                                + term
                                                + "}"))
                .andExpect(status().isForbidden());
        long proposalForFlow = createProposal(student, term);
        proposalAction(proposalForFlow, "SUBMIT", "ctsv", "");
        proposalAction(proposalForFlow, "APPROVE", "principal", "");
        mvc.perform(
                        post("/api/invoices/issue")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"student_id\":"
                                                + student
                                                + ",\"semester_id\":"
                                                + term
                                                + "}"))
                .andExpect(status().isOk());
        long invoice =
                db.number(
                        "SELECT id FROM invoices WHERE student_id=? AND semester_id=?",
                        student,
                        term);
        long fund =
                db.insert(
                        "ctsv_funds",
                        map(
                                "code",
                                "FLOW-FUND",
                                "name",
                                "Flow fund",
                                "channel",
                                "CASH",
                                "active",
                                true));
        mvc.perform(
                        post("/api/payments")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"invoice_id\":"
                                                + invoice
                                                + ",\"fund_id\":"
                                                + fund
                                                + ",\"amount\":400000,\"reference_no\":\"FLOW-OVER\"}"))
                .andExpect(status().isConflict());
        mvc.perform(
                        post("/api/payments")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"invoice_id\":"
                                                + invoice
                                                + ",\"fund_id\":"
                                                + fund
                                                + ",\"amount\":100000,\"reference_no\":\"FLOW-PAID\"}"))
                .andExpect(status().isOk());
        long payment = db.number("SELECT id FROM payments WHERE reference_no='FLOW-PAID'");
        String allocation =
                "{\"fund_id\":"
                        + fund
                        + ",\"semester_id\":"
                        + term
                        + ",\"allocations\":[{\"payment_id\":"
                        + payment
                        + ",\"allocated_amount\":100000}]}";
        mvc.perform(
                        post("/api/remittances")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(allocation))
                .andExpect(status().isOk());
        mvc.perform(
                        post("/api/remittances")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(allocation))
                .andExpect(status().isConflict());
        long remittance = db.number("SELECT id FROM ctsv_remittances WHERE fund_id=?", fund);
        mvc.perform(
                        post("/api/remittances/" + remittance + "/decision")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"approve\":true}"))
                .andExpect(status().isOk());
        mvc.perform(
                        post("/api/reports")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"semester_id\":" + term + "}"))
                .andExpect(status().isConflict());
        db.run("UPDATE semesters SET ends_on=? WHERE id=?", now.minusDays(1), term);
        mvc.perform(
                        post("/api/reports")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"semester_id\":" + term + "}"))
                .andExpect(status().isOk());
    }

    @Test
    void sqlDatesAndTimesReachApiWithoutUtcDateShift() throws Exception {
        var today = java.time.LocalDate.of(2026, 11, 12);
        long year =
                db.insert(
                        "academic_years",
                        map(
                                "name",
                                "DATE-CHECK",
                                "starts_on",
                                today,
                                "ends_on",
                                today.plusYears(1)));
        mvc.perform(get("/api/lookups").with(user("principal")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.academic_years[0].starts_on").value("2026-11-12"))
                .andExpect(
                        jsonPath("$.admission_periods[0].opens_at").value("2020-01-01T00:00:00"));
        var time = db.one("SELECT CAST('07:30:00' AS TIME) starts_at");
        org.junit.jupiter.api.Assertions.assertEquals("07:30:00", time.get("starts_at"));
    }

    long academicSection(String code) {
        var now = java.time.LocalDate.now();
        long year =
                db.insert(
                        "academic_years",
                        map(
                                "name",
                                code,
                                "starts_on",
                                now.minusMonths(1),
                                "ends_on",
                                now.plusMonths(12)));
        long term =
                db.insert(
                        "semesters",
                        map(
                                "academic_year_id",
                                year,
                                "code",
                                code,
                                "starts_on",
                                now.minusMonths(1),
                                "ends_on",
                                now.plusMonths(3),
                                "status",
                                "OPEN",
                                "registration_from",
                                now.minusDays(1).atStartOfDay(),
                                "registration_to",
                                now.plusDays(1).atStartOfDay()));
        long course =
                db.insert(
                        "courses",
                        map("course_code", code, "title", code, "credits", 3, "active", true));
        long section =
                db.insert(
                        "course_sections",
                        map(
                                "semester_id",
                                term,
                                "course_id",
                                course,
                                "section_code",
                                code,
                                "capacity",
                                20,
                                "attendance_weight",
                                10,
                                "midterm_weight",
                                30,
                                "final_weight",
                                60,
                                "is_open",
                                true));
        db.insert("grade_sheets", map("section_id", section, "status", "DRAFT"));
        db.insert(
                "section_schedules",
                map(
                        "section_id",
                        section,
                        "day_of_week",
                        7,
                        "starts_at",
                        "07:30:00",
                        "ends_at",
                        "09:30:00",
                        "room",
                        "A101",
                        "room_id",
                        db.number("SELECT id FROM rooms WHERE code='A101'")));
        return section;
    }

    @Test
    void studentAcademicIncludesUnpublishedCoursesWithoutLeakingScores() throws Exception {
        long section = academicSection("PORTAL101");
        long enrolled =
                db.insert(
                        "enrollments",
                        map("student_id", student, "section_id", section, "status", "REGISTERED"));
        db.insert(
                "grades",
                map(
                        "enrollment_id",
                        enrolled,
                        "attendance_score",
                        9,
                        "midterm_score",
                        8,
                        "final_score",
                        7,
                        "remark",
                        "Internal review"));
        mvc.perform(get("/api/student/academic").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sections[0].schedules[0].day_of_week").value(7))
                .andExpect(jsonPath("$.enrollments[0].attendance_score").isEmpty())
                .andExpect(jsonPath("$.enrollments[0].remark").isEmpty())
                .andExpect(jsonPath("$.sections[0].cancel_reason").value(""));
        mvc.perform(get("/api/student/academic").with(user("other")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enrollments.length()").value(0));
        mvc.perform(post("/api/sections/" + section + "/cancel").with(user("student")).with(csrf()))
                .andExpect(status().isOk());
        mvc.perform(
                        post("/api/sections/" + section + "/register")
                                .with(user("student"))
                                .with(csrf()))
                .andExpect(status().isOk());
        db.run("UPDATE grade_sheets SET status='PUBLISHED' WHERE section_id=?", section);
        mvc.perform(get("/api/student/academic").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enrollments[0].attendance_score").value(9));
    }

    @Test
    void examsAreManagedByTrainingAndVisibleOnlyAfterPublicationForEnrolledStudents()
            throws Exception {
        long section = academicSection("EXAM101");
        mvc.perform(get("/api/exams/sections").with(user("student")))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/exams/sections").with(user("pdt")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].section_code").value("EXAM101"));
        db.insert(
                "enrollments",
                map("student_id", student, "section_id", section, "status", "REGISTERED"));
        String payload =
                "{\"section_id\":"
                        + section
                        + ",\"starts_at\":\"2027-01-20T08:00\",\"ends_at\":\"2027-01-20T10:00\",\"room\":\"A101\",\"exam_type\":\"Final\",\"status\":\"DRAFT\"}";
        mvc.perform(
                        post("/api/exams")
                                .with(user("student"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload))
                .andExpect(status().isForbidden());
        mvc.perform(
                        post("/api/exams")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload))
                .andExpect(status().isOk());
        long exam = db.number("SELECT id FROM exam_schedules WHERE section_id=?", section);
        mvc.perform(get("/api/exams").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
        mvc.perform(
                        put("/api/exams/" + exam)
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload.replace("DRAFT", "PUBLISHED")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/exams").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].section_code").value("EXAM101"));
        mvc.perform(get("/api/exams").with(user("other")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
        mvc.perform(
                        post("/api/exams")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload))
                .andExpect(status().isConflict());
        mvc.perform(
                        put("/api/exams/" + exam)
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload.replace("DRAFT", "CANCELLED")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/exams").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void normalizedCatalogsRejectUnknownReferencesAndPreserveLegacyClients() throws Exception {
        long section = academicSection("NORMAL101");
        long room = db.number("SELECT id FROM rooms WHERE code='A101'");
        long type = db.number("SELECT id FROM exam_types WHERE code='FINAL'");
        String schedule =
                "{\"day_of_week\":1,\"starts_at\":\"08:00\",\"ends_at\":\"10:00\",\"room_id\":"
                        + room
                        + "}";
        mvc.perform(
                        post("/api/sections/" + section + "/schedules")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(schedule))
                .andExpect(status().isOk());
        mvc.perform(
                        post("/api/sections/" + section + "/schedules")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(schedule.replace("08:00", "25:00")))
                .andExpect(status().isBadRequest());
        String exam =
                "{\"section_id\":"
                        + section
                        + ",\"starts_at\":\"2027-01-22T08:00\",\"ends_at\":\"2027-01-22T10:00\",\"room_id\":"
                        + room
                        + ",\"exam_type_id\":"
                        + type
                        + ",\"status\":\"PUBLISHED\"}";
        mvc.perform(
                        post("/api/exams")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(exam))
                .andExpect(status().isOk());
        mvc.perform(get("/api/exams").with(user("pdt")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].room_id").value(room))
                .andExpect(jsonPath("$[0].exam_type_id").value(type))
                .andExpect(jsonPath("$[0].room").value("A101"));
        mvc.perform(
                        post("/api/exams")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(exam.replace("\"room_id\":" + room, "\"room_id\":999999")))
                .andExpect(status().isBadRequest());
        mvc.perform(
                        post("/api/resources/rooms")
                                .with(user("student"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"code\":\"B101\",\"name\":\"Room B101\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(
                        put("/api/resources/rooms/" + room)
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"code\":\"A102\"}"))
                .andExpect(status().isOk());
        org.junit.jupiter.api.Assertions.assertEquals(
                "A102",
                db.one("SELECT room FROM section_schedules WHERE section_id=? LIMIT 1", section)
                        .get("room"));
        org.junit.jupiter.api.Assertions.assertEquals(
                "A102",
                db.one("SELECT room FROM exam_schedules WHERE section_id=?", section).get("room"));
    }

    @Test
    void cancellingExamStillWorksWhenCatalogWasDisabled() throws Exception {
        long section = academicSection("CANCEL101");
        long room = db.number("SELECT id FROM rooms WHERE code='A101'");
        long type = db.number("SELECT id FROM exam_types WHERE code='FINAL'");
        long exam =
                db.insert(
                        "exam_schedules",
                        map(
                                "section_id",
                                section,
                                "room_id",
                                room,
                                "exam_type_id",
                                type,
                                "room",
                                "A101",
                                "exam_type",
                                "Final",
                                "status",
                                "PUBLISHED",
                                "starts_at",
                                "2027-01-22 08:00:00",
                                "ends_at",
                                "2027-01-22 10:00:00"));
        db.run("UPDATE rooms SET active=FALSE WHERE id=?", room);
        db.run("UPDATE exam_types SET active=FALSE WHERE id=?", type);
        String payload =
                "{\"section_id\":"
                        + section
                        + ",\"starts_at\":\"2027-01-22T08:00\",\"ends_at\":\"2027-01-22T10:00\",\"room_id\":"
                        + room
                        + ",\"exam_type_id\":"
                        + type
                        + ",\"status\":\"CANCELLED\"}";
        mvc.perform(
                        put("/api/exams/" + exam)
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload))
                .andExpect(status().isOk());
        mvc.perform(
                        post("/api/exams")
                                .with(user("pdt"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload.replace("CANCELLED", "PUBLISHED")))
                .andExpect(status().isConflict());
    }

    @Test
    void activatingMailboxQueuesPersonalEmailOnlyOnceWithoutPassword() throws Exception {
        long mailbox =
                db.insert(
                        "student_school_mailboxes",
                        map(
                                "student_id",
                                student,
                                "school_email",
                                "student@school.test",
                                "provisioning_status",
                                "RESERVED"));
        String payload =
                "{\"school_email\":\"student@school.test\",\"provisioning_status\":\"ACTIVE\",\"mailbox_confirmed\":true,\"note\":\"Provider"
                    + " verified\"}";
        mvc.perform(
                        post("/api/mailboxes/" + mailbox + "/provision")
                                .with(user("student"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(payload))
                .andExpect(status().isForbidden());
        for (int attempt = 0; attempt < 2; attempt++)
            mvc.perform(
                            post("/api/mailboxes/" + mailbox + "/provision")
                                    .with(user("principal"))
                                    .with(csrf())
                                    .contentType("application/json")
                                    .content(payload))
                    .andExpect(status().isOk());
        org.junit.jupiter.api.Assertions.assertEquals(
                1, db.number("SELECT COUNT(*) FROM outbound_emails WHERE mailbox_id=?", mailbox));
        var queued = db.one("SELECT * FROM outbound_emails WHERE mailbox_id=?", mailbox);
        org.junit.jupiter.api.Assertions.assertEquals(
                "student@example.test", queued.get("recipient_email"));
        org.junit.jupiter.api.Assertions.assertEquals("QUEUED", queued.get("delivery_status"));
        org.junit.jupiter.api.Assertions.assertTrue(
                queued.get("body_text").toString().contains("student@school.test"));
        org.junit.jupiter.api.Assertions.assertFalse(
                queued.get("body_text").toString().contains("LongPassword123!"));
    }

    @Test
    void studentProfileRemainsOwnProfileWithAdditionalOfficeRole() throws Exception {
        db.run(
                "INSERT INTO user_roles(user_id,role_id) SELECT ?,id FROM roles WHERE"
                        + " code='PRINCIPAL'",
                studentUser);
        mvc.perform(get("/api/student/profile").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(student));
        mvc.perform(get("/api/student/academic").with(user("student")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile[0].id").value(student));
        mvc.perform(get("/api/student/profile").with(user("ctsv")))
                .andExpect(status().isForbidden());
    }

    long createProposal(long studentId, long term) throws Exception {
        mvc.perform(
                        post("/api/invoice-proposals")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(
                                        "{\"student_id\":"
                                                + studentId
                                                + ",\"semester_id\":"
                                                + term
                                                + ",\"discount_amount\":0}"))
                .andExpect(status().isOk());
        return db.number(
                "SELECT id FROM invoice_proposals WHERE student_id=? AND semester_id=?",
                studentId,
                term);
    }

    void proposalAction(long id, String action, String username, String note) throws Exception {
        mvc.perform(
                        post("/api/invoice-proposals/" + id + "/" + action)
                                .with(user(username))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"note\":\"" + note + "\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void invoiceMustBeReviewedAndIssueUsesApprovedSnapshot() throws Exception {
        long section = academicSection("APPROVAL101");
        long term = db.number("SELECT semester_id FROM course_sections WHERE id=?", section);
        db.insert("tuition_rates", map("semester_id", term, "price_per_credit", 100000));
        db.insert(
                "enrollments",
                map("student_id", student, "section_id", section, "status", "REGISTERED"));
        String issue = "{\"student_id\":" + student + ",\"semester_id\":" + term + "}";
        mvc.perform(
                        post("/api/invoices/issue")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(issue))
                .andExpect(status().isConflict());
        mvc.perform(
                        post("/api/invoice-proposals")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(issue))
                .andExpect(status().isForbidden());
        long proposal = createProposal(student, term);
        mvc.perform(get("/api/reviews/invoice_proposals").with(user("principal")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0));
        proposalAction(proposal, "SUBMIT", "ctsv", "");
        mvc.perform(get("/api/reviews/invoice_proposals").with(user("principal")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1));
        mvc.perform(get("/api/reviews/invoice_proposals").with(user("student")))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/sections/" + section + "/cancel").with(user("student")).with(csrf()))
                .andExpect(status().isConflict());
        proposalAction(proposal, "APPROVE", "principal", "");
        db.run("UPDATE tuition_rates SET price_per_credit=200000 WHERE semester_id=?", term);
        mvc.perform(
                        post("/api/invoices/issue")
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content(issue))
                .andExpect(status().isOk());
        long invoice =
                db.number(
                        "SELECT id FROM invoices WHERE student_id=? AND semester_id=?",
                        student,
                        term);
        org.junit.jupiter.api.Assertions.assertEquals(
                100000,
                db.number(
                        "SELECT unit_price_at_issue FROM invoice_items WHERE invoice_id=?",
                        invoice));
        org.junit.jupiter.api.Assertions.assertEquals(
                "ISSUED",
                db.one("SELECT status FROM invoice_proposals WHERE id=?", proposal).get("status"));
        mvc.perform(get("/api/reviews/invoice_proposals?view=history").with(user("principal")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1));
    }

    @Test
    void changedProposalPricesRequireReturnAndResubmission() throws Exception {
        long section = academicSection("REPRICE101");
        long term = db.number("SELECT semester_id FROM course_sections WHERE id=?", section);
        db.insert("tuition_rates", map("semester_id", term, "price_per_credit", 100000));
        db.insert(
                "enrollments",
                map("student_id", student, "section_id", section, "status", "REGISTERED"));
        long proposal = createProposal(student, term);
        proposalAction(proposal, "SUBMIT", "ctsv", "");
        db.run("UPDATE tuition_rates SET price_per_credit=120000 WHERE semester_id=?", term);
        mvc.perform(
                        post("/api/invoice-proposals/" + proposal + "/APPROVE")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isConflict());
        mvc.perform(
                        post("/api/invoice-proposals/" + proposal + "/RETURN")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isBadRequest());
        proposalAction(proposal, "RETURN", "principal", "Update tuition rate");
        mvc.perform(
                        put("/api/invoice-proposals/" + proposal)
                                .with(user("ctsv"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{\"discount_amount\":0}"))
                .andExpect(status().isOk());
        proposalAction(proposal, "SUBMIT", "ctsv", "");
        proposalAction(proposal, "APPROVE", "principal", "");
    }

    @Test
    void principalGradeQueueOnlyIncludesTrainingForwardedSheets() throws Exception {
        long section = academicSection("QUEUE101");
        mvc.perform(get("/api/reviews/grade_sheets").with(user("principal")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0));
        db.run("UPDATE grade_sheets SET status='VERIFIED' WHERE section_id=?", section);
        mvc.perform(
                        post("/api/sections/" + section + "/sheet/APPROVE")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isConflict());
        long sheet = db.number("SELECT id FROM grade_sheets WHERE section_id=?", section);
        db.insert(
                "grade_reviews", map("sheet_id", sheet, "actor_user_id", pdt, "action", "VERIFY"));
        mvc.perform(get("/api/reviews/grade_sheets").with(user("principal")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1));
        mvc.perform(
                        post("/api/sections/" + section + "/sheet/APPROVE")
                                .with(user("principal"))
                                .with(csrf())
                                .contentType("application/json")
                                .content("{}"))
                .andExpect(status().isOk());
    }
}
