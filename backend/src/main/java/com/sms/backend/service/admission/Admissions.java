package com.sms.backend.service.admission;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.resource.Resources;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.util.*;

@Service
public class Admissions {
    private final Db db;
    private final Actor actor;
    private final Resources resources;
    private final String schoolEmailDomain;

    public Admissions(
            Db db,
            Actor actor,
            Resources resources,
            @Value("${sms.school-email-domain}") String schoolEmailDomain) {
        this.db = db;
        this.actor = actor;
        this.resources = resources;
        if (!schoolEmailDomain.matches("[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"))
            throw new IllegalArgumentException("Invalid SMS_SCHOOL_EMAIL_DOMAIN");
        this.schoolEmailDomain = schoolEmailDomain;
    }

    public Map<String, Object> detail(long id) {
        var u = actor.current();
        var row = resources.accessible("admissions", id);
        actor.audit(u, "VIEW_DOSSIER", "admission_applications", id);
        return map(
                "application",
                row,
                "requirements",
                db.rows(
                        "SELECT document_type,label,is_required FROM"
                                + " admission_document_requirements WHERE period_id=?",
                        row.get("period_id")),
                "documents",
                db.rows(
                        "SELECT"
                            + " id,document_type,revision_no,file_name,mime_type,size_bytes,status,rejection_reason,uploaded_at"
                            + " FROM admission_documents WHERE application_id=? ORDER BY"
                            + " uploaded_at DESC,id DESC",
                        id),
                "events",
                db.rows(
                        "SELECT e.*,u.full_name actor_name FROM admission_review_events e JOIN"
                                + " users u ON u.id=e.actor_user_id WHERE application_id=? ORDER BY"
                                + " e.id",
                        id),
                "identity",
                db.rows(
                        "SELECT"
                            + " identity_type,identity_last4,issued_on,issued_by,expires_on,verified_at"
                            + " FROM admission_identity_records WHERE application_id=?",
                        id),
                "school",
                db.rows("SELECT * FROM admission_high_school_records WHERE application_id=?", id),
                "scores",
                db.rows(
                        "SELECT sc.* FROM admission_high_school_scores sc JOIN"
                            + " admission_high_school_records r ON r.id=sc.school_record_id WHERE"
                            + " r.application_id=?",
                        id));
    }

    @Transactional
    public void transition(long id, String action, Map<String, Object> body) {
        var u = actor.current();
        resources.accessible("admissions", id);
        var row = db.one("SELECT * FROM admission_applications WHERE id=? FOR UPDATE", id);
        String from = row.get("status").toString();
        String to;
        String event = action;
        switch (action) {
            case "SUBMIT" -> {
                u.require("APPLICANT");
                if (Db.id(row.get("applicant_user_id")) != u.id())
                    throw error(403, "Không phải hồ sơ của bạn.");
                expect(from, "DRAFT", "CHANGES_REQUESTED");
                if (db.number(
                                "SELECT COUNT(*) FROM admission_periods WHERE id=? AND"
                                        + " status='OPEN' AND opens_at<=CURRENT_TIMESTAMP AND"
                                        + " closes_at>=CURRENT_TIMESTAMP",
                                row.get("period_id"))
                        != 1) throw error(409, "Đợt nhập học đã đóng.");
                checkDocuments(id, false);
                to = "SUBMITTED";
                db.run(
                        "UPDATE admission_applications SET submitted_at=CURRENT_TIMESTAMP WHERE"
                                + " id=?",
                        id);
            }
            case "START_REVIEW" -> {
                u.require("CTSV");
                expect(from, "SUBMITTED");
                to = "IN_REVIEW";
                db.run(
                        "UPDATE admission_applications SET assigned_ctsv_user_id=? WHERE id=?",
                        u.id(),
                        id);
            }
            case "REQUEST_CHANGES" -> {
                u.require("CTSV");
                expect(from, "IN_REVIEW");
                text(body, "note", 700);
                to = "CHANGES_REQUESTED";
            }
            case "APPROVE" -> {
                u.require("CTSV");
                expect(from, "IN_REVIEW");
                checkDocuments(id, true);
                to = "CTSV_APPROVED";
            }
            case "REJECT" -> {
                u.require("CTSV");
                expect(from, "IN_REVIEW");
                text(body, "note", 700);
                to = "CTSV_REJECTED";
            }
            case "SUBMIT_TO_SCHOOL" -> {
                u.require("CTSV");
                expect(from, "CTSV_APPROVED");
                to = "SENT_TO_SCHOOL";
            }
            case "SCHOOL_APPROVE" -> {
                u.require("PRINCIPAL");
                expect(from, "SENT_TO_SCHOOL");
                to = "SCHOOL_APPROVED";
            }
            case "SCHOOL_REJECT" -> {
                u.require("PRINCIPAL");
                expect(from, "SENT_TO_SCHOOL");
                text(body, "note", 700);
                to = "SCHOOL_REJECTED";
            }
            case "SCHOOL_RETURN" -> {
                u.require("PRINCIPAL");
                expect(from, "SENT_TO_SCHOOL");
                text(body, "note", 700);
                to = "CHANGES_REQUESTED";
                event = "REQUEST_CHANGES";
            }
            case "PDT_VERIFY" -> {
                u.require("TRAINING_OFFICE");
                expect(from, "SCHOOL_APPROVED");
                to = "PDT_VERIFIED";
            }
            case "ENROLL" -> {
                u.require("TRAINING_OFFICE");
                expect(from, "PDT_VERIFIED");
                long classId = Db.id(body.get("class_id"));
                String code = text(body, "student_code", 40);
                if (db.number(
                                "SELECT COUNT(*) FROM academic_classes c JOIN admission_periods p"
                                    + " ON p.cohort_id=c.cohort_id WHERE c.id=? AND c.major_id=?"
                                    + " AND p.id=?",
                                classId,
                                row.get("major_id"),
                                row.get("period_id"))
                        != 1) throw error(400, "Lớp phải đúng ngành và khóa của đợt nhập học.");
                if (db.number(
                                "SELECT COUNT(*) FROM admission_review_events WHERE"
                                        + " application_id=? AND event_type='SCHOOL_APPROVE'",
                                id)
                        == 0) throw error(409, "Thiếu quyết định BGH.");
                long userId = Db.id(row.get("applicant_user_id"));
                long student =
                        db.insert(
                                "students",
                                map(
                                        "user_id",
                                        userId,
                                        "student_code",
                                        code,
                                        "class_id",
                                        classId,
                                        "phone",
                                        row.get("phone"),
                                        "address",
                                        row.get("address"),
                                        "date_of_birth",
                                        row.get("date_of_birth"),
                                        "status",
                                        "STUDYING",
                                        "enrolled_on",
                                        LocalDate.now()));
                db.run(
                        "INSERT INTO user_roles(user_id,role_id) SELECT ?,id FROM roles WHERE"
                                + " code='STUDENT'",
                        userId);
                for (String field :
                        List.of(
                                "gender",
                                "place_of_birth",
                                "hometown",
                                "permanent_address",
                                "current_address",
                                "nationality",
                                "guardian_full_name",
                                "guardian_phone"))
                    if (row.get(field) != null)
                        db.run(
                                "UPDATE students SET " + field + "=? WHERE id=?",
                                row.get(field),
                                student);
                String email = code.toLowerCase(Locale.ROOT) + "@" + schoolEmailDomain;
                db.insert(
                        "student_school_mailboxes",
                        map(
                                "student_id",
                                student,
                                "school_email",
                                email,
                                "provisioning_status",
                                "RESERVED",
                                "provisioned_by",
                                u.id()));
                db.run("UPDATE admission_applications SET student_id=? WHERE id=?", student, id);
                to = "ENROLLED";
            }
            default -> throw error(400, "Thao tác hồ sơ không hợp lệ.");
        }
        db.run("UPDATE admission_applications SET status=? WHERE id=?", to, id);
        db.insert(
                "admission_review_events",
                map(
                        "application_id",
                        id,
                        "actor_user_id",
                        u.id(),
                        "event_type",
                        event,
                        "from_status",
                        from,
                        "to_status",
                        to,
                        "note",
                        Objects.toString(body.get("note"), "")));
        String email = Objects.toString(row.get("personal_email"), "");
        if (email.isBlank())
            email =
                    Objects.toString(
                            db.one(
                                            "SELECT email FROM users WHERE id=?",
                                            row.get("applicant_user_id"))
                                    .get("email"),
                            "");
        db.insert(
                "outbound_emails",
                map(
                        "event_key",
                        "ADMISSION-" + UUID.randomUUID(),
                        "admission_application_id",
                        id,
                        "template_code",
                        "ADMISSION_STATUS",
                        "recipient_email",
                        email,
                        "subject",
                        "Hồ sơ " + row.get("application_code") + ": " + to,
                        "delivery_status",
                        "QUEUED"));
        actor.audit(u, action, "admission_applications", id);
    }

    private void checkDocuments(long id, boolean verified) {
        var row = db.one("SELECT period_id FROM admission_applications WHERE id=?", id);
        for (var requirement :
                db.rows(
                        "SELECT * FROM admission_document_requirements WHERE period_id=? AND"
                                + " is_required=TRUE",
                        row.get("period_id"))) {
            var files =
                    db.rows(
                            "SELECT status FROM admission_documents WHERE application_id=? AND"
                                    + " document_type=? ORDER BY revision_no DESC LIMIT 1",
                            id,
                            requirement.get("document_type"));
            if (files.isEmpty() || (verified && !"VERIFIED".equals(files.getFirst().get("status"))))
                throw error(409, "Thiếu giấy tờ hoặc chưa xác minh: " + requirement.get("label"));
        }
    }

    @Transactional
    public void verifyDocument(long id, boolean verified, String reason) {
        var u = actor.current();
        u.require("CTSV");
        var doc = db.one("SELECT * FROM admission_documents WHERE id=? FOR UPDATE", id);
        var app =
                db.one(
                        "SELECT * FROM admission_applications WHERE id=? FOR UPDATE",
                        doc.get("application_id"));
        expect(app.get("status").toString(), "IN_REVIEW");
        if (db.number(
                        "SELECT COUNT(*) FROM admission_documents WHERE application_id=? AND"
                                + " document_type=? AND revision_no>?",
                        doc.get("application_id"),
                        doc.get("document_type"),
                        doc.get("revision_no"))
                > 0) throw error(409, "Chỉ xác minh phiên bản mới nhất.");
        if (!verified && (reason == null || reason.isBlank()))
            throw error(400, "Nhập lý do giấy tờ chưa đạt.");
        db.run(
                "UPDATE admission_documents SET"
                    + " status=?,checked_by=?,checked_at=CURRENT_TIMESTAMP,rejection_reason=? WHERE"
                    + " id=?",
                verified ? "VERIFIED" : "REJECTED",
                u.id(),
                verified ? null : reason,
                id);
        actor.audit(u, "VERIFY_DOCUMENT", "admission_documents", id);
    }

    public static void expect(String status, String... allowed) {
        if (Arrays.stream(allowed).noneMatch(status::equals))
            throw error(409, "Không thể thực hiện từ trạng thái " + status);
    }
}
