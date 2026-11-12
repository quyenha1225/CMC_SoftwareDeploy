package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.academic.Academic;
import com.sms.backend.service.admission.Admissions;
import com.sms.backend.service.admission.Documents;
import com.sms.backend.service.admission.IdentityRecords;
import com.sms.backend.service.finance.FinanceService;
import com.sms.backend.service.resource.Resources;
import com.sms.backend.service.student.StudentPhotos;

import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;

@RestController
@RequestMapping("/api")
public class ApiController {
    private final Resources resources;
    private final Admissions admissions;
    private final Documents documents;
    private final Academic academic;
    private final FinanceService finance;
    private final IdentityRecords records;
    private final Db db;
    private final Actor actor;
    private final StudentPhotos photos;

    public ApiController(
            Resources resources,
            Admissions admissions,
            Documents documents,
            Academic academic,
            FinanceService finance,
            IdentityRecords records,
            Db db,
            Actor actor,
            StudentPhotos photos) {
        this.resources = resources;
        this.admissions = admissions;
        this.documents = documents;
        this.academic = academic;
        this.finance = finance;
        this.records = records;
        this.db = db;
        this.actor = actor;
        this.photos = photos;
    }

    @GetMapping("/admission-periods/{id}/requirements")
    List<Map<String, Object>> requirements(@PathVariable long id) {
        actor.current().require("PRINCIPAL", "CTSV", "TRAINING_OFFICE");
        return db.rows(
                "SELECT * FROM admission_document_requirements WHERE period_id=? ORDER BY"
                        + " document_type",
                id);
    }

    @PostMapping("/admission-periods/{id}/requirements")
    @Transactional
    void requirement(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var u = actor.current();
        u.require("PRINCIPAL");
        db.one("SELECT id FROM admission_periods WHERE id=? FOR UPDATE", id);
        String type = text(input, "document_type", 50), label = text(input, "label", 160);
        boolean required = Boolean.TRUE.equals(input.get("is_required"));
        if (db.number(
                        "SELECT COUNT(*) FROM admission_document_requirements WHERE period_id=? AND"
                                + " document_type=?",
                        id,
                        type)
                == 0)
            db.insert(
                    "admission_document_requirements",
                    map(
                            "period_id",
                            id,
                            "document_type",
                            type,
                            "label",
                            label,
                            "is_required",
                            required));
        else
            db.run(
                    "UPDATE admission_document_requirements SET label=?,is_required=? WHERE"
                            + " period_id=? AND document_type=?",
                    label,
                    required,
                    id,
                    type);
        actor.audit(u, "CONFIGURE_DOCUMENT_REQUIREMENT", "admission_periods", id);
    }

    @GetMapping("/emails/{id}/attempts")
    List<Map<String, Object>> attempts(@PathVariable long id) {
        resources.accessible("emails", id);
        return db.rows(
                "SELECT * FROM email_delivery_attempts WHERE outbound_email_id=? ORDER BY"
                        + " attempt_no",
                id);
    }

    @GetMapping("/reports/{id}/reviews")
    List<Map<String, Object>> reportReviews(@PathVariable long id) {
        resources.accessible("reports", id);
        return db.rows(
                "SELECT r.*,u.full_name FROM ctsv_semester_report_reviews r JOIN users u ON"
                        + " u.id=r.actor_user_id WHERE report_id=? ORDER BY r.id",
                id);
    }

    @GetMapping("/grade-sheets/{id}/reviews")
    List<Map<String, Object>> gradeReviews(@PathVariable long id) {
        resources.accessible("grade_sheets", id);
        return db.rows(
                "SELECT r.*,u.full_name FROM grade_reviews r JOIN users u ON u.id=r.actor_user_id"
                        + " WHERE sheet_id=? ORDER BY r.id",
                id);
    }

    @GetMapping("/notifications/{id}/recipients")
    List<Map<String, Object>> recipients(@PathVariable long id) {
        actor.current().require("CTSV", "PRINCIPAL", "TRAINING_OFFICE");
        resources.accessible("notifications", id);
        return db.rows(
                "SELECT r.*,u.full_name FROM notification_recipients r JOIN users u ON"
                        + " u.id=r.user_id WHERE notification_id=?",
                id);
    }

    @PostMapping("/students/{id}/photo")
    void uploadPhoto(@PathVariable long id, @RequestParam MultipartFile file)
            throws java.io.IOException {
        photos.upload(id, file);
    }

    @GetMapping("/students/{id}/photo")
    ResponseEntity<?> photo(@PathVariable long id) {
        var file = photos.photo(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(file.mime()))
                .header("Cache-Control", "no-store")
                .header("X-Content-Type-Options", "nosniff")
                .body(new FileSystemResource(file.path()));
    }

    @PostMapping("/mailboxes/{id}/provision")
    @Transactional
    void provision(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var user = actor.current();
        user.require("PRINCIPAL");
        var previous = db.one("SELECT * FROM student_school_mailboxes WHERE id=? FOR UPDATE", id);
        String status = text(input, "provisioning_status", 20), note = text(input, "note", 500);
        if (!Set.of("PROVISIONING", "ACTIVE", "FAILED", "DISABLED").contains(status))
            throw error(400, "Trạng thái hộp thư không hợp lệ.");
        if (status.equals("ACTIVE") && !Boolean.TRUE.equals(input.get("mailbox_confirmed")))
            throw error(400, "Phải xác nhận hộp thư đã được cấp và sử dụng được tại nhà cung cấp.");
        String email = text(input, "school_email", 190);
        if (!email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) throw error(400, "Email không hợp lệ.");
        boolean announce =
                status.equals("ACTIVE")
                        && (!"ACTIVE".equals(previous.get("provisioning_status"))
                                || !email.equals(previous.get("school_email")));
        Map<String, Object> recipient = null;
        if (announce) {
            recipient =
                    db.one(
                            "SELECT u.email,u.full_name FROM students s JOIN users u ON"
                                    + " u.id=s.user_id WHERE s.id=?",
                            previous.get("student_id"));
            if (!Objects.toString(recipient.get("email"), "")
                    .matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+"))
                throw error(
                        409,
                        "Cần email cá nhân hợp lệ trong hồ sơ để gửi thông báo cấp email trường.");
            if (email.equalsIgnoreCase(recipient.get("email").toString()))
                throw error(
                        409,
                        "Email nhận thông báo phải là email cá nhân, khác hộp thư trường mới cấp.");
        }
        db.run(
                "UPDATE student_school_mailboxes SET"
                    + " school_email=?,provisioning_status=?,provisioned_by=?,activated_at=?,note=?"
                    + " WHERE id=?",
                email,
                status,
                user.id(),
                status.equals("ACTIVE") ? java.time.LocalDateTime.now() : null,
                note,
                id);
        db.run(
                "UPDATE password_reset_tokens SET used_at=CURRENT_TIMESTAMP WHERE used_at IS NULL"
                        + " AND user_id IN (SELECT s.user_id FROM students s JOIN"
                        + " student_school_mailboxes m ON m.student_id=s.id WHERE m.id=?)",
                id);
        actor.audit(user, "PROVISION_MAILBOX", "student_school_mailboxes", id);
        if (announce)
            db.insert(
                    "outbound_emails",
                    map(
                            "event_key",
                            "MAILBOX-" + UUID.randomUUID(),
                            "mailbox_id",
                            id,
                            "template_code",
                            "SCHOOL_MAILBOX_READY",
                            "recipient_email",
                            recipient.get("email"),
                            "subject",
                            "Thông báo cấp email trường",
                            "delivery_status",
                            "QUEUED",
                            "body_text",
                            "Chào "
                                    + recipient.get("full_name")
                                    + ",\n\n"
                                    + "Nhà trường đã xác nhận hộp thư của bạn được cấp và sử dụng"
                                    + " được.\n"
                                    + "Email trường: "
                                    + email
                                    + "\n\n"
                                    + "Thông tin này cũng được lưu trong Hồ sơ cá nhân trên"
                                    + " EduPortal. Nếu cần hướng dẫn truy cập, liên hệ bộ phận hỗ"
                                    + " trợ của nhà trường. Không gửi mật khẩu qua email phản"
                                    + " hồi."));
    }

    @PostMapping("/emails/{id}/retry")
    @Transactional
    void retryEmail(@PathVariable long id) {
        var user = actor.current();
        user.require("CTSV", "PRINCIPAL");
        var row = db.one("SELECT * FROM outbound_emails WHERE id=? FOR UPDATE", id);
        Admissions.expect(row.get("delivery_status").toString(), "FAILED");
        if (((Number) row.get("attempt_count")).intValue() >= 10)
            throw error(409, "Đã đạt giới hạn 10 lần gửi; cần kiểm tra cấu hình gửi thư.");
        db.run("UPDATE outbound_emails SET delivery_status='QUEUED' WHERE id=?", id);
        actor.audit(user, "RETRY_EMAIL", "outbound_emails", id);
    }

    @PostMapping("/students/{id}/mailbox")
    @Transactional
    void reserveMailbox(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var user = actor.current();
        user.require("PRINCIPAL");
        db.one("SELECT id FROM students WHERE id=? FOR UPDATE", id);
        String email = text(input, "school_email", 190);
        if (!email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) throw error(400, "Email không hợp lệ.");
        if (db.number("SELECT COUNT(*) FROM student_school_mailboxes WHERE student_id=?", id) > 0)
            throw error(409, "Sinh viên đã có địa chỉ trường; cập nhật ở mục Email trường.");
        db.insert(
                "student_school_mailboxes",
                map(
                        "student_id",
                        id,
                        "school_email",
                        email,
                        "provisioning_status",
                        "RESERVED",
                        "provisioned_by",
                        user.id(),
                        "note",
                        "Đặt trước địa chỉ; chưa xác nhận hộp thư tại nhà cung cấp."));
        actor.audit(user, "RESERVE_MAILBOX", "students", id);
    }

    @GetMapping("/meta")
    Map<String, Object> meta() {
        return resources.metadata();
    }

    @PostMapping("/requests/{id}/attachments")
    void requestUpload(@PathVariable long id, @RequestParam MultipartFile file)
            throws java.io.IOException {
        documents.requestUpload(id, file);
    }

    @GetMapping("/request-attachments/{id}/download")
    ResponseEntity<?> requestDownload(@PathVariable long id) {
        var file = documents.requestDownload(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(file.mime()))
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(file.name(), java.nio.charset.StandardCharsets.UTF_8)
                                .build()
                                .toString())
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .body(new FileSystemResource(file.path()));
    }

    @GetMapping("/resources/{key}")
    Map<String, Object> list(
            @PathVariable String key,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "") String search) {
        return resources.list(key, page, size, search);
    }

    @GetMapping("/resources/{key}/{id}")
    Map<String, Object> item(@PathVariable String key, @PathVariable long id) {
        return resources.accessible(key, id);
    }

    @PostMapping("/resources/{key}")
    Map<String, Object> create(@PathVariable String key, @RequestBody Map<String, Object> input) {
        return map("id", resources.save(key, null, input));
    }

    @PutMapping("/resources/{key}/{id}")
    Map<String, Object> update(
            @PathVariable String key,
            @PathVariable long id,
            @RequestBody Map<String, Object> input) {
        return map("id", resources.save(key, id, input));
    }

    @GetMapping("/admissions/{id}")
    Map<String, Object> dossier(@PathVariable long id) {
        return admissions.detail(id);
    }

    @PostMapping("/admissions/{id}/actions/{action}")
    void admissionAction(
            @PathVariable long id,
            @PathVariable String action,
            @RequestBody Map<String, Object> input) {
        admissions.transition(id, action, input);
    }

    @PostMapping("/admissions/{id}/documents")
    void upload(@PathVariable long id, @RequestParam String type, @RequestParam MultipartFile file)
            throws java.io.IOException {
        documents.upload(id, type, file);
    }

    @PostMapping("/documents/{id}/verify")
    void verify(@PathVariable long id, @RequestBody Map<String, Object> input) {
        admissions.verifyDocument(
                id,
                Boolean.TRUE.equals(input.get("verified")),
                Objects.toString(input.get("reason"), ""));
    }

    @GetMapping("/documents/{id}/download")
    ResponseEntity<?> download(@PathVariable long id) {
        var file = documents.download(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(file.mime()))
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(file.name(), java.nio.charset.StandardCharsets.UTF_8)
                                .build()
                                .toString())
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .body(new FileSystemResource(file.path()));
    }

    @PutMapping("/admissions/{id}/identity")
    void identity(@PathVariable long id, @RequestBody Map<String, Object> input) {
        records.identity(id, input);
    }

    @PutMapping("/admissions/{id}/high-school")
    void school(@PathVariable long id, @RequestBody Map<String, Object> input) {
        records.school(id, input);
    }

    @PostMapping("/sections/{id}/register")
    void register(@PathVariable long id) {
        academic.register(id, false);
    }

    @PostMapping("/sections/{id}/cancel")
    void cancel(@PathVariable long id) {
        academic.register(id, true);
    }

    @GetMapping("/sections/{id}/roster")
    List<Map<String, Object>> roster(@PathVariable long id) {
        return academic.roster(id);
    }

    @GetMapping("/sections/{id}/schedules")
    List<Map<String, Object>> schedules(@PathVariable long id) {
        resources.accessible("sections", id);
        return db.rows(
                "SELECT * FROM section_schedules WHERE section_id=? ORDER BY day_of_week,starts_at",
                id);
    }

    @PostMapping("/sections/{id}/schedules")
    void schedule(@PathVariable long id, @RequestBody Map<String, Object> input) {
        academic.schedule(id, input);
    }

    @PutMapping("/enrollments/{id}/grade")
    void grade(@PathVariable long id, @RequestBody Map<String, Object> input) {
        academic.saveGrade(id, input);
    }

    @PostMapping("/sections/{id}/sheet/{action}")
    void sheet(
            @PathVariable long id,
            @PathVariable String action,
            @RequestBody Map<String, Object> input) {
        academic.sheet(id, action, Objects.toString(input.get("note"), ""));
    }

    @PostMapping("/invoices/issue")
    Map<String, Object> issue(@RequestBody Map<String, Object> input) {
        return map(
                "id",
                finance.issue(Db.id(input.get("student_id")), Db.id(input.get("semester_id"))));
    }

    @GetMapping("/invoices/{id}/items")
    List<Map<String, Object>> invoiceItems(@PathVariable long id) {
        resources.accessible("invoices", id);
        return db.rows(
                "SELECT it.*,cs.section_code,c.title FROM invoice_items it JOIN enrollments e ON"
                    + " e.id=it.enrollment_id JOIN course_sections cs ON cs.id=e.section_id JOIN"
                    + " courses c ON c.id=cs.course_id WHERE it.invoice_id=?",
                id);
    }

    @PostMapping("/payments")
    Map<String, Object> payment(@RequestBody Map<String, Object> input) {
        return map("id", finance.payment(input));
    }

    @PostMapping("/adjustments")
    Map<String, Object> adjustment(@RequestBody Map<String, Object> input) {
        return map("id", finance.adjustment(input));
    }

    @PostMapping("/adjustments/{id}/decision")
    void decideAdjustment(@PathVariable long id, @RequestBody Map<String, Object> input) {
        finance.decideAdjustment(id, Boolean.TRUE.equals(input.get("approve")));
    }

    @PostMapping("/remittances")
    Map<String, Object> remittance(@RequestBody Map<String, Object> input) {
        return map("id", finance.remittance(input));
    }

    @PostMapping("/remittances/{id}/decision")
    void decideRemittance(@PathVariable long id, @RequestBody Map<String, Object> input) {
        finance.decideRemittance(
                id,
                Boolean.TRUE.equals(input.get("approve")),
                Objects.toString(input.get("note"), ""));
    }

    @GetMapping("/remittances/{id}/allocations")
    List<Map<String, Object>> allocations(@PathVariable long id) {
        resources.accessible("remittances", id);
        return db.rows(
                "SELECT a.*,p.reference_no FROM ctsv_remittance_allocations a JOIN payments p ON"
                        + " p.id=a.payment_id WHERE a.remittance_id=?",
                id);
    }

    @PostMapping("/reports")
    Map<String, Object> report(@RequestBody Map<String, Object> input) {
        return map("id", finance.report(Db.id(input.get("semester_id"))));
    }

    @PostMapping("/reports/{id}/decision")
    void decideReport(@PathVariable long id, @RequestBody Map<String, Object> input) {
        finance.decideReport(
                id,
                Boolean.TRUE.equals(input.get("approve")),
                Objects.toString(input.get("note"), ""));
    }

    @GetMapping("/reports/{id}/summary")
    List<Map<String, Object>> summary(@PathVariable long id) {
        var report = resources.accessible("reports", id);
        return db.rows(
                "SELECT * FROM v_ctsv_semester_finance WHERE semester_id=?",
                report.get("semester_id"));
    }

    @GetMapping("/timetable")
    List<Map<String, Object>> timetable() {
        var u = actor.current();
        u.require("PRINCIPAL", "TRAINING_OFFICE", "LECTURER", "STUDENT");
        String sql =
                "SELECT ss.*,cs.semester_id,cs.section_code,c.course_code,c.title"
                    + " course_title,c.credits,u.full_name lecturer_name FROM section_schedules ss"
                    + " JOIN course_sections cs ON cs.id=ss.section_id JOIN courses c ON"
                    + " c.id=cs.course_id LEFT JOIN lecturers l ON l.id=cs.lecturer_id LEFT JOIN"
                    + " users u ON u.id=l.user_id WHERE ";
        String order = " ORDER BY cs.semester_id,ss.day_of_week,ss.starts_at";
        if (u.has("PRINCIPAL", "TRAINING_OFFICE")) return db.rows(sql + "1=1" + order);
        if (u.has("LECTURER")) return db.rows(sql + "cs.lecturer_id=?" + order, u.lecturerId());
        return db.rows(
                sql
                        + "EXISTS(SELECT 1 FROM enrollments e WHERE e.section_id=cs.id AND"
                        + " e.student_id=? AND e.status IN ('REGISTERED','COMPLETED'))"
                        + order,
                u.student());
    }

    @GetMapping("/lookups")
    Map<String, Object> lookups() {
        var u = actor.current();
        var result = new LinkedHashMap<String, Object>();
        for (String key :
                List.of(
                        "faculties",
                        "majors",
                        "cohorts",
                        "academic_classes",
                        "academic_years",
                        "semesters",
                        "courses",
                        "admission_periods",
                        "rooms",
                        "exam_types"))
            result.put(key, db.rows("SELECT * FROM " + key + " ORDER BY id"));
        if (u.has("PRINCIPAL", "CTSV", "TRAINING_OFFICE")) {
            result.put(
                    "students",
                    db.rows(
                            "SELECT s.id,s.student_code,u.full_name FROM students s JOIN users u ON"
                                    + " u.id=s.user_id"));
            result.put(
                    "lecturers",
                    db.rows(
                            "SELECT l.id,l.lecturer_code,u.full_name FROM lecturers l JOIN users u"
                                    + " ON u.id=l.user_id"));
            result.put("ctsv_funds", db.rows("SELECT * FROM ctsv_funds WHERE active=TRUE"));
        }
        if (u.has("PRINCIPAL"))
            result.put(
                    "users", db.rows("SELECT id,username,full_name FROM users WHERE enabled=TRUE"));
        else if (u.has("CTSV", "TRAINING_OFFICE"))
            result.put(
                    "users",
                    db.rows(
                            "SELECT DISTINCT u.id,u.full_name FROM users u JOIN user_roles ur ON"
                                    + " ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE"
                                    + " u.enabled=TRUE AND r.code IN"
                                    + " ('CTSV','TRAINING_OFFICE','LECTURER')"));
        result.put(
                "roles",
                u.has("PRINCIPAL") ? db.rows("SELECT id,code,description FROM roles") : List.of());
        return result;
    }

    @PostMapping("/users/{id}/roles")
    @Transactional
    void roles(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var u = actor.current();
        u.require("PRINCIPAL");
        if (id == u.id()) throw error(409, "Không tự thay đổi vai trò của tài khoản đang sử dụng.");
        db.one("SELECT id FROM users WHERE id=? FOR UPDATE", id);
        if (!(input.get("roles") instanceof List<?> roles) || roles.isEmpty())
            throw error(400, "Chọn ít nhất một vai trò.");
        var ids = new ArrayList<Long>();
        for (Object role : roles) {
            if (!Set.of("APPLICANT", "CTSV", "PRINCIPAL", "TRAINING_OFFICE", "LECTURER", "STUDENT")
                    .contains(role.toString())) throw error(400, "Vai trò không hợp lệ.");
            ids.add(db.number("SELECT id FROM roles WHERE code=?", role));
        }
        db.run("DELETE FROM user_roles WHERE user_id=?", id);
        for (long role : ids)
            db.run("INSERT INTO user_roles(user_id,role_id) VALUES(?,?)", id, role);
        actor.audit(u, "CHANGE_ROLES", "users", id);
    }

    @PostMapping("/requests")
    @Transactional
    Map<String, Object> request(@RequestBody Map<String, Object> input) {
        var u = actor.current();
        long student = u.student();
        String type = text(input, "request_type", 40);
        if (!Set.of(
                        "PROFILE_UPDATE",
                        "STUDY_STATUS",
                        "GRADE_QUESTION",
                        "TUITION_QUESTION",
                        "DOCUMENT_REQUEST",
                        "STUDENT_SUPPORT",
                        "COMPLAINT",
                        "OTHER")
                .contains(type)) throw error(400, "Loại yêu cầu không hợp lệ.");
        return map(
                "id",
                db.insert(
                        "student_requests",
                        map(
                                "request_code",
                                "REQ-" + UUID.randomUUID(),
                                "student_id",
                                student,
                                "request_type",
                                type,
                                "content",
                                text(input, "content", 15000),
                                "status",
                                "PENDING")));
    }

    @PostMapping("/requests/{id}/process")
    @Transactional
    void process(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var u = actor.current();
        u.require("CTSV", "TRAINING_OFFICE", "PRINCIPAL");
        var row = resources.accessible("requests", id);
        db.one("SELECT id FROM student_requests WHERE id=? FOR UPDATE", id);
        String action = text(input, "action", 40), note = text(input, "note", 700);
        String status = row.get("status").toString();
        Long handler = u.id();
        if (action.equals("ASSIGN")) {
            u.require("CTSV");
            handler = Db.id(input.get("handled_by"));
            if (db.number(
                            "SELECT COUNT(*) FROM user_roles ur JOIN roles r ON r.id=ur.role_id"
                                + " WHERE ur.user_id=? AND r.code IN ('CTSV','TRAINING_OFFICE')",
                            handler)
                    == 0) throw error(400, "Người nhận không thuộc CTSV/PĐT.");
            status = "PROCESSING";
        } else if (action.equals("RESOLVE")) {
            u.require("CTSV", "TRAINING_OFFICE");
            Admissions.expect(status, "PENDING", "PROCESSING");
            status = "RESOLVED";
        } else if (action.equals("REJECT")) {
            u.require("CTSV");
            Admissions.expect(status, "PENDING", "PROCESSING");
            status = "REJECTED";
        } else if (action.equals("REOPEN")) {
            u.require("CTSV");
            Admissions.expect(status, "RESOLVED", "REJECTED");
            status = "PROCESSING";
        } else if (!Set.of(
                        "ASK_MORE_INFO", "ESCALATE_TO_SCHOOL", "SCHOOL_FEEDBACK", "RETURN_TO_CTSV")
                .contains(action)) throw error(400, "Thao tác yêu cầu không hợp lệ.");
        if (Set.of("ESCALATE_TO_SCHOOL", "RETURN_TO_CTSV", "ASK_MORE_INFO").contains(action))
            u.require("CTSV");
        if (action.equals("SCHOOL_FEEDBACK")) u.require("PRINCIPAL");
        db.run(
                "UPDATE student_requests SET"
                    + " status=?,handled_by=?,response=?,handled_at=CURRENT_TIMESTAMP WHERE id=?",
                status,
                handler,
                note,
                id);
        db.insert(
                "student_request_review_events",
                map("request_id", id, "reviewer_user_id", u.id(), "action", action, "note", note));
        actor.audit(u, action, "student_requests", id);
    }
}
