package com.sms.backend.service.academic;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.admission.Admissions;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class Academic {
    private final Db db;
    private final Actor actor;
    private final AcademicCatalog catalog;

    public Academic(Db db, Actor actor, AcademicCatalog catalog) {
        this.db = db;
        this.actor = actor;
        this.catalog = catalog;
    }

    @Transactional
    public void register(long sectionId, boolean cancel) {
        registration(sectionId, cancel, true);
    }

    public String registrationReason(long sectionId, boolean cancel) {
        try {
            registration(sectionId, cancel, false);
            return "";
        } catch (org.springframework.web.server.ResponseStatusException exception) {
            return exception.getReason();
        }
    }

    private void registration(long sectionId, boolean cancel, boolean mutate) {
        var u = actor.current();
        long studentId = u.student();
        var student =
                db.one(
                        "SELECT * FROM students WHERE id=?" + (mutate ? " FOR UPDATE" : ""),
                        studentId);
        if (!"STUDYING".equals(student.get("status")))
            throw error(409, "Trạng thái sinh viên không cho phép đăng ký.");
        var section =
                db.one(
                        "SELECT * FROM course_sections WHERE id=?" + (mutate ? " FOR UPDATE" : ""),
                        sectionId);
        Object semester = section.get("semester_id");
        if (db.number(
                        "SELECT COUNT(*) FROM semesters WHERE id=? AND status='OPEN' AND"
                                + " registration_from<=CURRENT_TIMESTAMP AND"
                                + " registration_to>=CURRENT_TIMESTAMP",
                        semester)
                != 1) throw error(409, "Ngoài thời gian đăng ký học kỳ.");
        if (db.number(
                        "SELECT COUNT(*) FROM invoices WHERE student_id=? AND semester_id=?",
                        studentId,
                        semester)
                > 0)
            throw error(409, "Học kỳ đã phát hành hóa đơn. Vui lòng gửi yêu cầu điều chỉnh.");
        if (db.number(
                        "SELECT COUNT(*) FROM invoice_proposals WHERE student_id=? AND"
                                + " semester_id=? AND status IN ('SUBMITTED','APPROVED')",
                        studentId,
                        semester)
                > 0)
            throw error(
                    409,
                    "Học kỳ có đề nghị học phí đang trình/đã duyệt. Cần trả lại đề nghị trước khi"
                            + " đổi đăng ký.");
        var existing =
                db.rows(
                        "SELECT * FROM enrollments WHERE student_id=? AND section_id=?",
                        studentId,
                        sectionId);
        if (cancel) {
            if (existing.isEmpty() || !"REGISTERED".equals(existing.getFirst().get("status")))
                throw error(409, "Không có đăng ký được phép hủy.");
            if (db.number(
                            "SELECT COUNT(*) FROM grade_sheets WHERE section_id=? AND status NOT IN"
                                    + " ('DRAFT','RETURNED')",
                            sectionId)
                    > 0) throw error(409, "Bảng điểm đã gửi xét duyệt.");
            if (mutate)
                db.run(
                        "UPDATE enrollments SET status='CANCELLED' WHERE id=?",
                        existing.getFirst().get("id"));
        } else {
            if (!existing.isEmpty() && !"CANCELLED".equals(existing.getFirst().get("status")))
                throw error(409, "Bạn đã đăng ký lớp này.");
            if (!Boolean.parseBoolean(section.get("is_open").toString())
                    && !"1".equals(section.get("is_open").toString()))
                throw error(409, "Lớp chưa mở đăng ký.");
            if (db.number(
                            "SELECT COUNT(*) FROM section_schedules ss JOIN rooms r ON"
                                + " r.id=ss.room_id WHERE ss.section_id=? AND (r.active=FALSE OR"
                                + " (r.capacity IS NOT NULL AND r.capacity<=(SELECT COUNT(*) FROM"
                                + " enrollments e WHERE e.section_id=? AND"
                                + " e.status<>'CANCELLED')))",
                            sectionId,
                            sectionId)
                    > 0) throw error(409, "Phòng học đã ngừng sử dụng hoặc không còn đủ chỗ.");
            if (db.number(
                            "SELECT COUNT(*) FROM enrollments WHERE section_id=? AND"
                                    + " status<>'CANCELLED'",
                            sectionId)
                    >= Long.parseLong(section.get("capacity").toString()))
                throw error(409, "Lớp đã đủ sĩ số.");
            if (db.number(
                            "SELECT COUNT(*) FROM enrollments e JOIN course_sections cs ON"
                                + " cs.id=e.section_id WHERE e.student_id=? AND"
                                + " e.status<>'CANCELLED' AND cs.semester_id=? AND cs.course_id=?",
                            studentId,
                            semester,
                            section.get("course_id"))
                    > 0) throw error(409, "Đã đăng ký học phần này trong kỳ.");
            if (db.number(
                            "SELECT COUNT(*) FROM enrollments e JOIN course_sections cs ON"
                                + " cs.id=e.section_id JOIN section_schedules old ON"
                                + " old.section_id=cs.id JOIN section_schedules target ON"
                                + " target.section_id=? AND target.day_of_week=old.day_of_week AND"
                                + " target.starts_at<old.ends_at AND old.starts_at<target.ends_at"
                                + " WHERE e.student_id=? AND e.status<>'CANCELLED' AND"
                                + " cs.semester_id=?",
                            sectionId,
                            studentId,
                            semester)
                    > 0) throw error(409, "Lịch lớp bị trùng với lớp đã đăng ký.");
            long classId = Db.id(student.get("class_id"));
            if (db.number(
                                    "SELECT COUNT(*) FROM curricula c JOIN academic_classes ac ON"
                                            + " ac.major_id=c.major_id AND ac.cohort_id=c.cohort_id"
                                            + " WHERE ac.id=?",
                                    classId)
                            > 0
                    && db.number(
                                    "SELECT COUNT(*) FROM curriculum_courses cc JOIN curricula c ON"
                                            + " c.id=cc.curriculum_id JOIN academic_classes ac ON"
                                            + " ac.major_id=c.major_id AND ac.cohort_id=c.cohort_id"
                                            + " WHERE ac.id=? AND cc.course_id=?",
                                    classId,
                                    section.get("course_id"))
                            == 0)
                throw error(409, "Học phần không thuộc chương trình đào tạo của bạn.");
            if (!mutate) return;
            if (existing.isEmpty())
                db.insert(
                        "enrollments",
                        map(
                                "student_id",
                                studentId,
                                "section_id",
                                sectionId,
                                "status",
                                "REGISTERED"));
            else
                db.run(
                        "UPDATE enrollments SET status='REGISTERED',registered_at=CURRENT_TIMESTAMP"
                                + " WHERE id=?",
                        existing.getFirst().get("id"));
        }
        if (mutate)
            actor.audit(u, cancel ? "CANCEL_ENROLLMENT" : "REGISTER", "course_sections", sectionId);
    }

    public List<Map<String, Object>> roster(long sectionId) {
        var u = actor.current();
        u.require("LECTURER", "TRAINING_OFFICE", "PRINCIPAL");
        var section = db.one("SELECT * FROM course_sections WHERE id=?", sectionId);
        if (!u.has("TRAINING_OFFICE", "PRINCIPAL")
                && !Objects.equals(
                        u.lecturerId(),
                        section.get("lecturer_id") == null
                                ? null
                                : Db.id(section.get("lecturer_id"))))
            throw error(403, "Lớp không được phân công cho bạn.");
        return db.rows(
                "SELECT e.id"
                    + " enrollment_id,s.student_code,u.full_name,g.attendance_score,g.midterm_score,g.final_score,g.remark,cs.attendance_weight,cs.midterm_weight,cs.final_weight,ROUND((g.attendance_score*cs.attendance_weight+g.midterm_score*cs.midterm_weight+g.final_score*cs.final_weight)/100,2)"
                    + " total_score FROM enrollments e JOIN students s ON s.id=e.student_id JOIN"
                    + " users u ON u.id=s.user_id LEFT JOIN grades g ON g.enrollment_id=e.id JOIN"
                    + " course_sections cs ON cs.id=e.section_id WHERE e.section_id=? AND"
                    + " e.status<>'CANCELLED' ORDER BY s.student_code",
                sectionId);
    }

    @Transactional
    public void saveGrade(long enrollmentId, Map<String, Object> input) {
        var u = actor.current();
        u.require("LECTURER");
        var enrollment =
                db.one(
                        "SELECT e.*,cs.lecturer_id FROM enrollments e JOIN course_sections cs ON"
                                + " cs.id=e.section_id WHERE e.id=? FOR UPDATE",
                        enrollmentId);
        if (!Objects.equals(
                u.lecturerId(),
                enrollment.get("lecturer_id") == null
                        ? null
                        : Db.id(enrollment.get("lecturer_id"))))
            throw error(403, "Lớp không được phân công cho bạn.");
        if ("CANCELLED".equals(enrollment.get("status"))) throw error(409, "Đăng ký đã hủy.");
        var sheets =
                db.rows(
                        "SELECT * FROM grade_sheets WHERE section_id=? FOR UPDATE",
                        enrollment.get("section_id"));
        if (!sheets.isEmpty())
            Admissions.expect(sheets.getFirst().get("status").toString(), "DRAFT", "RETURNED");
        var values = new LinkedHashMap<String, Object>();
        for (String key : List.of("attendance_score", "midterm_score", "final_score")) {
            Object value = input.get(key);
            if (value != null && !value.toString().isBlank()) {
                double n = Double.parseDouble(value.toString());
                if (!Double.isFinite(n) || n < 0 || n > 10) throw error(400, "Điểm từ 0 đến 10.");
                values.put(key, n);
            } else values.put(key, null);
        }
        values.put("remark", Objects.toString(input.get("remark"), ""));
        var old = db.rows("SELECT id FROM grades WHERE enrollment_id=?", enrollmentId);
        if (old.isEmpty()) {
            values.put("enrollment_id", enrollmentId);
            db.insert("grades", values);
        } else db.update("grades", Db.id(old.getFirst().get("id")), values);
        actor.audit(u, "SAVE_GRADE", "enrollments", enrollmentId);
    }

    @Transactional
    public void sheet(long sectionId, String action, String note) {
        var u = actor.current();
        var section = db.one("SELECT * FROM course_sections WHERE id=? FOR UPDATE", sectionId);
        var sheets = db.rows("SELECT * FROM grade_sheets WHERE section_id=? FOR UPDATE", sectionId);
        long sheet =
                sheets.isEmpty()
                        ? db.insert("grade_sheets", map("section_id", sectionId, "status", "DRAFT"))
                        : Db.id(sheets.getFirst().get("id"));
        String from = sheets.isEmpty() ? "DRAFT" : sheets.getFirst().get("status").toString();
        String to;
        switch (action) {
            case "SUBMIT" -> {
                u.require("LECTURER");
                if (!Objects.equals(
                        u.lecturerId(),
                        section.get("lecturer_id") == null
                                ? null
                                : Db.id(section.get("lecturer_id"))))
                    throw error(403, "Lớp không được phân công.");
                Admissions.expect(from, "DRAFT", "RETURNED");
                if (db.number(
                                        "SELECT COUNT(*) FROM enrollments WHERE section_id=? AND"
                                                + " status<>'CANCELLED'",
                                        sectionId)
                                == 0
                        || db.number(
                                        "SELECT COUNT(*) FROM enrollments e LEFT JOIN grades g ON"
                                            + " g.enrollment_id=e.id WHERE e.section_id=? AND"
                                            + " e.status<>'CANCELLED' AND (g.attendance_score IS"
                                            + " NULL OR g.midterm_score IS NULL OR g.final_score IS"
                                            + " NULL)",
                                        sectionId)
                                > 0) throw error(409, "Cần đủ điểm cho danh sách đăng ký.");
                to = "SUBMITTED";
            }
            case "VERIFY" -> {
                u.require("TRAINING_OFFICE");
                Admissions.expect(from, "SUBMITTED");
                to = "VERIFIED";
            }
            case "APPROVE" -> {
                u.require("PRINCIPAL");
                Admissions.expect(from, "VERIFIED");
                if (db.number(
                                "SELECT COUNT(*) FROM grade_reviews gr JOIN user_roles ur ON"
                                    + " ur.user_id=gr.actor_user_id JOIN roles r ON r.id=ur.role_id"
                                    + " WHERE gr.sheet_id=? AND gr.action='VERIFY' AND"
                                    + " r.code='TRAINING_OFFICE'",
                                sheet)
                        == 0) throw error(409, "Bảng điểm chưa được PĐT kiểm tra và trình BGH.");
                if (db.number(
                                "SELECT COUNT(*) FROM lecturers WHERE id=? AND user_id=?",
                                section.get("lecturer_id"),
                                u.id())
                        > 0)
                    throw error(409, "Không tự xét duyệt bảng điểm của lớp mình giảng dạy.");
                to = "APPROVED";
            }
            case "PUBLISH" -> {
                u.require("TRAINING_OFFICE");
                Admissions.expect(from, "APPROVED");
                to = "PUBLISHED";
                db.run("UPDATE grade_sheets SET published_at=CURRENT_TIMESTAMP WHERE id=?", sheet);
            }
            case "RETURN" -> {
                if (from.equals("SUBMITTED")) u.require("TRAINING_OFFICE");
                else {
                    u.require("PRINCIPAL");
                    Admissions.expect(from, "VERIFIED");
                }
                if (note == null || note.isBlank()) throw error(400, "Nhập lý do trả lại.");
                to = "RETURNED";
            }
            default -> throw error(400, "Thao tác bảng điểm không hợp lệ.");
        }
        db.run("UPDATE grade_sheets SET status=?,version_no=version_no+1 WHERE id=?", to, sheet);
        db.insert(
                "grade_reviews",
                map("sheet_id", sheet, "actor_user_id", u.id(), "action", action, "note", note));
        actor.audit(u, action, "grade_sheets", sheet);
    }

    @Transactional
    public void schedule(long sectionId, Map<String, Object> input) {
        var u = actor.current();
        u.require("TRAINING_OFFICE");
        var section = db.one("SELECT * FROM course_sections WHERE id=? FOR UPDATE", sectionId);
        long day = Db.id(input.get("day_of_week"));
        String start = text(input, "starts_at", 8), end = text(input, "ends_at", 8);
        try {
            if (!java.time.LocalTime.parse(end).isAfter(java.time.LocalTime.parse(start)))
                throw error(400, "Giờ kết thúc phải sau giờ bắt đầu.");
        } catch (java.time.format.DateTimeParseException exception) {
            throw error(400, "Giờ học không hợp lệ.");
        }
        var roomRecord = catalog.room(input);
        String room = roomRecord.get("code").toString();
        if (roomRecord.get("capacity") != null
                && Db.id(section.get("capacity")) > Db.id(roomRecord.get("capacity")))
            throw error(409, "Sức chứa phòng nhỏ hơn sĩ số tối đa của lớp.");
        if (day > 7
                || !start.matches("\\d{2}:\\d{2}(:\\d{2})?")
                || !end.matches("\\d{2}:\\d{2}(:\\d{2})?")
                || start.compareTo(end) >= 0) throw error(400, "Kiểm tra thứ và khung giờ.");
        if (db.number(
                        "SELECT COUNT(*) FROM section_schedules ss JOIN course_sections cs ON"
                            + " cs.id=ss.section_id WHERE cs.semester_id=? AND ss.day_of_week=? AND"
                            + " ss.starts_at<? AND ss.ends_at>? AND (ss.room=? OR"
                            + " cs.lecturer_id=?)",
                        section.get("semester_id"),
                        day,
                        end,
                        start,
                        room,
                        section.get("lecturer_id"))
                > 0) throw error(409, "Trùng phòng hoặc giảng viên.");
        db.insert(
                "section_schedules",
                map(
                        "section_id",
                        sectionId,
                        "day_of_week",
                        day,
                        "starts_at",
                        start,
                        "ends_at",
                        end,
                        "room",
                        room,
                        "room_id",
                        roomRecord.get("id")));
        actor.audit(u, "ADD_SCHEDULE", "course_sections", sectionId);
    }
}
