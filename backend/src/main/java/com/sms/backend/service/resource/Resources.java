package com.sms.backend.service.resource;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;

import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Component
public class Resources {
    public record Spec(
            String table,
            String title,
            String select,
            String alias,
            String search,
            List<String> fields,
            Set<String> writers,
            Set<String> readers) {}

    private final Db db;
    private final Actor actor;
    public final Map<String, Spec> specs = new LinkedHashMap<>();

    private static Set<String> set(String names) {
        return Set.of(names.split(","));
    }

    public Resources(Db db, Actor actor) {
        this.db = db;
        this.actor = actor;
        add("rooms", "Phòng học / phòng thi", "code,name,capacity,active", "TRAINING_OFFICE");
        add("exam_types", "Loại kỳ thi", "code,name,active", "TRAINING_OFFICE");
        add("faculties", "Khoa", "code,name", "TRAINING_OFFICE");
        add("majors", "Ngành", "faculty_id,code,name", "TRAINING_OFFICE");
        add("cohorts", "Khóa tuyển sinh", "code,start_year,end_year", "TRAINING_OFFICE");
        add(
                "academic_classes",
                "Lớp hành chính",
                "major_id,cohort_id,code,name",
                "TRAINING_OFFICE");
        add("academic_years", "Năm học", "name,starts_on,ends_on", "TRAINING_OFFICE");
        add(
                "semesters",
                "Học kỳ",
                "academic_year_id,code,starts_on,ends_on,registration_from,registration_to,status",
                "TRAINING_OFFICE");
        add("courses", "Học phần", "course_code,title,credits,active", "TRAINING_OFFICE");
        add("curricula", "Chương trình đào tạo", "major_id,cohort_id,title", "TRAINING_OFFICE");
        add(
                "admission_periods",
                "Đợt nhập học",
                "code,title,cohort_id,opens_at,closes_at,status",
                "PRINCIPAL");
        add("tuition_rates", "Đơn giá học phí", "semester_id,price_per_credit", "CTSV");
        add("ctsv_funds", "Quỹ CTSV", "code,name,channel,active", "CTSV");
        define(
                "lecturers",
                "Giảng viên",
                "SELECT l.*,u.full_name,u.email FROM lecturers l JOIN users u ON u.id=l.user_id",
                "l",
                "u.full_name",
                List.of("user_id", "faculty_id", "lecturer_code"),
                "TRAINING_OFFICE",
                "PRINCIPAL,TRAINING_OFFICE");
        define(
                "sections",
                "Lớp học phần",
                "SELECT cs.*,c.course_code,c.title,c.credits,u.full_name lecturer_name,(SELECT"
                    + " COUNT(*) FROM enrollments e WHERE e.section_id=cs.id AND"
                    + " e.status<>'CANCELLED') registered FROM course_sections cs JOIN courses c ON"
                    + " c.id=cs.course_id LEFT JOIN lecturers l ON l.id=cs.lecturer_id LEFT JOIN"
                    + " users u ON u.id=l.user_id",
                "cs",
                "cs.section_code",
                List.of(
                        "semester_id",
                        "course_id",
                        "lecturer_id",
                        "section_code",
                        "capacity",
                        "attendance_weight",
                        "midterm_weight",
                        "final_weight",
                        "is_open"),
                "TRAINING_OFFICE",
                "APPLICANT,PRINCIPAL,TRAINING_OFFICE,LECTURER,STUDENT,CTSV");
        specs.put(
                "sections",
                new Spec(
                        "course_sections",
                        "Lớp học phần",
                        specs.get("sections").select(),
                        "cs",
                        "cs.section_code",
                        specs.get("sections").fields(),
                        set("TRAINING_OFFICE"),
                        specs.get("sections").readers()));
        define(
                "students",
                "Sinh viên",
                "SELECT s.*,u.full_name,u.email,ac.code class_code,m.name"
                    + " major_name,mb.school_email,mb.provisioning_status FROM students s JOIN"
                    + " users u ON u.id=s.user_id JOIN academic_classes ac ON ac.id=s.class_id JOIN"
                    + " majors m ON m.id=ac.major_id LEFT JOIN student_school_mailboxes mb ON"
                    + " mb.student_id=s.id",
                "s",
                "u.full_name",
                List.of(
                        "class_id",
                        "phone",
                        "address",
                        "status",
                        "date_of_birth",
                        "gender",
                        "place_of_birth",
                        "hometown",
                        "permanent_address",
                        "current_address",
                        "nationality",
                        "guardian_full_name",
                        "guardian_phone",
                        "enrolled_on"),
                "TRAINING_OFFICE",
                "STUDENT,LECTURER,TRAINING_OFFICE,PRINCIPAL,CTSV");
        define(
                "admissions",
                "Hồ sơ nhập học",
                "SELECT a.*,u.full_name applicant_name,m.name major_name FROM"
                        + " admission_applications a JOIN users u ON u.id=a.applicant_user_id JOIN"
                        + " majors m ON m.id=a.major_id",
                "a",
                "a.application_code",
                List.of(
                        "period_id",
                        "major_id",
                        "phone",
                        "address",
                        "date_of_birth",
                        "legal_full_name",
                        "personal_email",
                        "gender",
                        "place_of_birth",
                        "hometown",
                        "permanent_address",
                        "current_address",
                        "nationality",
                        "guardian_full_name",
                        "guardian_phone"),
                "APPLICANT",
                "APPLICANT,CTSV,PRINCIPAL,TRAINING_OFFICE");
        define(
                "enrollments",
                "Đăng ký học phần",
                "SELECT e.*,cs.section_code,cs.semester_id,c.title,c.credits,gs.status grade_status"
                        + " FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN"
                        + " courses c ON c.id=cs.course_id LEFT JOIN grade_sheets gs ON"
                        + " gs.section_id=cs.id",
                "e",
                "cs.section_code",
                List.of(),
                "",
                "STUDENT,LECTURER,TRAINING_OFFICE,PRINCIPAL,CTSV");
        define(
                "grades",
                "Điểm cá nhân",
                "SELECT"
                    + " g.*,e.student_id,e.section_id,s.student_code,u.full_name,cs.section_code,c.title,c.credits,gs.status"
                    + " sheet_status,ROUND((g.attendance_score*cs.attendance_weight+g.midterm_score*cs.midterm_weight+g.final_score*cs.final_weight)/100,2)"
                    + " total_score FROM grades g JOIN enrollments e ON e.id=g.enrollment_id JOIN"
                    + " students s ON s.id=e.student_id JOIN users u ON u.id=s.user_id JOIN"
                    + " course_sections cs ON cs.id=e.section_id JOIN courses c ON"
                    + " c.id=cs.course_id JOIN grade_sheets gs ON gs.section_id=cs.id",
                "g",
                "u.full_name",
                List.of(),
                "",
                "STUDENT,LECTURER,TRAINING_OFFICE,PRINCIPAL");
        define(
                "grade_sheets",
                "Bảng điểm",
                "SELECT gs.*,cs.section_code,cs.lecturer_id,c.title FROM grade_sheets gs JOIN"
                        + " course_sections cs ON cs.id=gs.section_id JOIN courses c ON"
                        + " c.id=cs.course_id",
                "gs",
                "cs.section_code",
                List.of(),
                "",
                "LECTURER,TRAINING_OFFICE,PRINCIPAL");
        define(
                "invoice_proposals",
                "Đề nghị học phí",
                "SELECT p.*,s.student_code,u.full_name,se.code semester_code,ay.name"
                    + " academic_year,prep.full_name prepared_name,COALESCE(x.gross_amount,0)"
                    + " gross_amount,COALESCE(x.gross_amount,0)-p.discount_amount payable_amount"
                    + " FROM invoice_proposals p JOIN students s ON s.id=p.student_id JOIN users u"
                    + " ON u.id=s.user_id JOIN semesters se ON se.id=p.semester_id JOIN"
                    + " academic_years ay ON ay.id=se.academic_year_id JOIN users prep ON"
                    + " prep.id=p.prepared_by LEFT JOIN (SELECT"
                    + " proposal_id,SUM(credits_at_proposal*unit_price_at_proposal) gross_amount"
                    + " FROM invoice_proposal_items GROUP BY proposal_id) x ON x.proposal_id=p.id",
                "p",
                "s.student_code",
                List.of(),
                "",
                "CTSV,PRINCIPAL,TRAINING_OFFICE");
        define(
                "invoices",
                "Hóa đơn học phí",
                "SELECT v.*,s.student_code FROM v_invoice_balances v JOIN students s ON"
                        + " s.id=v.student_id",
                "v",
                "s.student_code",
                List.of(),
                "",
                "STUDENT,CTSV,PRINCIPAL,TRAINING_OFFICE");
        define(
                "payments",
                "Khoản thu học phí",
                "SELECT p.*,i.student_id,i.semester_id,s.student_code FROM payments p JOIN invoices"
                        + " i ON i.id=p.invoice_id JOIN students s ON s.id=i.student_id",
                "p",
                "p.reference_no",
                List.of(),
                "",
                "STUDENT,CTSV,PRINCIPAL");
        define(
                "adjustments",
                "Điều chỉnh học phí",
                "SELECT t.* FROM tuition_adjustments t",
                "t",
                "t.adjustment_code",
                List.of(),
                "",
                "CTSV,PRINCIPAL");
        define(
                "remittances",
                "Bàn giao tiền",
                "SELECT r.* FROM ctsv_remittances r",
                "r",
                "r.remittance_code",
                List.of(),
                "",
                "CTSV,PRINCIPAL");
        define(
                "reports",
                "Báo cáo CTSV",
                "SELECT r.* FROM ctsv_semester_reports r",
                "r",
                "r.report_code",
                List.of(),
                "",
                "CTSV,PRINCIPAL");
        define(
                "requests",
                "Yêu cầu sinh viên",
                "SELECT r.*,s.student_code,u.full_name FROM student_requests r JOIN students s ON"
                        + " s.id=r.student_id JOIN users u ON u.id=s.user_id",
                "r",
                "r.request_code",
                List.of(),
                "",
                "STUDENT,CTSV,PRINCIPAL,TRAINING_OFFICE");
        define(
                "users",
                "Tài khoản",
                "SELECT u.id,u.username,u.email,u.full_name,u.enabled,u.created_at FROM users u",
                "u",
                "u.full_name",
                List.of("full_name", "email", "enabled"),
                "PRINCIPAL",
                "PRINCIPAL");
        define(
                "mailboxes",
                "Email trường",
                "SELECT m.*,s.student_code FROM student_school_mailboxes m JOIN students s ON"
                        + " s.id=m.student_id",
                "m",
                "m.school_email",
                List.of(),
                "",
                "STUDENT,TRAINING_OFFICE,PRINCIPAL");
        define(
                "emails",
                "Email thông báo",
                "SELECT e.* FROM outbound_emails e",
                "e",
                "e.recipient_email",
                List.of(),
                "",
                "CTSV,PRINCIPAL");
        define(
                "audit",
                "Nhật ký hệ thống",
                "SELECT a.* FROM audit_logs a",
                "a",
                "a.action",
                List.of(),
                "",
                "PRINCIPAL");
        define(
                "notifications",
                "Thông báo học vụ",
                "SELECT n.* FROM notifications n",
                "n",
                "n.title",
                List.of("title", "body"),
                "CTSV,PRINCIPAL,TRAINING_OFFICE",
                "STUDENT,LECTURER,CTSV,PRINCIPAL,TRAINING_OFFICE,APPLICANT");
    }

    private void add(String table, String title, String fields, String writers) {
        define(
                table,
                title,
                "SELECT t.* FROM " + table + " t",
                "t",
                Arrays.asList(fields.split(",")).contains("name")
                        ? "t.name"
                        : Arrays.asList(fields.split(",")).contains("title")
                                ? "t.title"
                                : Arrays.asList(fields.split(",")).contains("code")
                                        ? "t.code"
                                        : Arrays.asList(fields.split(",")).contains("course_code")
                                                ? "t.course_code"
                                                : "CAST(t.id AS CHAR)",
                List.of(fields.split(",")),
                writers,
                "APPLICANT,STUDENT,LECTURER,CTSV,PRINCIPAL,TRAINING_OFFICE");
    }

    private void define(
            String key,
            String title,
            String select,
            String alias,
            String search,
            List<String> fields,
            String writers,
            String readers) {
        specs.put(
                key,
                new Spec(
                        key,
                        title,
                        select,
                        alias,
                        search,
                        fields,
                        writers.isEmpty() ? Set.of() : set(writers),
                        set(readers)));
    }

    public Spec spec(String key, Actor.User user) {
        var spec = specs.get(key);
        if (spec == null) throw error(404, "Chức năng không tồn tại.");
        if (Collections.disjoint(spec.readers(), user.roles()))
            throw error(403, "Không có quyền đọc dữ liệu này.");
        return spec;
    }

    public String scope(String key, Actor.User u, List<Object> args) {
        boolean office = u.has("PRINCIPAL", "CTSV", "TRAINING_OFFICE");
        if (key.equals("admissions") && u.has("TRAINING_OFFICE") && !u.has("PRINCIPAL", "CTSV"))
            return "a.status IN ('SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')";
        if (key.equals("admissions") && !office) {
            args.add(u.id());
            return "a.applicant_user_id=?";
        }
        if (key.equals("requests") && u.has("TRAINING_OFFICE") && !u.has("CTSV", "PRINCIPAL")) {
            args.add(u.id());
            return "r.handled_by=?";
        }
        if (office) return "1=1";
        if (key.equals("notifications")) {
            args.add(u.id());
            return "EXISTS(SELECT 1 FROM notification_recipients r WHERE r.notification_id=n.id AND"
                    + " r.user_id=?)";
        }
        if (key.equals("students")) {
            if (u.has("LECTURER")) {
                args.add(u.lecturerId());
                return "EXISTS(SELECT 1 FROM enrollments e JOIN course_sections cs ON"
                        + " cs.id=e.section_id WHERE e.student_id=s.id AND e.status<>'CANCELLED'"
                        + " AND cs.lecturer_id=?)";
            }
            args.add(u.student());
            return "s.id=?";
        }
        if (Set.of("grades", "enrollments").contains(key)) {
            if (u.has("LECTURER")) {
                args.add(u.lecturerId());
                return "cs.lecturer_id=? AND e.status<>'CANCELLED'";
            }
            args.add(u.student());
            return "e.student_id=? AND e.status<>'CANCELLED'"
                    + (key.equals("grades") ? " AND gs.status='PUBLISHED'" : "");
        }
        if (key.equals("grade_sheets")) {
            args.add(u.lecturerId());
            return "cs.lecturer_id=?";
        }
        if (key.equals("sections") && u.has("LECTURER")) {
            args.add(u.lecturerId());
            return "cs.lecturer_id=?";
        }
        if (Set.of("invoices", "payments", "mailboxes", "requests").contains(key)) {
            args.add(u.student());
            return Map.of(
                            "invoices",
                            "v.student_id=?",
                            "payments",
                            "i.student_id=?",
                            "mailboxes",
                            "m.student_id=?",
                            "requests",
                            "r.student_id=?")
                    .get(key);
        }
        if (key.equals("posts")) return "p.status='PUBLISHED'";
        if (key.equals("exams")) {
            if (u.has("LECTURER")) {
                args.add(u.lecturerId());
                return "cs.lecturer_id=?";
            }
            args.add(u.student());
            return "EXISTS(SELECT 1 FROM enrollments e WHERE e.section_id=ex.section_id AND"
                    + " e.student_id=? AND e.status<>'CANCELLED')";
        }
        return "1=1";
    }

    public Map<String, Object> list(String key, int page, int size, String search) {
        return list(key, page, size, search, null);
    }

    public Map<String, Object> list(String key, int page, int size, String search, String review) {
        var u = actor.current();
        var s = spec(key, u);
        var args = new ArrayList<Object>();
        String where = scope(key, u, args);
        if (review != null) {
            u.require("PRINCIPAL");
            String states =
                    switch (key) {
                        case "grade_sheets" ->
                                review.equals("pending")
                                        ? "'VERIFIED'"
                                        : "'APPROVED','PUBLISHED','RETURNED'";
                        case "admissions" ->
                                review.equals("pending")
                                        ? "'SENT_TO_SCHOOL'"
                                        : "'SCHOOL_APPROVED','SCHOOL_REJECTED','PDT_VERIFIED','ENROLLED'";
                        case "invoice_proposals" ->
                                review.equals("pending")
                                        ? "'SUBMITTED'"
                                        : "'APPROVED','RETURNED','REJECTED','ISSUED'";
                        case "adjustments" ->
                                review.equals("pending") ? "'REQUESTED'" : "'APPROVED','REJECTED'";
                        case "remittances" ->
                                review.equals("pending") ? "'SUBMITTED'" : "'CONFIRMED','REJECTED'";
                        case "reports" ->
                                review.equals("pending") ? "'SUBMITTED'" : "'APPROVED','RETURNED'";
                        default -> throw error(404, "Không có hàng đợi xét duyệt này.");
                    };
            where += " AND " + s.alias() + ".status IN (" + states + ")";
            if (key.equals("invoice_proposals"))
                where +=
                        " AND EXISTS(SELECT 1 FROM invoice_proposal_reviews pr WHERE"
                                + " pr.proposal_id=p.id AND pr.action='SUBMIT')";
            if (key.equals("grade_sheets"))
                where +=
                        " AND EXISTS(SELECT 1 FROM grade_reviews gr JOIN user_roles ur ON"
                            + " ur.user_id=gr.actor_user_id JOIN roles r ON r.id=ur.role_id WHERE"
                            + " gr.sheet_id=gs.id AND gr.action='VERIFY' AND"
                            + " r.code='TRAINING_OFFICE')";
            if (key.equals("admissions"))
                where +=
                        " AND EXISTS(SELECT 1 FROM admission_review_events ev JOIN user_roles ur ON"
                            + " ur.user_id=ev.actor_user_id JOIN roles r ON r.id=ur.role_id WHERE"
                            + " ev.application_id=a.id AND ev.event_type='SUBMIT_TO_SCHOOL' AND"
                            + " r.code='CTSV')";
        }
        if (search != null && !search.isBlank()) {
            where += " AND " + s.search() + " LIKE ?";
            args.add("%" + search.substring(0, Math.min(150, search.length())) + "%");
        }
        int limit = Math.max(1, Math.min(size, 50)), current = Math.max(1, Math.min(page, 100000));
        String sql = s.select() + " WHERE " + where;
        long count = db.number("SELECT COUNT(*) FROM (" + sql + ") scoped", args.toArray());
        var paging = new ArrayList<>(args);
        paging.add(limit);
        paging.add((current - 1) * limit);
        var rows =
                db.rows(
                        sql
                                + " ORDER BY "
                                + s.alias()
                                + "."
                                + (key.equals("invoices") ? "invoice_id" : "id")
                                + " DESC LIMIT ? OFFSET ?",
                        paging.toArray());
        return map(
                "items",
                rows,
                "total",
                count,
                "page",
                current,
                "size",
                limit,
                "title",
                s.title(),
                "fields",
                s.fields(),
                "canWrite",
                !Collections.disjoint(s.writers(), u.roles()));
    }

    public Map<String, Object> accessible(String key, long id) {
        var u = actor.current();
        var s = spec(key, u);
        var args = new ArrayList<Object>();
        String where = scope(key, u, args);
        args.add(id);
        return db.one(
                s.select()
                        + " WHERE "
                        + where
                        + " AND "
                        + s.alias()
                        + "."
                        + (key.equals("invoices") ? "invoice_id" : "id")
                        + "=?",
                args.toArray());
    }

    @Transactional
    public long save(String key, Long id, Map<String, Object> input) {
        var u = actor.current();
        var s = spec(key, u);
        if (Collections.disjoint(s.writers(), u.roles()))
            throw error(403, "Không có quyền thay đổi dữ liệu.");
        var values = new LinkedHashMap<String, Object>();
        for (var field : input.keySet()) {
            if (!s.fields().contains(field))
                throw error(400, "Không được cập nhật trường " + field);
            Object value = input.get(field);
            if (value instanceof String str) {
                if (str.length() > 15000) throw error(400, "Nội dung quá dài.");
                value = str.isBlank() ? null : str.trim();
            }
            values.put(field, value);
        }
        if (key.equals("students") && id == null)
            throw error(409, "Tạo sinh viên qua luồng hồ sơ đã được BGH duyệt và PĐT cấp MSSV.");
        if (key.equals("admissions")) {
            if (id != null) {
                var old = accessible(key, id);
                if (Db.id(old.get("applicant_user_id")) != u.id())
                    throw error(403, "Không được sửa hồ sơ của người khác.");
                if (!Set.of("DRAFT", "CHANGES_REQUESTED").contains(old.get("status")))
                    throw error(409, "Chỉ sửa hồ sơ nháp hoặc cần bổ sung.");
            }
            long period =
                    id == null
                            ? Db.id(values.get("period_id"))
                            : Db.id(accessible(key, id).get("period_id"));
            if (db.number(
                            "SELECT COUNT(*) FROM admission_periods WHERE id=? AND status='OPEN'"
                                    + " AND opens_at<=CURRENT_TIMESTAMP AND"
                                    + " closes_at>=CURRENT_TIMESTAMP",
                            period)
                    != 1) throw error(409, "Đợt nhập học chưa mở hoặc đã đóng.");
            if (id == null) {
                values.put("applicant_user_id", u.id());
                values.put("application_code", "HS-" + UUID.randomUUID());
                values.put("status", "DRAFT");
            }
        }
        if (Set.of("rooms", "exam_types").contains(key)) {
            if (values.containsKey("code")) {
                String code =
                        text(values, "code", key.equals("rooms") ? 80 : 40)
                                .toUpperCase(Locale.ROOT);
                if (!code.matches("[A-Z0-9][A-Z0-9._-]*"))
                    throw error(
                            400, "Mã danh mục chỉ gồm chữ, số, dấu chấm, gạch ngang/gạch dưới.");
                values.put("code", code);
            }
            if (values.containsKey("name"))
                values.put("name", text(values, "name", key.equals("rooms") ? 160 : 80));
            if (values.get("capacity") != null && Db.id(values.get("capacity")) > 100000)
                throw error(400, "Sức chứa phòng không hợp lệ.");
        }
        if (key.equals("rooms")
                && id != null
                && values.get("capacity") != null
                && db.number(
                                "SELECT COUNT(*) FROM section_schedules ss JOIN course_sections cs"
                                        + " ON cs.id=ss.section_id WHERE ss.room_id=? AND"
                                        + " cs.capacity>?",
                                id,
                                Db.id(values.get("capacity")))
                        > 0)
            throw error(409, "Không giảm sức chứa dưới sĩ số tối đa của lớp đang dùng phòng.");
        if (key.equals("sections")) validateSection(id, values);
        if (key.equals("posts")) {
            values.put("created_by", u.id());
            if (!Set.of("DRAFT", "PUBLISHED")
                    .contains(String.valueOf(values.getOrDefault("status", "DRAFT"))))
                throw error(400, "Trạng thái bài không hợp lệ.");
        }
        if (key.equals("notifications")) {
            values.put("created_by", u.id());
            if (id == null) values.put("notification_code", "TB-" + UUID.randomUUID());
        }
        String table =
                key.equals("admissions")
                        ? "admission_applications"
                        : key.equals("posts")
                                ? "campus_posts"
                                : key.equals("exams") ? "exam_schedules" : s.table();
        if (id != null) {
            accessible(key, id);
            if (key.equals("users") && id == u.id() && Boolean.FALSE.equals(values.get("enabled")))
                throw error(409, "Không tự khóa tài khoản đang sử dụng.");
            db.update(table, id, values);
            if (key.equals("rooms") && values.containsKey("code")) {
                db.run(
                        "UPDATE section_schedules SET room=? WHERE room_id=?",
                        values.get("code"),
                        id);
                db.run("UPDATE exam_schedules SET room=? WHERE room_id=?", values.get("code"), id);
            }
            if (key.equals("exam_types") && values.containsKey("name"))
                db.run(
                        "UPDATE exam_schedules SET exam_type=? WHERE exam_type_id=?",
                        values.get("name"),
                        id);
        } else {
            id = db.insert(table, values);
            if (key.equals("sections"))
                db.insert("grade_sheets", map("section_id", id, "status", "DRAFT"));
        }
        actor.audit(u, "SAVE", table, id);
        return id;
    }

    private void validateSection(Long id, Map<String, Object> values) {
        if (id != null
                && values.get("capacity") != null
                && db.number(
                                "SELECT COUNT(*) FROM section_schedules ss JOIN rooms r ON"
                                    + " r.id=ss.room_id WHERE ss.section_id=? AND r.capacity IS NOT"
                                    + " NULL AND r.capacity<?",
                                id,
                                Db.id(values.get("capacity")))
                        > 0) throw error(409, "Sĩ số tối đa vượt sức chứa phòng học đã xếp.");
        if (id != null) {
            var old = db.one("SELECT * FROM course_sections WHERE id=? FOR UPDATE", id);
            if (db.number(
                                    "SELECT COUNT(*) FROM enrollments WHERE section_id=? AND"
                                            + " status<>'CANCELLED'",
                                    id)
                            > 0
                    && (values.containsKey("course_id")
                                    && !Objects.toString(values.get("course_id"))
                                            .equals(Objects.toString(old.get("course_id")))
                            || values.containsKey("semester_id")
                                    && !Objects.toString(values.get("semester_id"))
                                            .equals(Objects.toString(old.get("semester_id")))))
                throw error(409, "Không đổi học phần/học kỳ của lớp đã có đăng ký.");
        }
        if (id != null
                && values.containsKey("capacity")
                && db.number(
                                "SELECT COUNT(*) FROM enrollments WHERE section_id=? AND"
                                        + " status<>'CANCELLED'",
                                id)
                        > Long.parseLong(values.get("capacity").toString()))
            throw error(409, "Sĩ số nhỏ hơn số đã đăng ký.");
    }

    public Map<String, Object> metadata() {
        var u = actor.current();
        return map(
                "resources",
                specs.entrySet().stream()
                        .filter(
                                entry ->
                                        !Collections.disjoint(
                                                entry.getValue().readers(), u.roles()))
                        .map(
                                entry ->
                                        map(
                                                "key",
                                                entry.getKey(),
                                                "title",
                                                entry.getValue().title(),
                                                "fields",
                                                entry.getValue().fields(),
                                                "canWrite",
                                                !Collections.disjoint(
                                                        entry.getValue().writers(), u.roles())))
                        .toList());
    }
}
