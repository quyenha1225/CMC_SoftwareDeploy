package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.academic.AcademicCatalog;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/exams")
public class ExamController {
    private final Db db;
    private final Actor actor;
    private final AcademicCatalog catalog;

    public ExamController(Db db, Actor actor, AcademicCatalog catalog) {
        this.db = db;
        this.actor = actor;
        this.catalog = catalog;
    }

    @GetMapping("/sections")
    List<Map<String, Object>> sections() {
        actor.current().require("TRAINING_OFFICE");
        return db.rows(
                "SELECT cs.id,cs.section_code,c.title FROM course_sections cs JOIN courses c ON"
                        + " c.id=cs.course_id ORDER BY cs.section_code");
    }

    @GetMapping
    List<Map<String, Object>> list() {
        var user = actor.current();
        user.require("STUDENT", "LECTURER", "TRAINING_OFFICE", "PRINCIPAL");
        String sql =
                "SELECT ex.*,cs.section_code,cs.semester_id,c.title,c.credits,u.full_name"
                    + " lecturer_name FROM exam_schedules ex JOIN course_sections cs ON"
                    + " cs.id=ex.section_id JOIN courses c ON c.id=cs.course_id LEFT JOIN lecturers"
                    + " l ON l.id=cs.lecturer_id LEFT JOIN users u ON u.id=l.user_id WHERE ";
        if (user.has("TRAINING_OFFICE", "PRINCIPAL"))
            return db.rows(sql + "1=1 ORDER BY ex.starts_at");
        if (user.has("LECTURER"))
            return db.rows(
                    sql + "ex.status='PUBLISHED' AND cs.lecturer_id=? ORDER BY ex.starts_at",
                    user.lecturerId());
        return db.rows(
                sql
                        + "ex.status='PUBLISHED' AND EXISTS(SELECT 1 FROM enrollments e WHERE"
                        + " e.section_id=cs.id AND e.student_id=? AND e.status<>'CANCELLED') ORDER"
                        + " BY ex.starts_at",
                user.student());
    }

    @PostMapping
    @Transactional
    Map<String, Object> create(@RequestBody Map<String, Object> input) {
        return map("id", save(null, input));
    }

    @PutMapping("/{id}")
    @Transactional
    Map<String, Object> update(@PathVariable long id, @RequestBody Map<String, Object> input) {
        return map("id", save(id, input));
    }

    private long save(Long id, Map<String, Object> input) {
        var user = actor.current();
        user.require("TRAINING_OFFICE");
        if (id != null) db.one("SELECT id FROM exam_schedules WHERE id=? FOR UPDATE", id);
        long sectionId = Db.id(input.get("section_id"));
        // Lock the semester to serialize room/lecturer/student collision checks across sections.
        var section = db.one("SELECT * FROM course_sections WHERE id=?", sectionId);
        db.one("SELECT id FROM semesters WHERE id=? FOR UPDATE", section.get("semester_id"));
        LocalDateTime start, end;
        try {
            start = LocalDateTime.parse(text(input, "starts_at", 30).replace(' ', 'T'));
            end = LocalDateTime.parse(text(input, "ends_at", 30).replace(' ', 'T'));
        } catch (RuntimeException exception) {
            throw error(400, "Ngày giờ thi không hợp lệ.");
        }
        String status = text(input, "status", 20);
        var roomRecord = catalog.room(input, !status.equals("CANCELLED"));
        var typeRecord = catalog.examType(input, !status.equals("CANCELLED"));
        String room = roomRecord.get("code").toString(), type = typeRecord.get("name").toString();
        if (section.get("lecturer_id") != null)
            db.one("SELECT id FROM lecturers WHERE id=? FOR UPDATE", section.get("lecturer_id"));
        db.rows(
                "SELECT s.id FROM students s JOIN enrollments e ON e.student_id=s.id WHERE"
                        + " e.section_id=? AND e.status<>'CANCELLED' ORDER BY s.id FOR UPDATE",
                sectionId);
        if (!status.equals("CANCELLED")
                && roomRecord.get("capacity") != null
                && db.number(
                                "SELECT COUNT(*) FROM enrollments WHERE section_id=? AND"
                                        + " status<>'CANCELLED'",
                                sectionId)
                        > Db.id(roomRecord.get("capacity")))
            throw error(409, "Phòng thi không đủ chỗ cho sinh viên đã đăng ký.");
        if (!end.isAfter(start)
                || !start.toLocalDate().equals(end.toLocalDate())
                || !Set.of("DRAFT", "PUBLISHED", "CANCELLED").contains(status))
            throw error(400, "Kiểm tra thời gian thi trong ngày và trạng thái.");
        if (!status.equals("CANCELLED")
                && db.number(
                                "SELECT COUNT(*) FROM exam_schedules ex JOIN course_sections cs ON"
                                    + " cs.id=ex.section_id WHERE ex.id<>? AND"
                                    + " ex.status<>'CANCELLED' AND ex.starts_at<? AND ex.ends_at>?"
                                    + " AND (ex.room=? OR ex.section_id=? OR cs.lecturer_id=? OR"
                                    + " EXISTS(SELECT 1 FROM enrollments a JOIN enrollments b ON"
                                    + " b.student_id=a.student_id WHERE a.section_id=? AND"
                                    + " b.section_id=ex.section_id AND a.status<>'CANCELLED' AND"
                                    + " b.status<>'CANCELLED'))",
                                id == null ? 0 : id,
                                end,
                                start,
                                room,
                                sectionId,
                                section.get("lecturer_id"),
                                sectionId)
                        > 0) throw error(409, "Lịch thi trùng phòng, giảng viên hoặc sinh viên.");
        var values =
                map(
                        "section_id",
                        sectionId,
                        "starts_at",
                        start,
                        "ends_at",
                        end,
                        "room",
                        room,
                        "room_id",
                        roomRecord.get("id"),
                        "exam_type",
                        type,
                        "exam_type_id",
                        typeRecord.get("id"),
                        "status",
                        status,
                        "note",
                        Objects.toString(input.get("note"), ""));
        if (id == null) id = db.insert("exam_schedules", values);
        else db.update("exam_schedules", id, values);
        actor.audit(user, "SAVE_EXAM", "exam_schedules", id);
        return id;
    }
}
