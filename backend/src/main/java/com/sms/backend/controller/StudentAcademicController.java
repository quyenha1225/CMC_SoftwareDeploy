package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.academic.Academic;
import com.sms.backend.service.resource.Resources;

import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class StudentAcademicController {
    private final Db db;
    private final Actor actor;
    private final Academic academic;
    private final Resources resources;

    public StudentAcademicController(Db db, Actor actor, Academic academic, Resources resources) {
        this.db = db;
        this.actor = actor;
        this.academic = academic;
        this.resources = resources;
    }

    @GetMapping("/student/academic")
    Map<String, Object> studentAcademic() {
        var user = actor.current();
        user.require("STUDENT");
        long student = user.student();
        var sections =
                db.rows(
                        "SELECT cs.*,c.course_code,c.title,c.credits,u.full_name"
                            + " lecturer_name,s.code"
                            + " semester_code,s.starts_on,s.ends_on,s.registration_from,s.registration_to,s.status"
                            + " semester_status,ay.name academic_year,(SELECT COUNT(*) FROM"
                            + " enrollments e WHERE e.section_id=cs.id AND e.status<>'CANCELLED')"
                            + " registered FROM course_sections cs JOIN courses c ON"
                            + " c.id=cs.course_id JOIN semesters s ON s.id=cs.semester_id JOIN"
                            + " academic_years ay ON ay.id=s.academic_year_id LEFT JOIN lecturers l"
                            + " ON l.id=cs.lecturer_id LEFT JOIN users u ON u.id=l.user_id ORDER BY"
                            + " cs.id");
        for (var section : sections) {
            long id = Db.id(section.get("id"));
            section.put("schedules", schedules(id));
            section.put("register_reason", academic.registrationReason(id, false));
            section.put("cancel_reason", academic.registrationReason(id, true));
        }
        var enrollments =
                db.rows(
                        "SELECT e.*,gs.status sheet_status,g.remark,CASE WHEN gs.status='PUBLISHED'"
                            + " THEN g.attendance_score END attendance_score,CASE WHEN"
                            + " gs.status='PUBLISHED' THEN g.midterm_score END midterm_score,CASE"
                            + " WHEN gs.status='PUBLISHED' THEN g.final_score END final_score,CASE"
                            + " WHEN gs.status='PUBLISHED' THEN"
                            + " ROUND((g.attendance_score*cs.attendance_weight+g.midterm_score*cs.midterm_weight+g.final_score*cs.final_weight)/100,2)"
                            + " END total_score FROM enrollments e JOIN course_sections cs ON"
                            + " cs.id=e.section_id LEFT JOIN grade_sheets gs ON gs.section_id=cs.id"
                            + " LEFT JOIN grades g ON g.enrollment_id=e.id WHERE e.student_id=?"
                            + " ORDER BY e.id",
                        student);
        // Unpublished remarks may contain internal review notes as well as scores.
        enrollments.forEach(
                row -> {
                    if (!"PUBLISHED".equals(row.get("sheet_status"))) row.put("remark", null);
                });
        return map(
                "sections",
                sections,
                "enrollments",
                enrollments,
                "profile",
                List.of(resources.accessible("students", student)));
    }

    @GetMapping("/student/profile")
    Map<String, Object> studentProfile() {
        var user = actor.current();
        user.require("STUDENT");
        return resources.accessible("students", user.student());
    }

    @GetMapping("/sections/{id}/detail")
    Map<String, Object> section(@PathVariable long id) {
        var section = resources.accessible("sections", id);
        section.put("schedules", schedules(id));
        section.put(
                "semester",
                db.one(
                        "SELECT s.*,ay.name academic_year FROM semesters s JOIN academic_years ay"
                                + " ON ay.id=s.academic_year_id WHERE s.id=?",
                        section.get("semester_id")));
        return section;
    }

    private List<Map<String, Object>> schedules(long id) {
        return db.rows(
                "SELECT * FROM section_schedules WHERE section_id=? ORDER BY day_of_week,starts_at",
                id);
    }
}
