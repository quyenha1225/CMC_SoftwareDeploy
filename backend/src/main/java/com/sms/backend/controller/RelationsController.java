package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.resource.Resources;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class RelationsController {
    private final Db db;
    private final Actor actor;
    private final Resources resources;

    public RelationsController(Db db, Actor actor, Resources resources) {
        this.db = db;
        this.actor = actor;
        this.resources = resources;
    }

    @GetMapping("/curricula/{id}/courses")
    List<Map<String, Object>> courses(@PathVariable long id) {
        resources.accessible("curricula", id);
        return db.rows(
                "SELECT cc.*,c.course_code,c.title,c.credits FROM curriculum_courses cc JOIN"
                        + " courses c ON c.id=cc.course_id WHERE cc.curriculum_id=? ORDER BY"
                        + " cc.suggested_semester,c.course_code",
                id);
    }

    @PostMapping("/curricula/{id}/courses")
    @Transactional
    void course(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var u = actor.current();
        u.require("TRAINING_OFFICE");
        db.one("SELECT id FROM curricula WHERE id=? FOR UPDATE", id);
        long course = Db.id(input.get("course_id"));
        db.one("SELECT id FROM courses WHERE id=?", course);
        var values =
                map(
                        "suggested_semester",
                        input.get("suggested_semester"),
                        "required_course",
                        !Boolean.FALSE.equals(input.get("required_course")));
        if (db.number(
                        "SELECT COUNT(*) FROM curriculum_courses WHERE curriculum_id=? AND"
                                + " course_id=?",
                        id,
                        course)
                > 0)
            db.run(
                    "UPDATE curriculum_courses SET suggested_semester=?,required_course=? WHERE"
                            + " curriculum_id=? AND course_id=?",
                    values.get("suggested_semester"),
                    values.get("required_course"),
                    id,
                    course);
        else
            db.run(
                    "INSERT INTO"
                        + " curriculum_courses(curriculum_id,course_id,suggested_semester,required_course)"
                        + " VALUES(?,?,?,?)",
                    id,
                    course,
                    values.get("suggested_semester"),
                    values.get("required_course"));
        actor.audit(u, "SET_CURRICULUM_COURSE", "curricula", id);
    }

    @GetMapping("/notifications/{id}")
    Map<String, Object> notification(@PathVariable long id) {
        return resources.accessible("notifications", id);
    }

    @PostMapping("/notifications/{id}/read")
    void read(@PathVariable long id) {
        var u = actor.current();
        resources.accessible("notifications", id);
        db.run(
                "UPDATE notification_recipients SET read_at=CURRENT_TIMESTAMP WHERE"
                        + " notification_id=? AND user_id=? AND read_at IS NULL",
                id,
                u.id());
    }

    @PostMapping("/notifications/{id}/deliver")
    @Transactional
    void deliver(@PathVariable long id, @RequestBody Map<String, Object> input) {
        var u = actor.current();
        u.require("CTSV", "PRINCIPAL", "TRAINING_OFFICE");
        resources.accessible("notifications", id);
        db.one("SELECT id FROM notifications WHERE id=? FOR UPDATE", id);
        String role = text(input, "role", 40);
        if (!Set.of("APPLICANT", "STUDENT", "LECTURER", "CTSV", "PRINCIPAL", "TRAINING_OFFICE")
                .contains(role)) throw error(400, "Vai trò không hợp lệ.");
        db.run(
                "INSERT INTO notification_recipients(notification_id,user_id) SELECT ?,ur.user_id"
                    + " FROM user_roles ur JOIN roles r ON r.id=ur.role_id JOIN users u ON"
                    + " u.id=ur.user_id WHERE r.code=? AND u.enabled=TRUE AND NOT EXISTS(SELECT 1"
                    + " FROM notification_recipients nr WHERE nr.notification_id=? AND"
                    + " nr.user_id=ur.user_id)",
                id,
                role,
                id);
        actor.audit(u, "DELIVER_NOTIFICATION", "notifications", id);
    }

    @GetMapping("/requests/{id}/detail")
    Map<String, Object> request(@PathVariable long id) {
        var row = resources.accessible("requests", id);
        return map(
                "request",
                row,
                "events",
                db.rows(
                        "SELECT e.*,u.full_name FROM student_request_review_events e JOIN users u"
                                + " ON u.id=e.reviewer_user_id WHERE e.request_id=? ORDER BY e.id",
                        id),
                "attachments",
                db.rows(
                        "SELECT id,file_name,mime_type,size_bytes,uploaded_at FROM"
                                + " student_request_attachments WHERE request_id=? ORDER BY id",
                        id));
    }
}
